---
title: Spring Boot在Tomcat上使用
url: deploy_Spring_Boot_project_with_Tomcat
tags:
  - Spring Boot
  - Tomcat
categories:
  - Java Web
date: 2017-08-30 21:48:53
---


# 前言
一般的教程都是直接运行`main`方法, 看似脱离了`Tomcat`运行
实际上是使用的是内嵌的`Tomcat`
```java
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
```

<!-- more -->
而且打包出来的是`jar`包, 虽然可以直接运行, 但是如果想放在外部的`Tomcat`下, 就不太好了。

# 解决方案是 
1. 继承 ` SpringBootServletInitializer` 并重写 ` configure ` 方法
```java
@SpringBootApplication
@Controller
public class App extends SpringBootServletInitializer {
    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        // 可有可无的方法, 之后有解释
        return builder.sources(getClass());
    }
    public static void main(String[] args) {
        SpringApplication.run(App.class, args);
    }
}
```
2. 在项目的 `pom.xml` 设置 `<packaging>war</packaging>`, 注意, 多模块项目只需要在该模块的 ` pom.xml ` 设置即可
3. 添加[spring-boot-starter-tomcat依赖](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-tomcat/), 并设置 ` <scope>provided</scope> ` 
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-tomcat</artifactId>
    <scope>provided</scope>
</dependency>
```
4. 打`war包`部署到`Tomcat`

# 为什么要 继承SpringBootServletInitializer ?
![继承树 ](https://yuml.me/diagram/nofunky/class/[WebApplicationInitializer]^-[SpringBootServletInitializer],[SpringBootServletInitializer]^-[我的启动类])
首先明确一点, `Spring Boot `只是许多个`Spring`项目和其他项目整合起来, 并不是一个额外的项目, 你可以理解成一个封装了`Spring`、`SpringMVC`等项目的新项目。
那么, `Spring`有入口`ContextLoaderListener`、 `Spring MVC`有入口`DispatcherServlet`。那`Spring Boot`的入口当然就是`SpringBootServletInitializer`。
(当然如果你不用`war包`可以忽略这段话, 也不用看这篇文章)

看到熟悉的`ServletInitializer`, 这是[Servlet3.0新特性](https://ahaochan.github.io/Java/JavaWeb/JSP/Servlet3.0新特性.html#通过ServletContainerInitializer注册),  `Tomcat`会自动查找并运行实现了 ` ServletContainerInitializer ` 接口的类。
但是能自动加载的是 ` ServletContainerInitializer ` 及其子类, 和`SpringBootServletInitializer`及其父类` WebApplicationInitializer `
可是丝毫没有联系的, 能想到的就是有**另一个类**连接了这两个类。
这个类就是`SpringServletContainerInitializer`, 它会去加载所有的`WebApplicationInitializer`及其子类`SpringBootServletInitializer`。
```java
// org.springframework.web.SpringServletContainerInitializer
@HandlesTypes(WebApplicationInitializer.class)
// 继承了 ServletContainerInitializer , 所以能自动加载
public class SpringServletContainerInitializer implements ServletContainerInitializer {
    @Override
    // 1. 扫描HandlesTypes注解中的类或它的子类, 注入Set集合
    public void onStartup(Set<Class<?>> webAppInitializerClasses, ServletContext servletContext) throws ServletException {
        
        List<WebApplicationInitializer> initializers = new LinkedList<WebApplicationInitializer>();
        for (Class<?> waiClass : webAppInitializerClasses) {
            if (!waiClass.isInterface() && !Modifier.isAbstract(waiClass.getModifiers()) &&
                    WebApplicationInitializer.class.isAssignableFrom(waiClass)) {
                initializers.add((WebApplicationInitializer) waiClass.newInstance());
            }
        }

        AnnotationAwareOrderComparator.sort(initializers);
        for (WebApplicationInitializer initializer : initializers) {
            // 2. 核心方法, 调用WebApplicationInitializer的onStartup方法
            initializer.onStartup(servletContext);
        }
    }
}
```

` HandlesTypes ` 注解中的 ` WebApplicationInitializer ` 被注入到 ` Set集合 `中, 然后调用 ` WebApplicationInitializer`的`onStartup`方法。
至此, ` SpringBootServletInitializer ` 已经能随着`Tomcat`的启动而启动了。

# 为什么不用重写configure方法
很多网上的文章, 都说要重写 ` configure方法 `, 但是这对我上面那个`Hello world`例子是不需要的, 从源码中可以窥视一二。

```java
// org.springframework.boot.web.support.SpringBootServletInitializer
// 实现了 WebApplicationInitializer 接口, 所以也能间接的自动加载
public abstract class SpringBootServletInitializer implements WebApplicationInitializer {
    // 省略部分代码
    @Override
    public void onStartup(ServletContext servletContext) throws ServletException {
        // 1. 入口
        WebApplicationContext rootAppContext = createRootApplicationContext(servletContext);
        if (rootAppContext != null) {
            // 由于 application context 已被初始化，因此无操作
            // 这里加载了 ContextLoaderListener , 所以也不能自己再去实现 ContextLoaderListener
            servletContext.addListener(new ContextLoaderListener(rootAppContext) {
                @Override
                public void contextInitialized(ServletContextEvent event) {
                }
            });
        }
    }

    // 2. 创建 ApplicationContext
    protected WebApplicationContext createRootApplicationContext(ServletContext servletContext) {
        // 设计模式 之 建造器Builder模式
        SpringApplicationBuilder builder = createSpringApplicationBuilder();
        builder.main(getClass());
        ApplicationContext parent = getExistingRootWebApplicationContext(servletContext);
        if (parent != null) {
            this.logger.info("Root context already created (using as parent).");
            servletContext.setAttribute(
                    WebApplicationContext.ROOT_WEB_APPLICATION_CONTEXT_ATTRIBUTE, null);
            builder.initializers(new ParentContextApplicationContextInitializer(parent));
        }
        builder.initializers(
                new ServletContextApplicationContextInitializer(servletContext));
        builder.listeners(new ServletContextApplicationListener(servletContext));
        builder.contextClass(AnnotationConfigEmbeddedWebApplicationContext.class);
        // 调用 configure 方法, 默认不操作builder
        builder = configure(builder);
        SpringApplication application = builder.build();
        // 如果没有重写 configure 方法给 builder 添加 source 
        // 即 application 的 source(Set集合) 为空
        if (application.getSources().isEmpty() && AnnotationUtils
                .findAnnotation(getClass(), Configuration.class) != null) {
            // 且继承 SpringBootServletInitializer 自身的子类添加了 Configuration 注解
            // 因为 SpringBootApplication 注解继承了 Configuration 注解
            // 所以不用重写 configure方法 也可以加入 source 中
            application.getSources().add(getClass());
        }
        Assert.state(!application.getSources().isEmpty(),
                "No SpringApplication sources have been defined. Either override the "
                        + "configure method or add an @Configuration annotation");
        // Ensure error pages are registered
        if (this.registerErrorPageFilter) {
            application.getSources().add(ErrorPageFilterConfiguration.class);
        }
        return run(application);
    }

    // 默认不操作builder
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder;
    }
}
```
从`Configuration`注解的**类**可以注入 ` source ` 发现, 这个 ` source ` 就是存储`Spring`配置的, 当然, **不是`xml`**, 而是`java`配置。
也就是说
1. 只有一个`Java`配置类, 则直接继承 ` SpringBootServletInitializer` 即可。
2. 如果有多个`Java`配置类, 则继承 ` SpringBootServletInitializer` 之外，还要重写 ` configure ` 方法, 将配置类都注入进去, 包括 `SpringBootServletInitializer` 的子类。
