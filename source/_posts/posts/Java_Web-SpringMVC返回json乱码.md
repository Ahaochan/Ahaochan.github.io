---
title: Spring MVC返回json乱码
url: how_to_correctly_parsing_json_in_Spring_MVC
tags:
  - Spring MVC
categories:
  - Java Web
date: 2017-08-05 16:06:48
---

# 前言
json又双叒叕返回乱码了! 
乱码一般都是编码问题，比如一个字符串`你好世界`, 用`GBK`编码后, 再用`UTF-8`解码, 就会出现乱码问题。
<!-- more -->

# 样例
```java
@Controller
public class TestController{
    @GetMapping("/test")
    @ResponseBody
    public String test() {
        return "你好世界";
    }
}
```

# 使用CharacterEncodingFilter过滤器(没用)
在 web.xml 中加入`CharacterEncodingFilter`过滤器, 对request和response进行编码转换。
```xml
    <filter>
        <filter-name>encoding</filter-name>
        <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
        <init-param>
            <param-name>encoding</param-name>
            <param-value>UTF-8</param-value>
        </init-param>
        <init-param>
            <param-name>forceRequestEncoding</param-name>
            <param-value>true</param-value>
        </init-param>
        <init-param>
            <param-name>forceResponseEncoding</param-name>
            <param-value>true</param-value>
        </init-param>
    </filter>
    <filter-mapping>
        <filter-name>encoding</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
```


源码很简单, 就是调用`setCharacterEncoding`方法设置编码
```java
public class CharacterEncodingFilter extends OncePerRequestFilter {
    @Override
	protected void doFilterInternal(
			HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {

		String encoding = getEncoding();
		if (encoding != null) {
			if (isForceRequestEncoding() || request.getCharacterEncoding() == null) {
				request.setCharacterEncoding(encoding);
			}
			if (isForceResponseEncoding()) {
				response.setCharacterEncoding(encoding);
			}
		}
		filterChain.doFilter(request, response);
	}
}
```

# CV大法重写StringHttpMessageConverter类
行吧, 自己解决不了, 上stackoverflow看看, 
在使用`<mvc:annotation-driven />`自动驱动的前提下, 
发现`@ResponseBody`返回值是`String`类型的话。
会调用`StringHttpMessageConverter`这个类进行转换。
```java
public class StringHttpMessageConverter extends AbstractHttpMessageConverter<String> {
	public static final Charset DEFAULT_CHARSET = Charset.forName("ISO-8859-1");
    private volatile List<Charset> availableCharsets;
	private boolean writeAcceptCharset = true;
}
```
默认是`ISO-8859-1`编码, 而且是`final`修饰的。这就意味这不能继承这个方法了。
那就用CV大法吧。
```java
public class StringHttpMessageConverter extends AbstractHttpMessageConverter<String> {
	public static final Charset DEFAULT_CHARSET = Charset.forName("UTF-8");
    private volatile List<Charset> availableCharsets;
	private boolean writeAcceptCharset = true;
}
```
并且在`<mvc:annotation-driven />`内注入这个Bean
```xml
<mvc:annotation-driven>  
    <mvc:message-converters register-defaults="true">  
        <bean class="com.chuanliu.platform.activity.basic.converter.MyStringHttpMessageConverter"/>  
    </mvc:message-converters>  
</mvc:annotation-driven>
```

# 使用produces属性完成
使用CV大法是很不好的习惯, 
【[解决spring-mvc @responseBody注解返回json 乱码问题](http://blog.csdn.net/lsx1984/article/details/8803296)】这篇文章提出可以使用produces属性完成
```java
@Controller
public class TestController{
    @GetMapping(value = "/test", produces="text/html;charset=UTF-8")
    @ResponseBody
    public String test() {
        return "你好世界";
    }
}
```
省了一大堆配置, 但还是要在每个`@ResponseBody`方法使用CV大法, 写入`produces="text/html;charset=UTF-8"`。

# 直接返回对象
【[（二）Java 中文乱码学习 与Spring @ResponseBody中的乱码 - Spring @ResponseBody中的乱码](http://josh-persistence.iteye.com/blog/2085015)】中提到
在使用`<mvc:annotation-driven />`自动驱动的前提下,
如果直接返回String类型, 则会调用`StringHttpMessageConverter`。
如果直接返回对象类型, 则会调用`MappingJackson2HttpMessageConverter`。

在`MappingJackson2HttpMessageConverter`的父类`AbstractJackson2HttpMessageConverter`中。
可以看到使用了`UTF-8`编码。
```java
public abstract class AbstractJackson2HttpMessageConverter extends AbstractGenericHttpMessageConverter<Object> {
	public static final Charset DEFAULT_CHARSET = Charset.forName("UTF-8");
}
```

# 参考资料
- [解决spring-mvc @responseBody注解返回json 乱码问题](http://blog.csdn.net/lsx1984/article/details/8803296)
- [（二）Java 中文乱码学习 与Spring @ResponseBody中的乱码 - Spring @ResponseBody中的乱码](http://josh-persistence.iteye.com/blog/2085015)中提到
- [springmvc 4.x 处理json 数据时中文乱码](https://my.oschina.net/alexgaoyh/blog/316314)
