---
title: SpringMVC检测异常链接
url: detect_abnormal_url_in_SpringMVC
tags:
  - Spring MVC
categories:
  - Java Web
date: 2018-02-02 22:45:37
---

# 前言
大型网站通常会因为开发人员的代码功底参差不齐, 在一段时间后, 因为接口关闭等一系列原因, 造成页面出现`500`或`404`等常见错误。而这些链接是隐藏极深, 难以去人工一一排除的。

[Xenu Link Sleuth](https://en.wikipedia.org/wiki/Xenu%27s_Link_Sleuth)是一个错链扫描工具, 可以检测到网页中的链接是否正常。
当然, 这个工具是需要自己手动点击才能自动扫描的。最好就是用户访问到的瞬间, 我们就能知道链接是否正常。

<!-- more -->

# 拦截器
`Spring MVC`提供了**拦截器**和**拦截器链**。
推荐使用注解加载`Bean`。

```java
/**
 * Created by Ahaochan on 2017/9/21.
 * Spring拦截器的注解, 复制自{@link org.springframework.stereotype.Service}
 */
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Component
public @interface Interceptor {
    String value() default "";
}

/**
 * Created by Ahaochan on 2017/9/21.
 * Web状态码拦截器, 拦截到异常或状态码不为200, 则进行处理
 * 写入数据库、日志, 或者短信提醒
 */
@Interceptor
public class WebStatusInterceptor extends HandlerInterceptorAdapter {
    private static final Logger logger = LoggerFactory.getLogger(WebExceptionResolver.class);
    
    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        // 具体实现交由开发人员自行处理
        if(ex != null || response.getStatus() != HttpStatus.OK.value()){
            logger.error("异常链接:"+request.getRequestURI());
            logger.error("状态码:"+response.getStatus());
            logger.error("异常:", ex);
        }
    }
}
```
```xml
<!--spring-aop.xml 省略部分代码-->
<?xml version="1.0" encoding="UTF-8"?>
<beans>
    <!--扫描aop相关的bean -->
    <context:component-scan base-package="com.ahao" use-default-filters="false">
        <!-- 扫描拦截器 -->
        <context:include-filter type="annotation" expression="com.ahao.annotation.Interceptor"/>
    </context:component-scan>

    <aop:aspectj-autoproxy proxy-target-class="true"/>

    <!-- 拦截器链 -->
    <mvc:interceptors>
        <mvc:interceptor>
            <!-- 对所有uri进行拦截 -->
            <mvc:mapping path="/**"/>
            <!-- 特定请求的拦截器只能有一个 -->
            <ref bean="webStatusInterceptor "/>
        </mvc:interceptor>
    </mvc:interceptors>
</beans>
```

# 总结
[Xenu Link Sleuth](https://en.wikipedia.org/wiki/Xenu%27s_Link_Sleuth)是比较强大的工具, 但是及时性不足, 扫描时间过长。
`Spring MVC`提供了拦截器可以补充上面的缺陷, 但是缺点就是无法扫描外部链接。