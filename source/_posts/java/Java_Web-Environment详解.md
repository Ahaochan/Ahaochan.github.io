---
title: Environment详解
url: Environment_of_Spring_MVC
tags:
  - Spring MVC
  - 源码分析
categories:
  - Java Web
date: 2017-10-03 13:38:03
---
# 前言
` HttpServletBean ` 实现了 ` EnvironmentCapable ` 和 ` EnvironmentAware ` 接口。
Environment可以对一些应用变量进行初始化, 存储到内存中。方便 ` Bean ` 进行获取。

<!-- more -->

# Environment 初始化
查看 ` DispatcherServlet ` 的父类 ` HttpServletBean ` 的源码, 可以看到 ` HttpServletBean ` 的属性 `ConfigurableEnvironment` 接口的实现类是 `StandardServletEnvironment`。
```java
// org.springframework.web.servlet.HttpServletBean
public abstract class HttpServletBean
        extends HttpServlet implements EnvironmentCapable, EnvironmentAware {
    private ConfigurableEnvironment environment;
    // 省略部分代码
    @Override
    public void setEnvironment(Environment environment) {
        this.environment = (ConfigurableEnvironment) environment;
    }   
    @Override
    public ConfigurableEnvironment getEnvironment() {
        if (this.environment == null) {
            this.environment = createEnvironment();
        }
        return this.environment;
    }   
    protected ConfigurableEnvironment createEnvironment() {
        // 默认实现类是 StandardServletEnvironment
        return new StandardServletEnvironment();
    }
}
```

**继承树**
![Environment 继承树](https://yuml.me/diagram/nofunky/class/[StandardEnvironment]^-[StandardServletEnvironment],[AbstractEnvironment]^-[StandardEnvironment],[<<ConfigurableWebEnvironment>>;interface]^-[StandardServletEnvironment],[<<ConfigurableEnvironment>>;interface]^-[<<ConfigurableWebEnvironment>>;interface],[<<ConfigurableEnvironment>>;interface]^-[AbstractEnvironment])


先明确一个概念, Environment 是用来装载 `属性` 的。
 ` StandardServletEnvironment ` 的父类 ` AbstractEnvironment `
 里面的 ` MutablePropertySources ` 属性（可以看成 ` LinkedHashMap<String, String> `）封装了 5 个属性(稍后说明为什么)

- ServletContext ( 封装 context-param )
- ServletConfig ( 封装 init-param )
- JndiProperty
- 系统环境变量
- JVM 系统属性变量

那么观察下子类 `StandardServletEnvironment` 的源码，以及父类`StandardEnvironment` 的源码, 发现主要的方法就是 `customizePropertySources() ` , 也就是对 ` MutablePropertySources ` 属性进行操作
```java
// org.springframework.web.context.support.StandardServletEnvironment
public class StandardServletEnvironment
        extends StandardEnvironment implements ConfigurableWebEnvironment {
    // 省略部分代码
    @Override
    protected void customizePropertySources(MutablePropertySources propertySources) {
        // propertySources 可以看成 LinkedHashMap
        // 装载 ServletConfig 的占位符, 延迟载入
        propertySources.addLast(new StubPropertySource("servletConfigInitParams"));
        // 装载 ServletContext 的占位符, 延迟载入
        propertySources.addLast(new StubPropertySource("servletContextInitParams"));
        // 装载 JndiProperties
        if (JndiLocatorDelegate.isDefaultJndiEnvironmentAvailable()) {
            propertySources.addLast(new JndiPropertySource("jndiProperties"));
        }
        // 父类StandardEnvironment 负责装载 系统环境变量 和 JVM 系统属性变量
        super.customizePropertySources(propertySources);
    }
    @Override
    public void initPropertySources(ServletContext servletContext, ServletConfig servletConfig) {
        // FrameworkServlet 在刷新时调用, 延迟载入
        // 将ServletContext和ServletConfig注入PropertySources中
        WebApplicationContextUtils.initServletPropertySources(getPropertySources(), servletContext, servletConfig);
    }
}
// org.springframework.core.env.StandardEnvironment
public class StandardEnvironment extends AbstractEnvironment {
    @Override
    protected void customizePropertySources(MutablePropertySources propertySources) {
        // 装载 系统环境变量
        propertySources.addLast(new MapPropertySource("systemEnvironment", getSystemProperties()));
        // 装载 JVM 系统属性变量
        propertySources.addLast(new SystemEnvironmentPropertySource("systemProperties", getSystemEnvironment()));
    }
    @Override
    public Map<String, Object> getSystemProperties() {
        try {
            return (Map) System.getProperties();
        } catch (AccessControlException ex) {
            return (Map) new ReadOnlySystemAttributesMap() {
                @Override
                protected String getSystemAttribute(String attributeName) {
                    try {
                        return System.getProperty(attributeName);
                    } catch (AccessControlException ex) {
                        return null;
                    }
                }
            };
        }
    }
    @Override
    public Map<String, Object> getSystemEnvironment() {
        if (suppressGetenvAccess()) {
            return Collections.emptyMap();
        } try {
            return (Map) System.getenv();
        } catch (AccessControlException ex) {
            return (Map) new ReadOnlySystemAttributesMap() {
                @Override
                protected String getSystemAttribute(String attributeName) {
                    try {
                        return System.getenv(attributeName);
                    } catch (AccessControlException ex) {
                        return null;
                    }
                }
            };
        }
    }
}
```
可以猜测出方法的参数 `propertySources` 是一个装载 `属性` 的集合。那么 ` customizePropertySources ` 的参数 ` propertySources ` 一定不为 `null` , 也就是 ` propertySources ` 被初始化过。
初始化一般发生在 `构造方法` 或者 `field 直接 new` 中。
但是 ` StandardServletEnvironment ` 并没有构造方法, 其父类
 ` StandardEnvironment ` 也没有构造方法。
那么只能看最顶层的父类 `AbstractEnvironment` 。
```java
// org.springframework.core.env.AbstractEnvironment
public abstract class AbstractEnvironment implements ConfigurableEnvironment {
    // 省略部分代码
    private final MutablePropertySources propertySources = new MutablePropertySources(this.logger);
    public AbstractEnvironment() {
        customizePropertySources(this.propertySources);
    }
    protected void customizePropertySources(MutablePropertySources propertySources) {
    }
}
```
又看到了熟悉的 `customizePropertySources()` 方法。
可以看到 `propertySources` 是在 field 直接 `new` 出来的。
 ` propertySources ` 的实现类是 `MutablePropertySources` , 里面有一个
 `CopyOnWriteArrayList` 集合，集合中的 `PropertySource` 是一个  `键值对` , 可以看成是 ` Map.Entry `。
```java
// org.springframework.core.env.MutablePropertySources
public class MutablePropertySources implements PropertySources {
    private final List<PropertySource<?>> propertySourceList = new CopyOnWriteArrayList<PropertySource<?>>();
}

// org.springframework.core.env.PropertySources
public interface PropertySources extends Iterable<PropertySource<?>> {
    boolean contains(String name);
    PropertySource<?> get(String name);
}

// org.springframework.core.env.PropertySource
public abstract class PropertySource<T> {
    
    // 以 键值对 形式存储
    protected final String name;
    protected final T source;

    // 省略 构造器 和 getter 和 setter 方法
    // hashcode 和 equals 只判断 name 属性
	
    public boolean containsProperty(String name) {
        return (getProperty(name) != null);
    }
    // 交给内部类子类 StubPropertySource 和 ComparisonPropertySource 实现
    public abstract Object getProperty(String name);

    // 类似占位符, 在实际的属性不能被及时初始化时保留，并在 Context 刷新时进行替换
    public static class StubPropertySource extends PropertySource<Object> {
        public StubPropertySource(String name) {
            super(name, new Object());
        }
        @Override
        public String getProperty(String name) {
            return null;
        }
    }

    // 类似占位符, 在实际的属性不能被及时初始化时保留，并在 Context 刷新时进行替换
    static class ComparisonPropertySource extends StubPropertySource {
        // 省略部分代码
    }
	
    public static PropertySource<?> named(String name) {
        return new ComparisonPropertySource(name);
    }
}
```

总结说, 就是 `AbstractEnvironment` 类的 `MutablePropertySources` 中的
 `CopyOnWriteArrayList` 集合中, 装载了 5 个属性

- ServletContext ( StandardServletEnvironment 装载, 封装 context-param )
- ServletConfig ( StandardServletEnvironment 装载, 封装 init-param )
- JndiProperty ( StandardServletEnvironment 装载 )
- 系统环境变量 ( StandardEnvironment 装载 )
- JVM 系统属性变量 ( StandardEnvironment 装载 )、

需要注意的是，这里 ` ServletContext ` 和 ` ServletConfig  ` 要等到 
 ` FrameworkServlet ` 刷新的时候调用 ` StandardServletEnvironment ` 的 ` initPropertySources ` 方法, 来刷新这两个属性。
```java
// org.springframework.web.context.support.StandardServletEnvironment
public class StandardServletEnvironment
        extends StandardEnvironment implements ConfigurableWebEnvironment {
    @Override
    public void initPropertySources(ServletContext servletContext, ServletConfig servletConfig) {
        // FrameworkServlet 在刷新时调用
        // 将ServletContext和ServletConfig注入PropertySources中
        WebApplicationContextUtils.initServletPropertySources(getPropertySources(), servletContext, servletConfig);
    }
}
// org.springframework.web.context.support.WebApplicationContextUtils
public abstract class WebApplicationContextUtils {
    public static void initServletPropertySources(
        MutablePropertySources propertySources, ServletContext servletContext, ServletConfig servletConfig) {
        // 省略部分代码
        propertySources.replace("servletContextInitParams",
					new ServletContextPropertySource("servletContextInitParams", servletContext));
        propertySources.replace("servletConfigInitParams",
					new ServletConfigPropertySource("servletConfigInitParams", servletConfig));
	}
}
```

# Environment 的使用
` Spring ` 开放了 ` EnvironmentAware  ` 和 ` EnvironmentCapable `接口。
- `EnvironmentAware` 由 Spring 框架往 Bean 内 `注入Environment` 
- `EnvironmentCapable`  通过 getEnvironment 往外面 `暴露Environment`

开发者只需要实现这两个接口，Spring就会自动注入。
```xml
<!-- web.xml 省略部分代码 -->
<?xml version="1.0" encoding="UTF-8"?>
<web-app>
    <context-param>  
        <param-name>myConfig</param-name>  
        <param-value>hello</param-value>  
    </context-param>  
</web-app>
```
```java
public class User implements EnvironmentAware, EnvironmentCapable {
    private String name;
    private int age;
    private Environment environment;

    public String getHello() {
        return environment.getProperty("myConfig");
    }

    @Override
    public void setEnvironment(Environment environment) {
        // 注入 Environment 
        this.environment = environment;
    }

    @Override
    public Environment getEnvironment() {
        // 暴露 Environment 
        return environment;
    }
}
```
