---
title: HttpServlet源码详解
url: HttpServlet_source_code
tags:
  - Servlet
categories:
  - Java Web
date: 2017-05-16 18:05:22
---
# 前言
Servlet是Servlet+Applet的缩写，表示一个服务器应用。
Servlet是一个接口，是javaweb开发的一套规范。
<!-- more -->

# 继承树
<img src="http://yuml.me/diagram/nofunky/class/[<<ServletConfig>>;interface]^-[GenericServlet], [<<Servlet>>;interface]^-[GenericServlet], [GenericServlet]^-[HttpServlet]"/>

# GenericServlet详解
GenericServlet是与具体协议无关的。
可以看到`GenericServlet`是一个抽象类，实现了`Servlet`和`ServletConfig`接口。
```java
public abstract class GenericServlet 
    implements Servlet, ServletConfig, java.io.Serializable{
    private transient ServletConfig config;
    /** 省略部分代码 */
}
```

## Servlet接口在GenericServlet中的实现
先看`Servlet`接口，它实现了以下方法。
```java
public interface Servlet {
    public void init(ServletConfig config);     // Web容器调用时，初始化方法，只调用一次
    public void destroy();  // 关闭Web容器时销毁，只调用一次
    
    public ServletConfig getServletConfig();    // 暴露获取ServletConfig对象的方法
    // 容器注入request和response，处理业务
    public void service(ServletRequest req, ServletResponse res);  
    public String getServletInfo(); // 获取Servlet的信息，如作者，版权等。
}
```

根据这些方法，在`GenericeServlet`中找到其实现。
主要是对`init`进行了实现。
```java
public abstract class GenericServlet 
    implements Servlet, ServletConfig, java.io.Serializable{
    /** 省略部分代码 */
    private transient ServletConfig config;
    // 在序列化时，不对transient修饰的field进行序列化。
    
    public void init(ServletConfig config) throws ServletException {
        this.config = config;   // 获取Web容器注入的ServletConfig对象
        this.init(); 
    }

    public void init() throws ServletException {
        // 使用模板方法模式，自定义一个无参的init方法，并暴露给子类实现。
    }
    
    public ServletConfig getServletConfig() {
        return config; // 暴露获取ServletConfig对象的方法
    }
    
    public void destroy() {}
    public String getServletInfo() {    return "";  }
    public abstract void service(ServletRequest req, ServletResponse res);
}
```

## ServletConfig接口在GenericServlet中的实现
先看`ServletConfig`接口，它实现了以下方法。
```java
public interface ServletConfig {
    public String getServletName(); // 获取Servlet的名字，即web.xml中<servlet-name>的值
    public ServletContext getServletContext();  // 暴露获取ServletContext对象的方法
    public String getInitParameter(String name);    // 根据name获取初始化参数，即web.xml中<context-param>的键值对
    public Enumeration<String> getInitParameterNames(); // 获取所有的<context-param>的键值对
}
```

根据这些方法，在`GenericeServlet`中找到其实现。
全部都是通过`ServletConfig`对象进行实现的，而`ServletConfig`是由Web容器注入的,由[Servlet](#Servlet接口在GenericServlet中的实现)实现。
```java
public abstract class GenericServlet 
    implements Servlet, ServletConfig, java.io.Serializable{
    /** 省略部分代码 */
    public String getServletName() {
        return getServletConfig().getServletName();
    }
    public ServletContext getServletContext() {
        return getServletConfig().getServletContext();
    }
    public String getInitParameter(String name) {
        return getServletConfig().getInitParameter(name);
    }
    public Enumeration<String> getInitParameterNames() {
        return getServletConfig().getInitParameterNames();
    }  
}
```

# HttpServlet详解
很明显，GenericServlet只留下了`service`这个方法给HttpServlet进行重写。
并根据不同的请求类型，调用不同的`doXxx`方法。
`doXxx`必须重写，否则在调用时会出现异常。
```java
public abstract class HttpServlet extends GenericServlet{
    /** 省略部分代码 */
    @Override
    public void service(ServletRequest req, ServletResponse res){
        HttpServletRequest  request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        service(request, response);
    }
    
    /** 核心方法 */
    protected void service(HttpServletRequest req, HttpServletResponse resp) {
        String method = req.getMethod(); // 获取请求类型
        
        // 根据请求类型，调用不同的doXxx方法
        if (method.equals(METHOD_GET)) {
            doGet(req, resp);
        } else if (method.equals(METHOD_HEAD)) {
            doHead(req, resp);
        } else if (method.equals(METHOD_POST)) {
            doPost(req, resp);
        } else if (method.equals(METHOD_PUT)) {
            doPut(req, resp);
        } else if (method.equals(METHOD_DELETE)) {
            doDelete(req, resp);
        } else if (method.equals(METHOD_OPTIONS)) {
            doOptions(req,resp);
        } else if (method.equals(METHOD_TRACE)) {
            doTrace(req,resp);
        } else {
            //
        }
    }
}
```

## Http的各种请求类型

| 请求类型 | 作用 |
|:---------|:-----|
| Get      |      |
| Post     |      |
| Put      |      |
| Delete   |      |
| Head     | 调用doGet方法，返回空body的Response    |
| Options  | 调试工作，返回所有支持的处理类型的集合 |
| Trace    | 调试工作，远程诊断服务器，将接收到的header原封不动地返回 |
