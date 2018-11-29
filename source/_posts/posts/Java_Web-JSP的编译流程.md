---
title: JSP的编译流程
url: JSP_compile_and_load
tags:
  - Servlet
  - Tomcat
categories:
  - Java Web
date: 2018-11-29 18:05:15
---
# 情景还原
用`Spring Boot`简单搭建环境, 建一个`Controller`以及两个`JSP`页面。
发现`/test1`页面`404`不能访问, 而`/test2`可以访问。
```java
@Controller
public class TestController {
    @GetMapping("test1")
    public String test1() {
        return "/WEB-INF/views/IE10+.jsp";
    }
    @GetMapping("test2")
    public String test2() {
        return "/WEB-INF/views/IE10.jsp";
    }
}
```

# 问题所在
`JSP`是本质一个`Java`文件, 所以命名也需要遵循`Java`命名规则, `+`加号对`Java`命名规则来说是一个非法字符。
所以`IE10+.jsp`对应的`java`文件是不存在的, 自然也就`404`了。
我在`$CATALINA_BASE/work/Catalina/localhost/web/org/apache/jsp/WEB_002dINF/views/`下只看到了`IE10_jsp.java`和`IE10_jsp.class`这两个文件。

# JSP编译流程
1. 客户端请求`JSP`文件.
2. `Servlet`容器将请求交给`org.apache.jasper.servlet.JspServlet`处理, 具体配置在`Tomcat`的`conf/web.xml`中.
3. `JspServlet`生成`java`文件, 编译为`class`文件, 加载到`ClassLoader`, 加入缓存中.
4. 调用生成的`Servlet`的`service`方法处理请求.

# 基于Tomcat 8.5.35的源码分析
![继承树](http://yuml.me/diagram/nofunky/class/[<<PeriodicEventListener>>;interface]^-[JspServlet], [HttpServlet]^-[JspServlet])
`JspServlet`继承了`HttpServlet`, 并实现了`PeriodicEventListener`接口, 这个接口暂时不管它, `HttpServlet`在我[另一篇文章](https://ahaochan.github.io/posts/HttpServlet_source_code.html)中有做源码解析。

## 重写了继承树上GenericServlet的方法
`JspServlet`重写了`GenericServlet`的两个方法.
默认情况下, 只做了一件事, 对`JspRuntimeContext`的实例进行初始化和销毁.
1. `public void init(ServletConfig config);` 初始化方法, 默认只初始化`JspRuntimeContext`的实例
2. `public void destroy();` 销毁方法, 销毁`JspRuntimeContext`的实例
```java
// org.apache.jasper.servlet.JspServlet
public class JspServlet extends HttpServlet implements PeriodicEventListener {
    private transient ServletContext context;
    private ServletConfig config;
    private transient Options options;
    private transient JspRuntimeContext rctxt;
    private String jspFile;
    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        this.config = config;
        this.context = config.getServletContext();

        // 省略部分代码, 默认不执行的代码
        options = new EmbeddedServletOptions(config, context);
        rctxt = new JspRuntimeContext(context, options);
    }

    @Override
    public void destroy() {
        rctxt.destroy();
    }
```

## 重写了HttpServlet的service方法
`service`方法是实际处理请求的逻辑方法。这里不对`include`等特殊情况做分析.
首先会判断请求参数是否携带`jsp_precompile`参数, 如果有的话就标记成预编译, 交给后面的核心代码使用.
然后再从缓存中获取`JspServletWrapper`实例, 没有则创建.
最后交给`JspServletWrapper`的`service`去执行核心代码.
```java
// org.apache.jasper.servlet.JspServlet
public class JspServlet extends HttpServlet implements PeriodicEventListener {
    private transient ServletContext context;
    private ServletConfig config;
    private transient Options options;
    private transient JspRuntimeContext rctxt;
    private String jspFile;
    @Override
    public void service (HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // jspFile may be configured as an init-param for this servlet instance
        String jspUri = request.getServletPath();
        String pathInfo = request.getPathInfo();
        if (pathInfo != null) {
            jspUri += pathInfo;
        }
        // 根据 jsp_precompile 参数是否存在, 判断是否需要进行预编译
        boolean precompile = preCompile(request);
        // 处理请求
        serviceJspFile(request, response, jspUri, precompile);
    }
    
    private void serviceJspFile(HttpServletRequest request, HttpServletResponse response, String jspUri, boolean precompile)
        throws ServletException, IOException {

        // 1. 从 JspRuntimeContext 缓存中获取 JspServlet包装类, 双重锁避免高并发问题
        JspServletWrapper wrapper = rctxt.getWrapper(jspUri);
        if (wrapper == null) {
            synchronized(this) {
                wrapper = rctxt.getWrapper(jspUri);
                if (wrapper == null) {
                    // 判断请求的JSP是否存在, 避免创建无用的JspServletWwrapper
                    if (null == context.getResource(jspUri)) {
                        handleMissingResource(request, response, jspUri);
                        return;
                    }
                    wrapper = new JspServletWrapper(config, options, jspUri, rctxt);
                    // 加入 JspRuntimeContext 缓存
                    rctxt.addWrapper(jspUri,wrapper);
                }
            }
        }

        try {
            // 2. 核心处理代码
            wrapper.service(request, response, precompile);
        } catch (FileNotFoundException fnfe) {
            handleMissingResource(request, response, jspUri);
        }
    }
}
```

## 生成Java文件并编译
`options.getDevelopment()`这个变量是写在`web.xml`的`JspServlet`里, 通过`ServletConfig`的`getInitParameter("development")`方法获取. `web.xml`中没有进行配置, 所以默认为`true`.
```java
// org.apache.jasper.servlet.JspServletWrapper
public class JspServletWrapper {
    private final JspCompilationContext ctxt;
    private volatile boolean mustCompile = true;
    private final Options options;

    public void service(HttpServletRequest request, HttpServletResponse response, boolean precompile)
            throws ServletException, IOException, FileNotFoundException {
        // =========================================
        // (1) 编译, mustCompile默认为true, options.getDevelopment()默认为true
        // =========================================
        if (options.getDevelopment() || mustCompile) {
            synchronized (this) {
                if (options.getDevelopment() || mustCompile) {
                    // The following sets reload to true, if necessary
                    ctxt.compile();
                    mustCompile = false;
                }
            }
        }
        // ==================省略部分代码==================
    }
}
```
`JspServletWrapper`的`service`调用了`JspCompilationContext`的`compile`方法.
```java
// org.apache.jasper.JspCompilationContext
public class JspCompilationContext {
    public void compile() throws JasperException, FileNotFoundException {
        // 1. 获取编译器
        createCompiler();
        // 2. 判断是否需要重新将 JSP 转为 java 文件, 并编译为 class 文件
        if (jspCompiler.isOutDated()) {
            if (isRemoved()) {
                throw new FileNotFoundException(jspUri);
            }
            // 3. 先删除上次生成的 class 文件, 后删除 java 文件
            jspCompiler.removeGeneratedFiles();
            jspLoader = null; // 清空 ClassLoader, 为了进行 JSP 热部署
            // 4. 重新生成 java 文件, 后编译为 class 文件
            jspCompiler.compile();
            jsw.setReload(true); // 设置重新加载 Servlet 的标识
            jsw.setCompilationException(null);
        }
        // 省略部分捕获异常的代码
    }
}
```

第一步, `createCompiler();`先获取编译器
1. 判断`web.xml`里的`JspServlet`有没有定义编译器的类名`compilerClassName`, 有则创建
2. 判断`web.xml`里的`JspServlet`有没有定义`compiler`, 有则先创建`JDTCompiler`编译器, 否则先创建`AntCompiler`. 创建失败则尝试创建两者的另一个编译器.
3. 都创建失败, 则抛出异常

第二步, `jspCompiler.isOutDated()`比较`JSP`的最后修改时间和对应的`class`文件
最后修改时间, 过时则重新编译.  可以在`web.xml`里的`JspServlet`配置`modificationTestInterval`参数, 指定一定秒数内`return false`, 不进行重新编译.

第三步, 先删除上次生成的`class`文件, 后删除`java`文件。
第四步, 调用之前获取到的编译器的`compile`方法生成`java`文件, 并编译为`class`文件.
```
// org.apache.jasper.compiler.Compiler
public abstract class Compiler {
    public void compile() throws FileNotFoundException, JasperException, Exception {
        compile(true);
    }

    public void compile(boolean compileClass) throws FileNotFoundException, JasperException, Exception {
        compile(compileClass, false);
    }

    public void compile(boolean compileClass, boolean jspcMode) throws FileNotFoundException, JasperException, Exception {
        // 1. 生成 java 文件
        String[] smap = generateJava();
        File javaFile = new File(ctxt.getServletJavaFileName());
        Long jspLastModified = ctxt.getLastModified(ctxt.getJspFile());
        javaFile.setLastModified(jspLastModified.longValue());
        if (compileClass) {
            // 2. 编译为 class 文件, 交给子类实现, 如 AntCompiler、JDTCompiler
            generateClass(smap);
            // Fix for bugzilla 41606
            // Set JspServletWrapper.servletClassLastModifiedTime after successful compile
            File targetFile = new File(ctxt.getClassFileName());
            if (targetFile.exists()) {
                targetFile.setLastModified(jspLastModified.longValue());
                if (jsw != null) {
                    jsw.setServletClassLastModifiedTime(
                            jspLastModified.longValue());
                }
            }
        }
    }
}
```

## 获取 Servlet
同样是`JspServletWrapper`的`service`方法, 在编译出了`class`文件后, 就应该要将`class`加载到`ClassLoader`里了。
在之前提到的`JspCompilationContext`的`compile`方法里, 将`JSP`的`ClassLoader`变量`jspLoader`设置为了`null`. 因为一个`ClassLoader`不能加载两个相同的类, 所以要一个新的`ClassLoader`进行热部署`JSP`.

```java
// org.apache.jasper.servlet.JspServletWrapper
public class JspServletWrapper {
    private Servlet theServlet;

    public void service(HttpServletRequest request, HttpServletResponse response, boolean precompile)
            throws ServletException, IOException, FileNotFoundException {
        // =========================================
        // (2) (重新)加载 servlet class 文件
        // =========================================
        Servlet servlet = getServlet();
        // 如果请求参数 jsp_precompile 存在, 则不执行之后的代码
        if (precompile) {
            return;
        }
        // =========================================
    }

    public Servlet getServlet() throws ServletException {
        if (getReloadInternal() || theServlet == null) {
            synchronized (this) {
                // Synchronizing on jsw enables simultaneous loading
                // of different pages, but not the same page.
                if (getReloadInternal() || theServlet == null) {
                    // 1. 先销毁旧的 Servlet
                    destroy();
                    // 2. 加载 class 并反射创建 Servlet, 这里的 JspLoader 在之前设置为 null, 所以这里会 new 一个 JspLoader
                    InstanceManager instanceManager = InstanceManagerFactory.getInstanceManager(config);
                    // fqcn 是  Full Qualified Class Name 的缩写
                    Servlet servlet = (Servlet) instanceManager.newInstance(ctxt.getFQCN(), ctxt.getJspLoader());
                    // 3. 初始化 Servlet
                    servlet.init(config);

                    // 4. JSP 重载数量+1
                    if (theServlet != null) {
                        ctxt.getRuntimeContext().incrementJspReloadCount();
                    }

                    theServlet = servlet;
                    reload = false; // 编译时会重新设置为 true, 用于进入此 if
                    // Volatile 'reload' forces in order write of 'theServlet' and new servlet object
                }
            }
        }
        return theServlet;
    }
}
```

## 限制 JSP 加载数量(选读)
默认不执行这段代码, 属于程序优化部分, 比较简单, 就是对一个队列进行先进先出的操作。
```java
// org.apache.jasper.servlet.JspServletWrapper
public class JspServletWrapper {
    private final boolean unloadAllowed; // web.xml 的 JspServlet 的 maxLoadedJsps  参数配置, 大于0则为true
    private final boolean unloadByIdle;  // web.xml 的 JspServlet 的 jspIdleTimeout 参数配置, 大于0则为true
    private final boolean unloadByCount; // 值为 unloadAllowed || unloadByIdle

    public void service(HttpServletRequest request, HttpServletResponse response, boolean precompile)
            throws ServletException, IOException, FileNotFoundException {
        // =========================================
        // (3) 限制 JSP 数量, 先进先出的队列
        // =========================================
        if (unloadAllowed) {
            synchronized (this) {
                if (unloadByCount) {
                    if (unloadHandle == null) {
                        unloadHandle = ctxt.getRuntimeContext().push(this);
                    } else if (lastUsageTime < ctxt.getRuntimeContext().getLastJspQueueUpdate()) {
                        // 核心代码, 移除队列中的 JSP 缓存
                        ctxt.getRuntimeContext().makeYoungest(unloadHandle);
                        lastUsageTime = System.currentTimeMillis();
                    }
                } else {
                    if (lastUsageTime < ctxt.getRuntimeContext().getLastJspQueueUpdate()) {
                        lastUsageTime = System.currentTimeMillis();
                    }
                }
            }
        }
        // =========================================
    }
}
```

## JSP 生成的 Servlet 进行处理请求
终于到了我们熟悉的环节, 调用创建的`Servlet`的`service`方法, 处理请求.
```java
// org.apache.jasper.servlet.JspServletWrapper
public class JspServletWrapper {
    private final boolean unloadAllowed; // web.xml 的 JspServlet 的 maxLoadedJsps  参数配置, 大于0则为true
    private final boolean unloadByIdle;  // web.xml 的 JspServlet 的 jspIdleTimeout 参数配置, 大于0则为true
    private final boolean unloadByCount; // 值为 unloadAllowed || unloadByIdle

    public void service(HttpServletRequest request, HttpServletResponse response, boolean precompile)
            throws ServletException, IOException, FileNotFoundException {
        // =========================================
        // (4) 执行创建的 Servlet 的 service 方法
        // =========================================
        if (servlet instanceof SingleThreadModel) {
            // sync on the wrapper so that the freshness
            // of the page is determined right before servicing
            synchronized (this) {
                servlet.service(request, response);
            }
        } else {
            servlet.service(request, response);
        }
        // =========================================
    }
}
```

# 一个简单的Hello world
```html
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
    <body>
        Hello world
    </body>
</html>
```

-----------------------

```java
package org.apache.jsp.WEB_002dINF.views.upload;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;

public final class IE10_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent,
                 org.apache.jasper.runtime.JspSourceImports {

  private static final javax.servlet.jsp.JspFactory _jspxFactory =
          javax.servlet.jsp.JspFactory.getDefaultFactory();

  private static java.util.Map<java.lang.String,java.lang.Long> _jspx_dependants;

  private static final java.util.Set<java.lang.String> _jspx_imports_packages;

  private static final java.util.Set<java.lang.String> _jspx_imports_classes;

  static {
    _jspx_imports_packages = new java.util.HashSet<>();
    _jspx_imports_packages.add("javax.servlet");
    _jspx_imports_packages.add("javax.servlet.http");
    _jspx_imports_packages.add("javax.servlet.jsp");
    _jspx_imports_classes = null;
  }

  private volatile javax.el.ExpressionFactory _el_expressionfactory;
  private volatile org.apache.tomcat.InstanceManager _jsp_instancemanager;

  public java.util.Map<java.lang.String,java.lang.Long> getDependants() {
    return _jspx_dependants;
  }

  public java.util.Set<java.lang.String> getPackageImports() {
    return _jspx_imports_packages;
  }

  public java.util.Set<java.lang.String> getClassImports() {
    return _jspx_imports_classes;
  }

  public javax.el.ExpressionFactory _jsp_getExpressionFactory() {
    if (_el_expressionfactory == null) {
      synchronized (this) {
        if (_el_expressionfactory == null) {
          _el_expressionfactory = _jspxFactory.getJspApplicationContext(getServletConfig().getServletContext()).getExpressionFactory();
        }
      }
    }
    return _el_expressionfactory;
  }

  public org.apache.tomcat.InstanceManager _jsp_getInstanceManager() {
    if (_jsp_instancemanager == null) {
      synchronized (this) {
        if (_jsp_instancemanager == null) {
          _jsp_instancemanager = org.apache.jasper.runtime.InstanceManagerFactory.getInstanceManager(getServletConfig());
        }
      }
    }
    return _jsp_instancemanager;
  }

  public void _jspInit() {
  }

  public void _jspDestroy() {
  }

  public void _jspService(final javax.servlet.http.HttpServletRequest request, final javax.servlet.http.HttpServletResponse response)
      throws java.io.IOException, javax.servlet.ServletException {

    final java.lang.String _jspx_method = request.getMethod();
    if (!"GET".equals(_jspx_method) && !"POST".equals(_jspx_method) && !"HEAD".equals(_jspx_method) && !javax.servlet.DispatcherType.ERROR.equals(request.getDispatcherType())) {
      response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED, "JSPs only permit GET POST or HEAD");
      return;
    }

    final javax.servlet.jsp.PageContext pageContext;
    javax.servlet.http.HttpSession session = null;
    final javax.servlet.ServletContext application;
    final javax.servlet.ServletConfig config;
    javax.servlet.jsp.JspWriter out = null;
    final java.lang.Object page = this;
    javax.servlet.jsp.JspWriter _jspx_out = null;
    javax.servlet.jsp.PageContext _jspx_page_context = null;


    try {
      response.setContentType("text/html;charset=UTF-8");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;

      // =========================== 输出代码 =====================================
      out.write("\r\n");
      out.write("<html>\r\n");
      out.write("<body>\r\n");
      out.write("Hello world\r\n");
      out.write("</body>\r\n");
      out.write("</html>\r\n");
      // =========================== 输出代码 =====================================
    } catch (java.lang.Throwable t) {
      if (!(t instanceof javax.servlet.jsp.SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          try {
            if (response.isCommitted()) {
              out.flush();
            } else {
              out.clearBuffer();
            }
          } catch (java.io.IOException e) {}
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
        else throw new ServletException(t);
      }
    } finally {
      _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}
```

# 参考资料
- [Jsp的编译过程和热部署原理](http://shenzhang.github.io/blog/2013/06/26/recompile-and-redeploy-in-jsp/)
- [JSP 热部署 源码解析](https://www.jianshu.com/p/01805c2a1036)
- [FQCN是什么鬼](https://blog.csdn.net/hwcptbtptp/article/details/78270243)
- [Why Spring Boot cannot parse view with + symbol?](https://stackoverflow.com/questions/53511441)