---
title: 异构语言接入Java微服务
url: Polyglot_support_with_Sidecar
tags:
  - Spring Cloud
categories:
  - Spring Cloud
date: 2020-04-02 11:06:18
---

# 前言
作为微服务体系, 应该是不限语言的, 不管是`php`、`nodejs`、`python`、`java`, 都可以是一个微服务.
本文将说明如何将`php`、`nodejs`、`python`接入`Java`微服务体系下.

<!-- more -->

# Sidecar
目前`Spring Cloud`主流使用的是`Sidecar`方式.
{% img /images/异构语言接入Java微服务_01.png %}

`Sidecar`作为一个中转服务, 和`PHP`服务存在同一个服务器上, 做到低延迟通信.
当`PHP`服务启动完毕后, 启动`Sidecar`服务. 
此时`Sidecar`会做三件事.
1. `Sidecar`会将`PHP`服务所在服务器的`IP`和端口, 注册到注册中心, 成为一个微服务.
2. `Sidecar`会定时检测`PHP`服务的健康状态, 也就是调用一下`PHP`服务的接口, 看有没有返回数据, 没有就从注册中心注销`PHP`服务
3. `PHP`服务想要调用其他微服务接口需要通过`Sidecar`中转, `Sidecar`会将来自`PHP`的请求路由到其他微服务.

接下来讲一下`Spring`主流的具体实现.

# Spring Cloud Netflix Sidecar
一代目的`Spring Cloud`全家桶, 也可以叫`Netflix`全家桶, 理所当然的, 它提供的`Sidecar`, 只支持了自家的`Eureka`.

## 第一步, 注册到注册中心
先来看看入口[`SidecarAutoConfiguration`](https://github.com/spring-cloud/spring-cloud-netflix/blob/2.2.x/spring-cloud-netflix-sidecar/src/main/java/org/springframework/cloud/netflix/sidecar/SidecarAutoConfiguration.java)
```java
// org.springframework.cloud.netflix.sidecar.SidecarAutoConfiguration
@Configuration(proxyBeanMethods = false)
public class SidecarAutoConfiguration {
    @Configuration(proxyBeanMethods = false)
    @ConditionalOnClass(EurekaClientConfig.class)
    protected static class EurekaInstanceConfigBeanConfiguration {
        @Bean
        @ConditionalOnMissingBean
        public EurekaInstanceConfigBean eurekaInstanceConfigBean(ManagementMetadataProvider managementMetadataProvider) {
            EurekaInstanceConfigBean config = new EurekaInstanceConfigBean(inetUtils);
            int port = this.sidecarProperties.getPort();
            config.setNonSecurePort(port);
            String ipAddress = this.sidecarProperties.getIpAddress();
            config.setIpAddress(ipAddress);
            return config;
        }
    }
}
```
我们可以看到`SidecarAutoConfiguration`注册了一个`EurekaInstanceConfigBean`.
我们再看看客户端的配置`EurekaClientAutoConfiguration`.
```java
// org.springframework.cloud.netflix.eureka.SidecarAutoConfiguration
@Configuration(proxyBeanMethods = false)
public class EurekaClientAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean(value = EurekaInstanceConfig.class, search = SearchStrategy.CURRENT)
    public EurekaInstanceConfigBean eurekaInstanceConfigBean(InetUtils inetUtils, ManagementMetadataProvider managementMetadataProvider) {
    }
}
```
这里也有一个`EurekaInstanceConfigBean`.
也就是说`SidecarAutoConfiguration`的`EurekaInstanceConfigBean`覆盖了`EurekaClientAutoConfiguration`的`EurekaInstanceConfigBean`.
将`PHP`服务注册到注册中心, 具体怎么注册的, 涉及`Eureka`的源码, 这里就不细讲.

## 第二步, 定时任务检查健康状态
继续看入口[`SidecarAutoConfiguration`](https://github.com/spring-cloud/spring-cloud-netflix/blob/2.2.x/spring-cloud-netflix-sidecar/src/main/java/org/springframework/cloud/netflix/sidecar/SidecarAutoConfiguration.java)
```java
// org.springframework.cloud.netflix.sidecar.SidecarAutoConfiguration
@Configuration(proxyBeanMethods = false)
public class SidecarAutoConfiguration {
    @Bean
    public LocalApplicationHealthIndicator localApplicationHealthIndicator() {
        return new LocalApplicationHealthIndicator();
    }
    @Configuration(proxyBeanMethods = false)
    @ConditionalOnClass(EurekaClientConfig.class)
    protected static class EurekaInstanceConfigBeanConfiguration {
        @Bean
        public HealthCheckHandler healthCheckHandler(final LocalApplicationHealthIndicator healthIndicator) {
            // 注入上面的 LocalApplicationHealthIndicator
            return new LocalApplicationHealthCheckHandler(healthIndicator);
        }
    }
}
// org.springframework.cloud.netflix.sidecar.LocalApplicationHealthCheckHandler
class LocalApplicationHealthCheckHandler implements HealthCheckHandler {
    // 注入进来的 LocalApplicationHealthIndicator
    private final HealthIndicator healthIndicator;
    LocalApplicationHealthCheckHandler(HealthIndicator healthIndicator) {
        this.healthIndicator = healthIndicator;
    }

    @Override
    public InstanceStatus getStatus(InstanceStatus currentStatus) {
        // 具体的心跳检测逻辑
        Status status = healthIndicator.health().getStatus();
        if (status.equals(Status.UP)) { return UP; }
        else if (status.equals(Status.OUT_OF_SERVICE)) { return OUT_OF_SERVICE; }
        else if (status.equals(Status.DOWN)) { return DOWN; }
        return UNKNOWN;
    }

}
```
可以看到`LocalApplicationHealthCheckHandler`是一个`LocalApplicationHealthIndicator`的装饰类.
主要是调用`LocalApplicationHealthIndicator`来进行心跳检测. `LocalApplicationHealthIndicator`实现了`Eureka`的`HealthCheckHandler`接口.

## 第三步, Sidecar会将来自PHP的请求路由到其他微服务
我们看[`pom.xml`](https://github.com/spring-cloud/spring-cloud-netflix/blob/2.2.x/spring-cloud-netflix-sidecar/pom.xml)的依赖.
可以看到主要依赖了`Zuul`.
`Zuul`的默认转发规则是`/微服务名称/具体uri`.
所以如果`PHP`服务要调用其他微服务, 只要访问`http://127.0.0.1:${Sidecar端口}/${微服务名称}/hello`即可.

# Spring Cloud Alibaba Sidecar
接下来是二代目的`Spring Cloud`全家桶, 也可以叫`Alibaba`全家桶, 除了支持自家的`Nacos`, 还支持了`consul`.

## 第一步, 注册到注册中心
这里以`Nacos`为例.
继续看入口[`SidecarNacosAutoConfiguration`](https://github.com/alibaba/spring-cloud-alibaba/blob/greenwich/spring-cloud-alibaba-sidecar/src/main/java/com/alibaba/cloud/sidecar/nacos/SidecarNacosAutoConfiguration.java)
这里比[`Netflix Sidecar`](https://github.com/spring-cloud/spring-cloud-netflix/blob/2.2.x/spring-cloud-netflix-sidecar/src/main/java/org/springframework/cloud/netflix/sidecar/SidecarAutoConfiguration.java)的简单多了.
```java
// com.alibaba.cloud.sidecar.nacos.SidecarNacosAutoConfiguration
@Configuration
public class SidecarNacosAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean
    public SidecarDiscoveryClient sidecarDiscoveryClient(SidecarNacosDiscoveryProperties sidecarNacosDiscoveryProperties) {
        return new SidecarNacosDiscoveryClient(sidecarNacosDiscoveryProperties);
    }
}
// com.alibaba.cloud.sidecar.nacos.SidecarNacosDiscoveryClient
public class SidecarNacosDiscoveryClient implements SidecarDiscoveryClient {
    private final SidecarNacosDiscoveryProperties sidecarNacosDiscoveryProperties;
    @Override
    public void registerInstance(String applicationName, String ip, Integer port) {
        // 注册逻辑
        this.sidecarNacosDiscoveryProperties.namingServiceInstance().registerInstance(applicationName, ip, port);
    }
    @Override
    public void deregisterInstance(String applicationName, String ip, Integer port) {
        // 注销逻辑
        this.sidecarNacosDiscoveryProperties.namingServiceInstance().deregisterInstance(applicationName, ip, port);
    }
}
```
一目了然, 注册和注销的方法, 调用的都是`Nacos`提供的`API`.

## 第二步, 定时任务检查健康状态
我们看[`SidecarAutoConfiguration`](https://github.com/alibaba/spring-cloud-alibaba/blob/greenwich/spring-cloud-alibaba-sidecar/src/main/java/com/alibaba/cloud/sidecar/SidecarAutoConfiguration.java)
```java
// com.alibaba.cloud.sidecar.SidecarAutoConfiguration
@Configuration(proxyBeanMethods = false)
public class SidecarAutoConfiguration {
    @Bean
    public SidecarHealthChecker sidecarHealthChecker(SidecarDiscoveryClient sidecarDiscoveryClient, SidecarHealthIndicator sidecarHealthIndicator, SidecarProperties sidecarProperties, ConfigurableEnvironment environment) {
        SidecarHealthChecker cleaner = new SidecarHealthChecker(sidecarDiscoveryClient, sidecarHealthIndicator, sidecarProperties, environment);
        cleaner.check();
        return cleaner;
    }
}
// com.alibaba.cloud.sidecar.SidecarHealthChecker
public class SidecarHealthChecker {
    public void check() {
        // 1. 开启一个定时任务
        Schedulers.single().schedulePeriodically(() -> {
            String ip = sidecarProperties.getIp();
            Integer port = sidecarProperties.getPort();

            // 2. 调用 http 请求
            Status status = healthIndicator.health().getStatus();
            String applicationName = environment.getProperty("spring.application.name");

            // 3. 健康则续期, 否则注销
            if (status.equals(Status.UP)) {
                this.sidecarDiscoveryClient.registerInstance(applicationName, ip, port);
            } else {
                this.sidecarDiscoveryClient.deregisterInstance(applicationName, ip, port);
            }
        }, 0, sidecarProperties.getHealthCheckInterval(), TimeUnit.MILLISECONDS);
    }
}
```
还是老套路, `Sidecar`通过`http`定时检测`PHP`服务的健康状态.
如果健康则继续续期, 否则从注册中心注销.

## 第三步, Sidecar会将来自PHP的请求路由到其他微服务
我们看[`pom.xml`](https://github.com/alibaba/spring-cloud-alibaba/blob/greenwich/spring-cloud-alibaba-sidecar/pom.xml)
可以看到依赖了`Spring Cloud Gateway`.
和`Zuul`一样. 只要访问`http://127.0.0.1:${Sidecar端口}/${微服务名称}/hello`即可调用其他微服务.

# 参考资料
- [Polyglot support with Sidecar](https://cloud.spring.io/spring-cloud-netflix/multi/multi__polyglot_support_with_sidecar.html)
