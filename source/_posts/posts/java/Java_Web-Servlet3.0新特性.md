---
title: Servlet3.0新特性
url: Servlet3.0
tags:
  - Servlet
categories:
  - Java Web
date: 2017-05-01 21:45:34
---
# 前言
`Servlet3.0`使用了注解来配置`web`应用，极大缩减了`web.xml`的配置。
<!-- more -->

# 新增注解

| 注解               | 作用                            |
|:-------------------|:--------------------------------|
| `@WebServlet`      | 修饰一个`Servlet`类             |
| `@WebFilter`       | 修饰一个`Filter`类              |
| `@WebListener`     | 修饰一个`Listener`类            |
| `@WebInitParam`    | 为`Servlet`、`Filter`类配置参数 |
| `@MultipartConfig` | 指定`Servlet`处理文件上传       |

# 对Web模块支持
`Servlet3.0`不再要求所有`Web`组件全部写在`web.xml`中。

需要在`META-INF`中添加`Web`模块部署描述符`web-fragment.xml`。
```xml
<?xml version="1.0" encoding="GBK" ?>
<web-fragment xmlns="http://java.sun.com/xml/ns/javaee"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
               http://java.sun.com/xml/ns/javaee/web-fragment_3_0.xsd
              version="3.0">
    <name>模块名</name>
    <ordering>
        <after><!-- 在哪些模块后加载 -->
            <name>模块1</name>
            <others/>
        <!-- others -->
        </after>
        <before><!-- 在哪些模块前加载 -->
            <name>模块2</name>
            <others/>
            <!-- others -->
        </before>
    </ordering>
    <!-- 配置Servlet、Filter、Listener -->
</web-fragment>
```
也可以在`web.xml`中指定加载顺序
```xml
<web-app>
    <absolute-ordering>
        <name>模块名</name>
        <others/>
    </absolute-ordering>
</web-app>
```

# 注解配置Web组件
> 不能在`web.xml`的`<web-app/>`指定`metadata-complete="true"`

如果`metadata-complete`设置为`true`，部署工具必须必须忽略存在于应用的类文件中的所有`servlet`注解和`web fragments`。
如果`metadata-complete`属性没有指定或设置为`false`，部署工具必须检查应用的类文件的注解，并扫描`web fragments`。

```java
@Servlet
public class MyServlet extends HttpServlet{
}
@WebFilter
public class MyFilter implements Filter{
}
@WebListener
public class MyListener implements ServletContextAttributeListener{
}
```

# 动态注册Web组件
`Servlet3.0`提供了`ServletContext`添加组件的方式
```java
  /** 添加Servlet */ 
  public ServletRegistration.Dynamic addServlet(String servletName, 
      String className); 
  public ServletRegistration.Dynamic addServlet(String servletName, 
      Servlet servlet); 
  public ServletRegistration.Dynamic addServlet(String servletName, 
      Class<? extends Servlet> servletClass); 

  /** 添加Filter */ 
  public FilterRegistration.Dynamic addFilter(String filterName, 
      String className); 
  public FilterRegistration.Dynamic addFilter(String filterName, Filter filter); 
  public FilterRegistration.Dynamic addFilter(String filterName, 
      Class<? extends Filter> filterClass); 

  /** 添加Listener */ 
  public void addListener(String className); 
  public <T extends EventListener> void addListener(T t); 
  public void addListener(Class<? extends EventListener> listenerClass);
```

## 通过ServletContextListener注册
```java
//这里不用@Servlet注解配置
public class MyServlet extends HttpServlet{
}

public class InitListener implements ServletContextListener{
    public void contextDestroyed(ServletContextEvent event) {  
        System.out.println("服务器关闭时会调用该方法");  
    }  
  
    @Override  
    public void contextInitialized(ServletContextEvent event) {  
        System.out.println("服务器启动时会调用该方法");  
        ServletContext context = contextEvent.getServletContext();  
          
        //注册一个没有使用@WebServlet注解的类为Servlet
        ServletRegistration register = context.addServlet("helloServlet", HelloServlet.class);  
          
        //为动态注册的Servlet设定访问URL(可设定多个)  
        register.addMapping("/hello", "/servlet/hello");  
          
        //为动态注册的Servlet设定初始参数
        //相当于以前的<init-param>
        register.setInitParameter("logPath", "/app/log");  
        register.setInitParameter("savePath", "/app/upload");  
    }  
}
```

## 通过ServletContainerInitializer注册
添加`META-INF/services/javax.servlet.ServletContainerInitializer`文件。
文件内容为
```
com.ahao.demo.MyServletContainerInitializer
```
指定自定义的`ServletContainerInitializer`。
```java
@HandlesTypes({ WebApplicationInitializer.class }) 
//@HandlesTypes({ HttpServlet.class })
//实现或者继承HandlesTypes注解中的类的都会被加载
public class MyServletContainerInitializer implements ServletContainerInitializer { 

    //以Set集合的方式传递注解中指定的类型的所有子类(包括子接口、实现类等)的class对象
    public void onStartup(Set<Class<?>> c, ServletContext servletContext)
                            throws ServletException {
        // 动态注册Servlet
        ServletContext context = sce.getServletContext();
        ServletRegistration.Dynamic servlet = context.addServlet("myServlet", MyServlet.class); 
        dynamicServlet.addMapping("/myServlet");
        dynamicServlet.setAsyncSupported(true);
        dynamicServlet.setLoadOnStartup(1);
        // 动态注册Filter
        FilterRegistration.Dynamic filter = context.addFilter("MyFilter", MyFilter.class);
        // 动态注册Listener
        context.addListener("com.ahao.demo.MyListener");
  } 
}
```


# 文件上传
`HttpServletRequest`提供处理文件上传的支持。
1. `Part getPart(String name)`
1. `Collection<Part> getParts()`

`Part`对应一个文件上传域，支持访问文件类型、大小、输入流等。
文件上传需要给`form`表单添加`enctype`属性，该属性有三个值：

| 属性值                              | 说明                                             |
|:------------------------------------|:-------------------------------------------------|
| `application/x-www-form-urlencoded` | 默认编码方式，对`form`的`value`属性进行`URL`编码 |
| `multipart/form-data`               | 二进制方式处理表单数据，上传文件用               |
| `text/plain`                        | 适用于直接通过表单发送邮件                       |

```html
<form action="upload" method="post" enctype="multipart/form-data">
    <input type="file" name="myfile" />
    <input type="submit"/>
</form>
```
在`Servlet`中处理上传数据，使用`@MultipartConfig`修饰，或者在`web.xml`中`<servlet>`标签中添加`<multipart-config/>`子标签
```java
@WebServlet(name="upload",urlPatterns={"/upload"})
@MultipartConfig
public class UploadServlet extends HttpServlet{
    public void doPost(HttpServletRequest request,HttpServletResponse response){
        Part part = request.getPart("myfile");
        out.println("文件类型:"+part.getContentType()+"<br/>");
        out.println("文件大小:"+part.getSize()+"<br/>");
        part.write(getServletContext().getRealPath("/uploadFiles")+"/"+"myfile");
    }
}
```

# 异步处理
> 支持`Servlet`、`Filter`。

当`Servlet`执行耗时操作时，必须等完成操作才能生成响应。
`Servlet3.0`允许`Servlet`创建一个线程去执行耗时操作。
## 先要给`Servlet`配置允许异步操作
- 在`xml`中配置：
```xml
<servlet>
    <servlet-name>MyServlet</servlet-name>
    <async-supported>true</async-supported>
</servlet>
```
- 在注解中配置：
```java
@WebServlet(urlPattern="/async",asyncSupported=true)
public class AsyncServlet extends HttpServlet{
}
```

## 通过ServletRequest创建AsyncContext对象
通过`AsyncContext`类实现，重复调用创建方法得到同一个`AsyncContext`对象。
```java
@WebServlet(urlPattern="/async",asyncSupported=true)
public class AsyncServlet extends HttpServlet{
    public void doGet(HttpServletRequest request,HttpServletResponse response){
        AsyncContext actx = request.startAsync();
        //AsyncContext actx = reuqets.startAsync(request,response);
        actx.setTimeout(3000);//设置超时时间
        actx.start(new Executor(actx));//启用线程
    }
}
```

## 异步监听
当需要了解异步操作执行细节时，可以使用`AsyncListener`监听器。
```java
//actx.addListener(new MyAsyncListener());
public class MyAsyncListener implements AsyncListener{
    public void onStartAsync(AsyncContext event){
        System.out.println("异步调用开始");
    }
    public void onComplete(AsyncContext event){
        System.out.println("异步调用完成");
    }
    public void onError(AsyncContext event){
        System.out.println("异步调用异常");
    }
    public void onTimeout(AsyncContext event){
        System.out.println("异步调用超时");
    }
}
```
