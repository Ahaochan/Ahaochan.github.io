---
title: Spring Cloud Gateway 聚合 swagger 3.0.0
url: integrate_swagger_3_in_spring_cloud_gateway
tags:
  - Spring Cloud
categories:
  - Spring Cloud
date: 2021-02-23 11:55:00
---

# 前言
网上关于`zuul`聚合各个微服务的`swagger`已经有很多文章了, 但是没有一个完整的关于`spring cloud gateway`的聚合教程.
研究了一天, 写了个`demo`, 然后写篇文章记录一下.

<!-- more -->

# Swagger引入
`Springfox`现在已经更新到`3.0.0`了, 并且也支持了`starter`方式.
直接[引入](https://mvnrepository.com/artifact/io.springfox/springfox-boot-starter), 不需要加任何注解.
```xml
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-boot-starter</artifactId>
    <version>3.0.0</version>
</dependency>
```

# 聚合Swagger
和`zuul`的套路一样, 我们要实现`SwaggerResourcesProvider`接口, 然后根据各个服务的服务名拼接`uri`.
```java
@Primary
@Configuration(proxyBeanMethods = false)
public class SwaggerConfig implements SwaggerResourcesProvider {

    @Autowired
    private RouteDefinitionLocator routeDefinitionLocator; // 获取路由定义

    @Override
    public List<SwaggerResource> get() {
        List<SwaggerResource> swaggerResourceList = new ArrayList<>();
        routeDefinitionLocator.getRouteDefinitions()
            .map(this::swaggerResource)           // 转化为 SwaggerResource 对象
            .subscribe(swaggerResourceList::add); // Flux 转化为 List 对象
        return swaggerResourceList;
    }

    private SwaggerResource swaggerResource(RouteDefinition definition) {
        String location = definition.getPredicates().stream()
            .filter(predicate -> "Path".equalsIgnoreCase(predicate.getName()))
            .findFirst() // 获取第一个名为 Path 的 predicate, 里面含有路由规则
            .map(PredicateDefinition::getArgs) 
            // 如果是从注册中心的路由规则, key 就是 pattern, 否则就是 _genkey_0
            .map(map -> map.getOrDefault("pattern", map.get(NameUtils.GENERATED_NAME_PREFIX + "0")))
            // 拼接 url
            .map(pattern -> StringUtils.substringBefore(pattern, "*"))
            .map(pattern -> pattern + "v2/api-docs")
            .orElse(null);

        SwaggerResource swaggerResource = new SwaggerResource();
        swaggerResource.setName(definition.getId());
        swaggerResource.setLocation(location);
        return swaggerResource;
    }
}
```
整个执行流程很简单, 就是从**路由定义**里面获取**路由规则**, 拼接成`swagger`的地址, 丢到`SwaggerResource`里面.
但是中间有一些比较坑的地方.

## Flux 转化为 List 对象
不懂`Mono`和`Flux`的去搜索, 自己实现一个`webflux`的`hello world`程序.
`Mono`和`Flux`都是支持泛型的类. 可以简单地认为, `Mono`是包装了一个对象的对象, `Flux`是包装了一堆对象的集合.
要进行转换有两种方法

```java
List<SwaggerResource> swaggerResourceList1 = new ArrayList<>();
routeDefinitionLocator.getRouteDefinitions()
        .map(this::swaggerResource)
        .subscribe(swaggerResourceList1::add);
    
List<SwaggerResource> swaggerResourceList2 = routeDefinitionLocator.getRouteDefinitions()
        .map(this::swaggerResource)
        .collectList()
        .block(Duration.ofSeconds(10));
```

但是我们只能用第一种, 第二种方法会抛出`IllegalStateException`异常.
```java
// reactor.core.publisher.Mono
public abstract class Mono<T> implements CorePublisher<T> {
    public T block(Duration timeout) {
        BlockingMonoSubscriber<T> subscriber = new BlockingMonoSubscriber<>();
        subscribe((Subscriber<T>) subscriber);
        return subscriber.blockingGet(timeout.toMillis(), TimeUnit.MILLISECONDS);
    }
}

// reactor.core.publisher.BlockingSingleSubscriber
abstract class BlockingSingleSubscriber<T> extends CountDownLatch implements InnerConsumer<T>, Disposable {
    final T blockingGet(long timeout, TimeUnit unit) {
        if (Schedulers.isInNonBlockingThread()) {
            throw new IllegalStateException("block()/blockFirst()/blockLast() are blocking, which is not supported in thread " + Thread.currentThread().getName());
        }
    }
}

// reactor.core.scheduler.Schedulers
public abstract class Schedulers {
    public static boolean isInNonBlockingThread() {
        return Thread.currentThread() instanceof NonBlocking;
    }
}
```


## 获取路由规则
`gateway`会从注册中心获取服务的相关信息, 初始化路由规则.
`GatewayDiscoveryClientAutoConfiguration`会为`DiscoveryLocatorProperties`属性生成一个初始化的`PredicateDefinition`集合, 有点像原型模式.
```java
@Configuration(proxyBeanMethods = false)
public class GatewayDiscoveryClientAutoConfiguration {

    public static List<PredicateDefinition> initPredicates() {
        ArrayList<PredicateDefinition> definitions = new ArrayList<>();
        // TODO: add a predicate that matches the url at /serviceId?

        // add a predicate that matches the url at /serviceId/**
        PredicateDefinition predicate = new PredicateDefinition();
        predicate.setName("Path"); // 所以上面才要根据 Path 进行过滤
        predicate.addArg("pattern", "'/'+serviceId+'/**'"); // 所以上面才要根据 pattern 进行过滤
        definitions.add(predicate);
        return definitions;
    }

    @Bean
    public DiscoveryLocatorProperties discoveryLocatorProperties() {
        DiscoveryLocatorProperties properties = new DiscoveryLocatorProperties();
        properties.setPredicates(initPredicates());
        properties.setFilters(initFilters());
        return properties;
    }
}

// org.springframework.cloud.gateway.discovery.DiscoveryClientRouteDefinitionLocator
public class DiscoveryClientRouteDefinitionLocator implements RouteDefinitionLocator {
    @Override
    public Flux<RouteDefinition> getRouteDefinitions() {
        // 省略部分代码
        return serviceInstances.filter(instances -> !instances.isEmpty())
                .map(instances -> instances.get(0)).filter(includePredicate)
                .map(instance -> {
                    // 1. 获取服务名
                    String serviceId = instance.getServiceId();

                    RouteDefinition routeDefinition = new RouteDefinition();
                    routeDefinition.setId(this.routeIdPrefix + serviceId);
                    String uri = urlExpr.getValue(evalCtxt, instance, String.class);
                    routeDefinition.setUri(URI.create(uri));

                    final ServiceInstance instanceForEval = new DelegatingServiceInstance(instance, properties);

                    // 2. 获取 GatewayDiscoveryClientAutoConfiguration 初始化的默认 Predicate
                    for (PredicateDefinition original : this.properties.getPredicates()) {
                        // 3. 为服务初始化它自己的 Predicate 定义. 包括路由规则
                        PredicateDefinition predicate = new PredicateDefinition();
                        predicate.setName(original.getName());
                        for (Map.Entry<String, String> entry : original.getArgs().entrySet()) {
                            // 将 '/'+serviceId+'/**' 表达式替换成真正的路由规则
                            String value = parser.parseExpression(entry.getValue()).getValue(evalCtxt, instanceForEval, String.class);
                            predicate.addArg(entry.getKey(), value);
                        }
                        routeDefinition.getPredicates().add(predicate);
                    }

                    return routeDefinition;
                });
    }
}
```

## _genkey_0是从哪来的?
在上面的源码分析里已经看到了`pattern`这个`key`是从哪里生成的了.
但是为什么还有一个`_genkey_0`呢?

因为如果是手动在配置文件里面配置服务的话, `gateway`会自动生成`key`.
```java
// org.springframework.cloud.gateway.support.NameUtils
public final class NameUtils {
	public static final String GENERATED_NAME_PREFIX = "_genkey_";
	public static String generateName(int i) {
		return GENERATED_NAME_PREFIX + i;
	}
}

// org.springframework.cloud.gateway.handler.predicate.PredicateDefinition
public class PredicateDefinition {
    public PredicateDefinition(String text) { // 解析配置文件里的规则, 如 Path=/api/**
        int eqIdx = text.indexOf('=');
        if (eqIdx <= 0) {
            throw new ValidationException("Unable to parse PredicateDefinition text '" + text + "'" + ", must be of the form name=value");
        }
        setName(text.substring(0, eqIdx));

        String[] args = tokenizeToStringArray(text.substring(eqIdx + 1), ",");
        for (int i = 0; i < args.length; i++) {
            // 注意这里
            this.args.put(NameUtils.generateName(i), args[i]);
        }
    }
}
```
看到这, 你就会发现, 我写的代码其实有一个问题, 如果配置文件里有多个`predicate`.
那么一定要保证`Path`是第`0`个, 否则就获取不到路由规则. 目前也没想到什么好办法, 就这样将就用吧.

## 服务id特别长怎么办
有的同学会发现, 注册中心生成的服务`id`特别长, 不美观. 
~~我只想安安静静做一个美男子~~
我只想要显示服务名, 可以把前缀都去掉吗?
{% img SpringCloudGateway聚合swagger3_01.png %}

答案是不行.
在配置文件中加入配置项`spring.cloud.gateway.discovery.locator.route-id-prefix: "你想要的前缀"`即可.
但是不能填空字符串.
```java
// org.springframework.cloud.gateway.discovery.DiscoveryClientRouteDefinitionLocator
public class DiscoveryClientRouteDefinitionLocator implements RouteDefinitionLocator {
    private DiscoveryClientRouteDefinitionLocator(String discoveryClientName, DiscoveryLocatorProperties properties) {
        this.properties = properties;
        // 如果判断是空字符串, 就用默认的前缀了
        if (StringUtils.hasText(properties.getRouteIdPrefix())) {
            routeIdPrefix = properties.getRouteIdPrefix();
        } else {
            // 默认的 discoveryClientName 是 discoveryClient.getClass().getSimpleName()
            routeIdPrefix = discoveryClientName + "_";
        }
        evalCtxt = SimpleEvaluationContext.forReadOnlyDataBinding().withInstanceMethods().build();
    }
}
```

# 总结
实际的例子可以看我在`github`上的项目[`ahao-spring-cloud-gateway`](https://github.com/Ahaochan/project/tree/master/ahao-spring-cloud-gateway)
