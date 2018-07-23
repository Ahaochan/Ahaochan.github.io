---
title: 记一次SpringMVC访问静态资源405错误修复
url: why_Spring_MVC_ask_the_static_resource_return_405
tags:
  - Spring MVC
categories:
  - Java Web
date: 2017-07-04 21:38:35
---

# 前言
访问静态资源出现405错误
```
警告 [http-nio-8080-exec-8] org.springframework.web.servlet.PageNotFound.handleHttpRequestMethodNotSupported Request method 'GET' not supported
```
```
HTTP Status 405 - Request method 'GET' not supported
type Status report
message Request method 'GET' not supported
description The specified HTTP method is not allowed for the requested resource.
```
<!-- more -->

# stackoverflow解释

开启`DefaultServletHandlerConfigurer`
或者配置`ResourceHandler`
二选一
```java
public class WebConfig extends WebMvcConfigurerAdapter {

    @Override
    public void configureDefaultServletHandling(DefaultServletHandlerConfigurer configurer) {
        configurer.enable();
    }
    
//    @Override
//    public void addResourceHandlers(ResourceHandlerRegistry registry) {
//        registry.addResourceHandler("/static/**").addResourceLocations("/static/**");
//    }
}
```

使用
```
@RequestMapping(value = "/path", method = RequestMethod.GET)
```
替换
```
@RequestMapping(value = "/path", method = RequestMethod.POST)
```


问题是
第一步我明显配置好的了。
第二步我还不至于犯这么低级的错误(事实上就是这么低级的错误)

# 修bug之路
1. 以为是IDEA的bug, 像Android Studio一样, 需要隔三差五的`ReBuild`一下。(405)
1. 删除项目目录下的`out`和`target`文件夹, 重新编译运行。(405)
1. 新建项目, 将`Initializer`、`WebConfig`复制到新项目, 编译运行。(成功)
1. 将全部代码复制一遍到新目录。(405)
1. 将所有`@Compontent`注释, 保留一个简单的HelloWorld的`@Controller`。(成功)
1. 一个个`@Compontent`恢复，终于找到bug所在。

# 问题所在
我在之前添加了个`PostMapping`, 加上了`TODO`后, 就忘记这件事了。
之后就开始出现访问静态资源`405`错误。页面能正常打开，就是样式丢失。
```java
@Controller
public class UserController{
    // 省略其他代码
    @PostMapping()
    public String addUser(){
        //TODO 增加用户
        return "";
    }
}
```

原因就在这, `name`的默认值是`""`，会拦截所有不经过其他`RequestMapping`的`url`。
静态资源也因此被拦截, 需要通过`Post`方式获取。
```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@RequestMapping(method = RequestMethod.POST)
public @interface PostMapping {
	@AliasFor(annotation = RequestMapping.class)
	String name() default "";
    // 省略其他代码
}
```

# 解决方法
将这段代码注释掉, 或者将`PostMapping`的`name`设置下。
```java
@Controller
public class UserController{
    // 省略其他代码
//    @PostMapping("/admin/user")
//    public String addUser(){
//        //TODO 增加用户
//        return "";
//    }
}
```
