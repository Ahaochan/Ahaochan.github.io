---
title: SpringMVC支持跨域访问
url: Cross_domain_access_in_Spring_MVC
tags:
  - Spring MVC
categories:
  - Java Web
date: 2017-09-07 23:19:11
---

# 前言
ajax的跨域访问, Spring MVC提供了使用AOP的解决方案。

<!-- more -->

# 什么是跨域访问
比如我现在在 `http://a.com` 中, 要访问 `http://b.com`, 这就是跨域访问。
而一般的 `AJAX` 是不允许跨域访问的。
网上关于跨域的说明有很多, 简单的说, 只要 `com` 之前的内容不一致, 就叫跨域访问。

# JSONP的解决方案(只支持GET)
## Spring MVC解决方案
**注意Spring MVC的版本要4.1以上**
先配置 `spring.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans >
    <!--扫描aop相关的bean -->
    <context:component-scan base-package="com.nine.rivers.galaxy" use-default-filters="false">
        <!-- 只扫描aop -->
        <context:include-filter type="annotation" expression="org.springframework.web.bind.annotation.ControllerAdvice"/>
    </context:component-scan>
</beans>
```

添加一个 `Advice` 和一个 `Controller`
```java
@ControllerAdvice(basePackages = "com.ahao.module.controller")
public class MyAdvice extends AbstractJsonpResponseBodyAdvice {
    public MyAdvice () {
        // 和下面 ajax 的 jsonp 属性的值要一致
        super("callback");
    }
}

// com.ahao.module.controller.TestController
// 注意在 MyAdvice 扫描的包下
@RestController
public class TestController {
    // 只支持GET, 使用 fastjson 方便输出
    @RequestMapping(value = "/test", method = RequestMethod.GET)
    public JSONObject test(@RequestParam("size") Integer size) {
        JSONObject json = new JSONObject(size);
        for (int i = 0; i < size; i++) {
            json.put("key"+i, "value"+i);
        }
        return json;
    }
}
```


可以看到 `Controller` 是一个很普通的 `Controller`, 那么主要的就是 `AbstractJsonpResponseBodyAdvice`。
从名字看就知道是和 `AOP` 有关。
值的注意的是, 如果把 `basePackages` 设置为 `com` 的话, 也就是很大范围的话,
那么该范围内所有的 `Controller` 都将支持 `JSONP`, 这样违背了[最小权限原则](https://zh.wikipedia.org/wiki/%E6%9C%80%E5%B0%8F%E6%9D%83%E9%99%90%E5%8E%9F%E5%88%99)。
所以 `basePackages` 范围要尽可能小。
配置好后, 启动`Tomcat`, 新建一个静态页面使用 `AJAX` 请求。

```html
<div></div>
<script src="https://cdn.bootcss.com/jquery/3.3.1/jquery.min.js"></script>
<script>
    $.ajax({
        type:"get",
        dataType:"jsonp",
        url:"http://localhost:8080/test",
        jsonp:"callback", // 和 MyAdvice 配置的值要一致
        data: {size: '5'},
        success : function(json) {
            $('div').html("成功:"+JSON.stringify(json));
        },
        error: function(xhr){
            $('div').html("失败:"+JSON.stringify(xhr));
        }
    });
</script>
```

结果
```html
<div>成功:{"key4":"value4","key3":"value3","key0":"value0","key2":"value2","key1":"value1"}</div>
```

### 为什么不支持POST
**没有支持`post`的`script`标签!!!**
`JSONP`的本质, 是通过`script`标签, 以函数传参的形式来调用。
从响应头`Content-Type: application/javascript;charset=utf-8`就可以看出。
如本例中的`JSONP`请求, 等价于
```js
<script src="http://localhost:8080/szlh/sdlyzwgk/test?callback=jQuery33108767440327735769_1521685929769&size=5&_=1521685929770"></script>
```
后台处理后, 将数据封装成一个`JSON对象`，返回一串函数
```js
jQuery33108767440327735769_1521685929769({"key4":"value4","key3":"value3","key0":"value0","key2":"value2","key1":"value1"});
```
可以看到`jQuery33108767440327735769_1521685929769`是函数名, 后台返回的数据封装成了`JSON对象`参数, 然后浏览器会调用这个函数, 走到`success`这个方法里面。

# CORS的解决方案
`CORS`是一个[W3C标准](https://developer.mozilla.org/zh/docs/Web/HTTP/Access_control_CORS)，全称是"跨域资源共享"(Cross-origin resource)

```js
// 允许http://localhost:8081对本机发起CORS访问
Access-Control-Allow-Origin: http://localhost:8081
// 3628800秒内，不需要再发送预检验请求，可以缓存该结果
Access-Control-Max-Age: 3628800
// 允许各种方式的请求
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
// 允许包含的请求头
Access-Control-Allow-Headers: content-type
```

## 原生解决方案
使用过滤器`Filter`解决, 注册这个过滤器即可。
```java
// com.ahao.core.filter.CORSFilter
public class CORSFilter implements Filter{
    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletResponse response = (HttpServletResponse) servletResponse;
        response.setHeader("Access-Control-Allow-Origin", "*");
        response.setHeader("Access-Control-Allow-Methods", "POST, GET");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
        filterChain.doFilter(servletRequest, servletResponse);
    }
}
```

## SpringMVC解决方案

**注意Spring MVC的版本要4.2以上**
使用`CrossOrigin`注解, 指定允许进行跨域的远程地址`http://localhost:8081`。
如果不指定, 则默认允许所有外来地址跨域访问。
```java
// com.ahao.module.controller.TestController
@RestController
public class TestController {
    // 支持GET、POST, 使用 fastjson 方便输出
    @CrossOrigin(origins = "http://localhost:8081")
    @RequestMapping(value = "/test", method = RequestMethod.POST)
    public JSONObject test(@RequestParam("size") Integer size) {
        JSONObject json = new JSONObject(size);
        for (int i = 0; i < size; i++) {
            json.put("key"+i, "value"+i);
        }
        return json;
    }
}
```
`CrossOrigin`注解可以加在类上, 也可以加在方法上。
如果需要全局都注解的话, 需要在`spring`配置文件上添加
```xml
<mvc:cors>
    <mvc:mapping path="/**" allowed-origins="http://localhost:8081"/>
</mvc:cors>
```

# 参考资料
- [CORS support in Spring Framework](https://spring.io/guides/gs/rest-service-cors/)