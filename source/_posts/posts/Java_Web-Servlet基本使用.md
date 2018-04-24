---
title: Servlet基本使用
url: Servlet_usage
tags:
  - Servlet
categories:
  - Java Web
date: 2017-02-25 14:13:15
---
# 介绍
`Servlet`是用`Java`编写的服务器端程序。
其主要功能在于交互式地浏览和修改数据，生成动态`Web`内容。
狭义的`Servlet`是指`Java`语言实现的一个接口，广义的`Servlet`是指任何实现了这个`Servlet`接口的类，
一般情况下，人们将`Servlet`理解为后者。
<!-- more -->

# 使用
- 实现`javax.servlet.Servlet`接口
- 继承`javax.servlet.GenericServlet`抽象类（实现了`Servlet`接口）
- 继承`javax.servlet.http.HttpServlet`类（继承自`toGenericServlet`类）（推荐）

先写一个类继承自`HttpServlet`
```java
public class Person extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        //处理get请求
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        //处理post请求
    }
}
```
并在`web.xml`中配置`Servlet`，对应在`ServletConfig`类中
```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">  
    <servlet>
        <servlet-name>myServlet</servlet-name>                                   <!--自己命名的Servlet名称-->
        <servlet-class>com.ahao.javaeeDemo.MyServlet</servlet-class> <!--Servlet所对应的类，用于反射创建-->
        <load-on-startup>0</load-on-startup> <!--服务器开始就创建Servlet，整型数代表加载优先级-->
        <init-param> <!--一个参数对应一个init-param标签-->
            <param-name>myParam</param-name> <!--初始化参数名-->
            <param-value>第一个参数</param-value> <!--初始化参数值-->
        </init-param>
    </servlet>
    <servlet-mapping>
        <servlet-name>myServlet</servlet-name> <!--自己命名的Servlet名称-->
        <url-pattern>/myServlet</url-pattern>      <!--访问Servlet的url路径，可以设置多个-->
    </servlet-mapping>
</web-app>
```

# web.xml介绍
所有项目的`web.xml`都有一个父的`web.xml`，位于`Tomcat/conf/web.xml`
其中有两个默认的`Servlet`


- `default`：解析`/`的`url`地址，即所有`servlet`都不匹配时，执行`default`，返回`404`等各种错误
- `jsp`：解析`jsp`后缀的`url`地址

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app>
    <!--==================default Servlet======================-->
    <servlet>
        <servlet-name>default</servlet-name>
        <servlet-class>org.apache.catalina.servlets.DefaultServlet</servlet-class>
        <init-param>
            <param-name>debug</param-name>
            <param-value>0</param-value>
        </init-param>
        <init-param>
            <param-name>listings</param-name>
            <param-value>false</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>default</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
    <!--==================default Servlet======================-->
    
    <!--==================JSP Servlet======================-->
    <servlet>
        <servlet-name>jsp</servlet-name>
        <servlet-class>org.apache.jasper.servlet.JspServlet</servlet-class>
        <init-param>
            <param-name>fork</param-name>
            <param-value>false</param-value>
        </init-param>
        <init-param>
            <param-name>xpoweredBy</param-name>
            <param-value>false</param-value>
        </init-param>
        <load-on-startup>3</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>jsp</servlet-name>
        <url-pattern>*.jsp</url-pattern>
        <url-pattern>*.jspx</url-pattern>
    </servlet-mapping>
    <!--==================JSP Servlet======================-->
</web-app>
```