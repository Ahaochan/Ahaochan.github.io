---
title: Feign之重复出现的FeignClientSpecification
url: Repeated_FeignClientSpecification_of_Feign
tags:
  - Feign
  - Spring Cloud
categories:
  - Spring Cloud
date: 2019-08-22 11:47:18
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
    @RequestMapping("/date")
    public String date() { return "现在日期是:" + new SimpleDateFormat("yyyy年MM月dd日").format(new Date()); }
    
    @RequestMapping("/time")
    public String time() { return "现在时间是:" + new SimpleDateFormat("hh时mm分ss秒").format(new Date()); }
}
```

在`ahao-client`创建一个`controller`和两个`feign`客户端, 同时注册到`eureka`上.
假设端口为`http://localhost:8081`
```java
@RestController
@RequestMapping("/ahao")
public class TimeController {
    @Autowired private DateApi dateApi;
    @Autowired private TimeApi timeApi;
    @RequestMapping("/date")
    public String date() { return dateApi.date(); }
    @RequestMapping("/time")
    public String time() { return timeApi.time(); }
}


@FeignClient(value = "AHAO-SERVER", path = "/ahao")
public interface DateApi {
    @RequestMapping("/date") String date();
}
@FeignClient(value = "AHAO-SERVER", path = "/ahao")
public interface TimeApi {
    @RequestMapping("/time") String time();
}
```

运行`ahao-client`报错
```text
***************************
APPLICATION FAILED TO START
***************************
Description:
The bean 'AHAO-SERVER.FeignClientSpecification', defined in null, could not be registered. A bean with that name has already been defined in null and overriding is disabled.

Action:
Consider renaming one of the beans or enabling overriding by setting spring.main.allow-bean-definition-overriding=true

Process finished with exit code 1
```
这个叫做`AHAO-SERVER.FeignClientSpecification`的`Bean`是从哪来的???

# 问题所在
`Spring`打印出了异常堆栈. 我们跟进去看一下.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    private void registerClientConfiguration(BeanDefinitionRegistry registry, Object name, Object configuration) {
        // 省略部分代码
        registry.registerBeanDefinition(name + "." + FeignClientSpecification.class.getSimpleName(), builder.getBeanDefinition());
    }
}
```
我们可以看到, 这里注册了一个`Bean`, 名字就是`AHAO-SERVER.FeignClientSpecification`.
这个`name`是从外部传进来的.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    public void registerFeignClients(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        // 省略部分代码
        Map<String, Object> attributes = annotationMetadata.getAnnotationAttributes(FeignClient.class.getCanonicalName());
        
        String name = getClientName(attributes);
        registerClientConfiguration(registry, name, attributes.get("configuration"));

        registerFeignClient(registry, annotationMetadata, attributes);
        // 省略部分代码
    }
}
```
可以看到, `name`应该是从注解中的属性取值来的, 再看看`getClientName()`方法.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    private String getClientName(Map<String, Object> client) {
        if (client == null) { return null; }
        
        String value = (String) client.get("contextId");
        if (!StringUtils.hasText(value)) { value = (String) client.get("value"); }
        if (!StringUtils.hasText(value)) { value = (String) client.get("name"); }
        if (!StringUtils.hasText(value)) { value = (String) client.get("serviceId"); }
        if (StringUtils.hasText(value)) { return value; }
        throw new IllegalStateException("Either 'name' or 'value' must be provided in @" + FeignClient.class.getSimpleName());
    }
}
```
一目了然了, 我们声明`@FeignClient`注解时, 只使用了`value`属性, 所以产生了冲突, 只要加上`contextId`就好了.

# 解决方案
加上`contextId`属性即可.
```java
@FeignClient(value = "AHAO-SERVER", path = "/ahao", contextId = "AHAO-SERVER-DATE")
public interface DateApi {
    @RequestMapping("/date") String date();
}
@FeignClient(value = "AHAO-SERVER", path = "/ahao", contextId = "AHAO-SERVER-TIME")
public interface TimeApi {
    @RequestMapping("/time") String time();
}
```

# Spring Boot/Cloud 2.0.x 版本
我们切换到`Spring Boot/Cloud 2.0.x`版本, 发现没有`contextId`属性, 但是启动的时候可以正常启动, 不会报错`Bean`冲突.
看下`Spring Boot/Cloud 2.0.x`版本的源码.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    private String getClientName(Map<String, Object> client) {
        if (client == null) { return null; }
        
        String value = (String) client.get("value");
        if (!StringUtils.hasText(value)) { value = (String) client.get("name"); }
        if (!StringUtils.hasText(value)) { value = (String) client.get("serviceId"); }
        if (StringUtils.hasText(value)) { return value; }
        throw new IllegalStateException("Either 'name' or 'value' must be provided in @" + FeignClient.class.getSimpleName());
    }
}
```
看下`getClientName()`方法, 里面也没有使用`contextId`. 也就是会创建两个同名`AHAO-SERVER.FeignClientSpecification`的`Bean`.
后来翻了下`issue`发现了答案.
> spring boot 2.0.x
> spring.main.allow-bean-definition-overriding default value is "true" 
> spring boot 2.1.x default value changed to "false"

原来是允许`Bean`重复定义所以才没有报错. 关键在`spring.main.allow-bean-definition-overriding`这个属性.
- `Spring Boot 2.0.x` 默认是 `true`.
- `Spring Boot 2.1.x` 默认是 `false`.

# 参考资料
- [Support Multiple Clients Using The Same Service](https://github.com/spring-cloud/spring-cloud-openfeign/pull/90/commits/82fa5181fdd2e23e7414521f468ecea88e17d157)
- [BeanDefinitionOverrideException in FeignClientsRegistrar in tests with customized Spring context](https://github.com/spring-cloud/spring-cloud-openfeign/issues/81#issuecomment-447188550)