---
title: ApplicationContext的事件机制
url: The_event_mechanism_of_ApplicationContext
tags:
  - Spring
categories:
  - Java Web
date: 2017-02-26 14:40:27
---

# 简单例子
完成事件机制首先需要一个事件源和事件监听器
`ApplicationEvent`事件和`ApplicationListener`监听器
<!-- more -->
```java
public class SayEvent extends ApplicationEvent {
    public void say(){
        System.out.println(this.getSource()+" : hello world");
    }
}
public class SayListener implements ApplicationListener<SayEvent> {
    @Override
    public void onApplicationEvent(SayEvent sayEvent) {
        sayEvent.say();
    }
}
```
并且要在`xml`文件中配置好`ApplicationListener`监听器
```xml
<beans>
    <bean class="com.ahao.javaeeDemo.SayListener" />
</beans>
```
通过`ApplicationContext`发布事件
```java
@Test
public void testEvent(){
    ApplicationContext ac = new ClassPathXmlApplicationContext("spring-bean.xml");
    SayEvent event = new SayEvent("由testEvent()发出");
    ac.publishEvent(event);
}
```
`Spring`的事件监听机制是**观察者模式**的实现。
监听器可以监听任何事件。
输出结果：`由testEvent()发出 : hello world`

# 内置事件
Spring提供如下几个内置事件：

1. `ContextRefreshedEvent`：`ApplicationContext`容器初始化或刷新时触发该事件。此处的初始化是指：所有的`Bean`被成功装载，后处理`Bean`被检测并激活，所有`Singleton Bean` 被预实例化，`ApplicationContext`容器已就绪可用

2. `ContextStartedEvent`：当使用`ConfigurableApplicationContext`(`ApplicationContext`的子接口）接口的`start()`方法启动`ApplicationContext`容器时触发该事件。容器管理声明周期的`Bean`实例将获得一个指定的启动信号，这在经常需要停止后重新启动的场合比较常见

3. `ContextClosedEvent`：当使用`ConfigurableApplicationContext`接口的`close()`方法关闭`ApplicationContext`时触发该事件

4. `ContextStoppedEvent`：当使用`ConfigurableApplicationContext`接口的`stop()`方法使`ApplicationContext`容器停止时触发该事件。此处的停止，意味着容器管理生命周期的`Bean`实例将获得一个指定的停止信号，被停止的`Spring`容器可再次调用`start()`方法重新启动

5. `RequestHandledEvent`：`Web`相关事件，只能应用于使用`DispatcherServlet`的`Web`应用。在使用`Spring`作为前端的`MVC`控制器时，当`Spring`处理用户请求结束后，系统会自动触发该事件。

# 参考资料
- [Spring中ApplicationContext的事件机制](https://my.oschina.net/itblog/blog/203744)

