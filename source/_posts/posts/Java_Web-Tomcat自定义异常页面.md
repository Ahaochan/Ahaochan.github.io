---
title: Tomcat自定义异常页面
url: Customize_Tomcat_Exceptions_Page
tags:
  - Tomcat
categories:
  - Java Web
date: 2018-06-11 16:45:00
---

# 前言
`Tomcat`在抛出异常的时候会自动跳转到带有异常堆栈的错误页面, 这很容易暴露自己的代码。

<!-- more -->

# Tomcat的原生解决方案
在项目的`/WEB-INF/web.xml`中指定自定义的默认页面即可, 并且该页面要与`WEB-INF`文件夹放在同一个目录下。
如果是`Servlet 2.5`, 还需要指定`Http`状态码。
```xml
<web-app>
    <!-- 支持Servlet 2.5+, 如果要对状态码特别指定页面, 需要按顺序排列error-page标签  -->
    <error-page>
        <error-code>500</error-code>
        <location>/500.jsp</location>
    </error-page>

    <!-- 支持Servlet 3  -->
    <error-page>
        <location>/Error.jsp</location>
    </error-page>
    <error-page>
        <exception-type>java.lang.Exception</exception-type>
        <location>/Error.jsp</location>
    </error-page>
</web-app>
```

# SpringMVC的解决方案
`Tomcat`的解决方案局限性太大, 也不能做逻辑处理记录到数据库之类的操作。

使用`ControllerAdvice`进行拦截, 并处理逻辑, 也可以重定向到其他页面。
```java
@ControllerAdvice
public class ErrorController {
    private static final Logger logger = LoggerFactory.getLogger(ErrorController.class);

    @ExceptionHandler(Exception.class)
    public void handleConflict(HttpServletRequest request, HttpServletResponse response, Exception e) throws Exception {
        // 如果使用@ResponseStatus注释异常，则重新抛出该异常并让框架处理该异常
        if (AnnotationUtils.findAnnotation(e.getClass(), ResponseStatus.class) != null) {
            throw e;
        }

        logger.error("发生了错误", e);
        // 逻辑操作, 记录到数据库等

        // 设置状态码, 并输出错误信息
        response.setStatus(500);
        response.getWriter().println(e.getMessage());
    }
}
```

# 参考资料
- [exception-handling-in-spring-mvc](https://spring.io/blog/2013/11/01/exception-handling-in-spring-mvc)