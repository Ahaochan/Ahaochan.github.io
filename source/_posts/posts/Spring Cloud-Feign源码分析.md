---
title: Feign 源码分析之初始化和执行
url: source_code_of_feign_and_init_and_execute
tags:
  - Feign
  - Spring Cloud
categories:
  - Spring Cloud
date: 2021-01-22 18:29:15
---

# 前言
`Feign`是一个面向对象的`http`客户端, 这里主要介绍`Feign`是如何初始化的, 并如何进行`http`请求的.
省略部分不重要的代码. 剥离了`hystrix`和`ribbon`的相关逻辑.
读完这篇源码解析, 之前写的{% post_link posts/Spring Cloud-Feign之重复出现的FeignClientSpecification %}也可以再复习下.

# FeignClientsRegistrar 创建 FactoryBean
要启用`Feign`, 首先要使用`@EnableFeignClients`注解.
```java
@Import(FeignClientsRegistrar.class) // 引入 FeignClientsRegistrar
public @interface EnableFeignClients {
}
```
`@EnableFeignClients`注解引入了`FeignClientsRegistrar`, 类实现了`ImportBeanDefinitionRegistrar`接口, 然后重写了`registerBeanDefinitions`方法.
说明加入到了`Spring`生命周期的管理中.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
// 实现了 ImportBeanDefinitionRegistrar 接口, 注册到 Spring 生命周期中
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    @Override
    public void registerBeanDefinitions(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        // 1. 将声明了 @EnableFeignClients 的类, 注册到名为 default.配置类名.FeignClientSpecification 的 FeignClientSpecification 实例中
        registerDefaultConfiguration(metadata, registry);
        // 2. 创建 FeignClientFactoryBean 注入到 Spring 容器中
        registerFeignClients(metadata, registry);
    }
}
```
`registerBeanDefinitions`方法主要做了两件事
1. 将声明了`@EnableFeignClients`的类, 注册到一个新的`FeignClientSpecification`实例`Bean`中. 作为默认`Feign`配置.
2. 将`@EnableFeignClients`的声明的包下的所有`@FeignClient`修饰的接口, 注册到新的`FeignClientFactoryBean`工厂中, 用于创建`JDK`动态代理.

## registerDefaultConfiguration 注册默认配置
第一行语句注册了一个名为`default.配置类名.FeignClientSpecification`的`FeignClientSpecification`实例为`Bean`.
作为之后创建的`Feign`动态代理的默认配置.
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    private void registerDefaultConfiguration(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        // 1. 获取 EnableFeignClients 中的属性
        Map<String, Object> defaultAttrs = metadata.getAnnotationAttributes(EnableFeignClients.class.getName(), true);
        if (defaultAttrs != null && defaultAttrs.containsKey("defaultConfiguration")) { // 永远为 true
            String name = "default." + metadata.getClassName();

            // 2. 注册一个 default.类名.FeignClientSpecification 的 Bean, 作为默认Feign配置
            BeanDefinitionBuilder builder = BeanDefinitionBuilder.genericBeanDefinition(FeignClientSpecification.class);
            builder.addConstructorArgValue(name);
            builder.addConstructorArgValue(configuration);
            registry.registerBeanDefinition(name + "." + FeignClientSpecification.class.getSimpleName(), builder.getBeanDefinition());
        }
    }
}
```

## registerFeignClients 注册 FactoryBean
```java
// org.springframework.cloud.openfeign.FeignClientsRegistrar
class FeignClientsRegistrar implements ImportBeanDefinitionRegistrar, ResourceLoaderAware, EnvironmentAware {
    public void registerFeignClients(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
        ClassPathScanningCandidateComponentProvider scanner = getScanner();

        // 1. 根据 @EnableFeignClients 的 clients 属性或者 value、basePackages、basePackageClasses 属性初始化 basePackages 变量
        Map<String, Object> attrs = metadata.getAnnotationAttributes(EnableFeignClients.class.getName());
        Class<?>[] clients = attrs.get("clients");
        Set<String> basePackages;
        if (clients == null || clients.length == 0) {
            scanner.addIncludeFilter(annotationTypeFilter); // scanner 的过滤器, 只扫描 @FeignClient 注解修饰的类
            // 1.1. 将 value、basePackages、basePackageClasses 属性的包名做并集, 如果都为空, 那就取配置类所在的包名
            basePackages = getBasePackages(metadata);
        } else {
            // 1.2. 将 clients 中的类的包名加入 basePackages, 并且 scanner 只扫描 clients 中的类以及 @FeignClient 注解修饰的类
        }

        // 2. 扫描 basePackage 包下的所有被 @FeignClient 注解修饰的接口
        for (String basePackage : basePackages) {
            Set<BeanDefinition> candidateComponents = scanner.findCandidateComponents(basePackage);
            for (BeanDefinition candidateComponent : candidateComponents) {
                if (candidateComponent instanceof AnnotatedBeanDefinition) {
                    // 2.1. 校验是否是接口
                    AnnotatedBeanDefinition beanDefinition = (AnnotatedBeanDefinition) candidateComponent;
                    AnnotationMetadata annotationMetadata = beanDefinition.getMetadata();
                    Assert.isTrue(annotationMetadata.isInterface(), "@FeignClient can only be specified on an interface");

                    // 2.2. 获取 FeignClient 的参数
                    Map<String, Object> attributes = annotationMetadata.getAnnotationAttributes(FeignClient.class.getCanonicalName());

                    // 2.3. 按 contextId、value、name、serviceId 的优先级顺序获取 name, 用来做下面 bean name 的前缀
                    String name = getClientName(attributes);
                    // 2.4. 将 @FeignClient 的 configuration 属性中的类, 注册为 FeignClientSpecification 类的实例 Bean
                    registerClientConfiguration(registry, name, attributes.get("configuration"));
                    // 2.5. 根据 @FeignClient 的属性, 注册 FeignClientFactoryBean 类的实例 Bean
                    //      Bean 名称规则为, 按 contextId、serviceId、name、value 的优先级顺序获取 name, 后面加上 FeignClient 字符串
                    registerFeignClient(registry, annotationMetadata, attributes);
                }
            }
        }
    }
}
```

# FeignClientFactoryBean 创建 JDK 动态代理
```java
// org.springframework.cloud.openfeign.FeignClientFactoryBean
class FeignClientFactoryBean implements FactoryBean<Object>, InitializingBean, ApplicationContextAware {

    @Override
    public Object getObject() throws Exception {
        return getTarget();
    }

    <T> T getTarget() {
        // 1. 初始化 FeignAutoConfiguration 中的 FeignContext, 将刚才声明的一堆 FeignClientSpecification 注入到 FeignContext 中
        FeignContext context = this.applicationContext.getBean(FeignContext.class);
        // 2. 根据 @FeignClient 里的 configuration 配置, 获取 builder
        Feign.Builder builder = feign(context);

        // 3. 如果 @FeignClient 没有配置 url, 就用 ribbon 做负载均衡
        if (!StringUtils.hasText(this.url)) {
            return (T) loadBalance(builder, context, new HardCodedTarget<>(this.type, this.name, this.url));
        }
        
        // 4. 生成 @FeignClient 接口的 JDK 代理实现, 这里返回的是 ReflectiveFeign$FeignInvocationHandler 类的 JDK 动态代理
        Client client = getOptional(context, Client.class);
        if (client != null) {
            builder.client(client);
        }
        // 5. 最终是调用 ReflectiveFeign 的 newInstance 方法, 创建 FeignInvocationHandler 的 JDK 动态代理
        Targeter targeter = get(context, Targeter.class);
        return (T) targeter.target(this, builder, context, new HardCodedTarget<>(this.type, this.name, url));
    }
}

// feign.ReflectiveFeign
public class ReflectiveFeign extends Feign {
    public <T> T newInstance(Target<T> target) {
        // 1. 根据方法初始化 MethodHandler 实例, 内部封装执行 http 请求的代码, 执行时根据 method 路由
        Map<Method, MethodHandler> methodToHandler = new LinkedHashMap<Method, MethodHandler>();
        // 2. 创建 FeignInvocationHandler 动态代理
        InvocationHandler handler = factory.create(target, methodToHandler);
        T proxy = (T) Proxy.newProxyInstance(target.type().getClassLoader(), new Class<?>[] {target.type()}, handler);
        return proxy;
    }
    static class FeignInvocationHandler implements InvocationHandler {
        public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
            // 根据 method 路由到 MethodHandler 中
        }
    }
}
```
初始化完毕后, 就可以`@Autowired`声明的`Feign`接口了.

# Feign 调用
```java
// feign.ReflectiveFeign
public class ReflectiveFeign extends Feign {
    static class FeignInvocationHandler implements InvocationHandler {
        private final Map<Method, MethodHandler> dispatch;
        public Object invoke(Object proxy, Method method, Object[] args) {
            return dispatch.get(method).invoke(args);
        }
    }
}
```

```java
// feign.SynchronousMethodHandler
final class SynchronousMethodHandler implements MethodHandler {
    @Override
    public Object invoke(Object[] argv) throws Throwable {
        // 1. 用原型模式, 构造 http 请求客户端
        RequestTemplate template = buildTemplateFromArgs.create(argv);
        // 2. 如果参数中没有 Options, 就返回默认的 Options 
        Options options = findOptions(argv);
        // 3. FeignClientsConfiguration 会初始化一个默认的 Retryer.NEVER_RETRY
        Retryer retryer = this.retryer.clone();
        // 4. while 是为了做重试
        while (true) {
            try {
                // 5. 业务请求
                return executeAndDecode(template, options);
            } catch (RetryableException e) {
                try {
                    retryer.continueOrPropagate(e);  // 重试策略
                } catch (RetryableException th) {
                    Throwable cause = th.getCause();
                    if (propagationPolicy == UNWRAP && cause != null) {
                        throw cause; // 中断重试
                    } else {
                        throw th; // 中断重试
                    }
                }
                if (logLevel != Logger.Level.NONE) {
                    logger.logRetry(metadata.configKey(), logLevel);
                }
                continue;
            }
        }
    }
}
```
调用的时候会根据`method`路由到各自的`MethodHandler`中.
然后`MethodHandler`会创建新的`http`客户端, 进行请求操作, 失败的时候做重试.

# executeAndDecode 执行http请求并解码响应体
```java
// feign.SynchronousMethodHandler
final class SynchronousMethodHandler implements MethodHandler {
    Object executeAndDecode(RequestTemplate template, Options options) throws Throwable {
        // 1. 经过拦截器处理, 根据 template 创建出 Request 对象
        Request request = targetRequest(template);
        
        // 2. 真正发起 http 请求
        Response response;
        try {
            // 默认是使用 HttpURLConnection 连接, 可以自己实现 Client 接口并注册为 Bean
            response = client.execute(request, options);
        } catch (IOException e) {
            throw errorExecuting(request, e);
        }

        // 3. 解析 http 响应体
        try {
            // 3.1. 如果方法声明返回体是 Response 就直接返回
            if (Response.class == metadata.returnType()) {
                return response;
            }
            // 3.2. 如果状态码是 200 或者 404 就解码
            if (response.status() >= 200 && response.status() < 300) {
                return decoder.decode(response, metadata.returnType());
            } else if (decode404 && response.status() == 404 && void.class != metadata.returnType()) {
                return decoder.decode(response, metadata.returnType());
            } 
            // 3.3. 否则使用错误解码器
            else {
                throw errorDecoder.decode(metadata.configKey(), response);
            }
        } catch (IOException e) {
            // 3.3. 然后跑出异常
            throw errorReading(request, response, e);
        } finally {
            ensureClosed(response.body());
        }
    }
}
```

## 拦截器的注入时机
拦截器是在创建`Feign.Builder`时初始化的, 具体代码如下
```java
// org.springframework.cloud.openfeign.FeignClientFactoryBean#configureFeign
class FeignClientFactoryBean implements FactoryBean<Object>, InitializingBean, ApplicationContextAware {
    protected void configureFeign(FeignContext context, Feign.Builder builder) {
        FeignClientProperties properties = this.applicationContext.getBean(FeignClientProperties.class);
        // FeignAutoConfiguration 里注入了, 必定为 true
        if (properties != null) {
            // 默认也是 true, 这里主要是配置优先级不同
            if (properties.isDefaultToProperties()) {
                configureUsingConfiguration(context, builder);
                // @EnableFeignClients#defaultConfiguration 自定义全局默认配置
                configureUsingProperties(properties.getConfig().get(properties.getDefaultConfig()), builder);
                // @FeignClient#configuration 单个Feign接口局部配置
                configureUsingProperties(properties.getConfig().get(this.contextId), builder);
            } else {
                // @EnableFeignClients#defaultConfiguration 自定义全局默认配置
                configureUsingProperties(properties.getConfig().get(properties.getDefaultConfig()), builder);
                // @FeignClient#configuration 单个Feign接口局部配置
                configureUsingProperties(properties.getConfig().get(this.contextId), builder);
                // 去 Spring 容器中找配置
                configureUsingConfiguration(context, builder);
            }
        } else {
            // 去 Spring 容器中找配置
            configureUsingConfiguration(context, builder);
        }
    }
}
```
默认情况下, `Feign`会依次从`Spring`容器、`@EnableFeignClients#defaultConfiguration`、`@FeignClient#configuration`寻找相关配置.
值得注意的一点是, 不要将`@EnableFeignClients#defaultConfiguration`、`@FeignClient#configuration`的配置声明为`Bean`.
因为`Feign`已经将配置注册到`FeignClientSpecification`类的实例`Bean`中了. 在上面也有提到.

# 流程图
![feign流程](https://yuml.me/diagram/nofunky;dir:UD/class/[@EnableFeignClients]->[FeignClientsRegistrar],[FeignClientsRegistrar]->[FeignClientFactoryBean],[FeignClientFactoryBean]->[ReflectiveFeign$FeignInvocationHandler])
