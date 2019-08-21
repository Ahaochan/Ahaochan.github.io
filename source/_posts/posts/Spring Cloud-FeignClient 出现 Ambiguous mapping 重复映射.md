---
title: FeignClient 出现 Ambiguous mapping 重复映射
url: FeignClient_and_Ambiguous_mapping
tags:
  - Feign
  - Spring Cloud
categories:
  - Spring Cloud
date: 2019-08-21 19:06:18
---

# 场景复现
依赖:
1. `Spring Boot 2.1.6.RELEASE`
1. `Eureka Client 2.1.0.RELEASE`
1. `OpenFeign 2.1.0.RELEASE`

我们创建两个项目, `ahao-server`服务提供方和`ahao-client`服务调用方.
`Eureka`可以使用我弄的一个[开箱即用`Eureka`](https://github.com/Ahaochan/project/tree/master/ahao-spring-cloud-eureka)

<!-- more -->

在`ahao-server`创建一个显示当前时间的`controller`, 同时注册到`eureka`上.
假设端口为`http://localhost:8080`
```java
@RestController
@RequestMapping("/ahao")
public class TimeController {
    @RequestMapping("/now")
    public String nowTime() {
        return "现在时间是:" + new SimpleDateFormat("yyyy年MM月dd日 hh时mm分ss秒").format(new Date());
    }
}
```

在`ahao-client`创建一个`controller`和一个`feign`客户端, 同时注册到`eureka`上.
假设端口为`http://localhost:8081`
```java
@RestController
@RequestMapping("/ahao")
public class TimeController {
    @Autowired
    private TimeApi timeApi;
    @RequestMapping("/now")
    public String now() {
        return timeApi.nowTime();
    }
}

@FeignClient(value = "AHAO-SERVER")
@RequestMapping("/ahao")
public interface TimeApi {
    @RequestMapping("/now")
    String nowTime();
}
```

运行`ahao-client`报错`java.lang.IllegalStateException: Ambiguous mapping.`
我们改一下`ahao-client`的`controller`.
```java
@RestController
@RequestMapping("/ahao")
public class TimeController {
    @Autowired
    private TimeApi timeApi;
    @RequestMapping("/my-now")
    public String now() {
        return timeApi.nowTime();
    }
}
```

再运行`ahao-client`就可以了.
我们访问`http://localhost:8081/ahao/my-now`可以得到`ahao-server`提供的时间服务, 但是访问`http://localhost:8081/ahao/now`就是`404`了.
那为什么会出现`java.lang.IllegalStateException: Ambiguous mapping.`呢?

# 问题所在
我们看下`RequestMappingHandlerMapping`映射注册器
```java
// org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping
public class RequestMappingHandlerMapping extends RequestMappingInfoHandlerMapping implements MatchableHandlerMapping, EmbeddedValueResolverAware {
    @Override
    protected boolean isHandler(Class<?> beanType) {
        return (AnnotatedElementUtils.hasAnnotation(beanType, Controller.class) ||
                AnnotatedElementUtils.hasAnnotation(beanType, RequestMapping.class));
    }
}
```
也就是, 只要`Bean`类上有`@Controller`注解**或者**`@RequestMapping`注解, 那就会解析`url`映射.
我们的`TimeApi`上刚好有一个`@RequestMapping`注解. 所以`TimeApi`和`TimeController`才会出现`url`映射冲突.

我们改造成`my-now`后, 就会有两个映射关系
1. `/ahao/my-now`: 正常的访问`ahao-server`服务
1. `/ahao/now`: 访问失败`404`

看到这里肯定有疑问了, 为什么`/ahao/now`有`url`映射关系, 访问却`404`?
我们再改造下`TimeApi`. 加个`@ResponseBody`注解, 看到这里应该就知道`Spring MVC`做了多大的一件蠢事.
```java
@FeignClient(value = "AHAO-SERVER")
@RequestMapping("/ahao")
@ResponseBody
public interface TimeApi {
    @RequestMapping("/now")
    String nowTime();
}
```
现在两个`url`都可以正常访问了
1. `/ahao/my-now`: 正常的访问`ahao-server`服务
1. `/ahao/now`: 正常的访问`ahao-server`服务

# 解决方案
这是`Spring MVC`的锅, `Feign`是不可能改的了, 而且`Spring MVC`也不可能改, 因为要兼容以前版本的使用者.

# 最简单的方法
不要把`@RequestMapping`和`@FeignClient`一起用, 直接把链接拼接到方法级的`@RequestMapping`上
```java
@FeignClient(value = "AHAO-SERVER")
public interface TimeApi {
    @RequestMapping("/ahao/now")
    String nowTime();
}
```

或者用`@FeignClient`的`path`属性
```java
@FeignClient(value = "AHAO-SERVER", path = "/ahao")
public interface TimeApi {
    @RequestMapping("/now")
    String nowTime();
}
```

# 装逼用方法
来源: https://github.com/spring-cloud/spring-cloud-netflix/issues/466#issuecomment-257043631
但是失去了自动装配的一些特性, 不推荐使用
```java
@Configuration
@ConditionalOnClass({Feign.class})
public class FeignMappingDefaultConfiguration {
    @Bean
    public WebMvcRegistrations feignWebRegistrations() {
        return new WebMvcRegistrationsAdapter() {
            @Override
            public RequestMappingHandlerMapping getRequestMappingHandlerMapping() {
                return new FeignFilterRequestMappingHandlerMapping();
            }
        };
    }

    private static class FeignFilterRequestMappingHandlerMapping extends RequestMappingHandlerMapping {
        @Override
        protected boolean isHandler(Class<?> beanType) {
            return super.isHandler(beanType) && (AnnotationUtils.findAnnotation(beanType, FeignClient.class) == null);
        }
    }
}
```

# 参考资料
- [@FeignClient with top level @RequestMapping annotation is also registered as Spring MVC handler](https://github.com/spring-cloud/spring-cloud-netflix/issues/466#issuecomment-257043631)
- [@RequestMapping without @Controller registered as handler SPR-17622](https://github.com/spring-projects/spring-framework/issues/22154)