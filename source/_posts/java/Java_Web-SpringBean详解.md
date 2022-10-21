---
title: SpringBean详解
url: Spring_Bean
tags:
  - Spring
categories:
  - Java Web
date: 2017-02-26 14:42:38
---
# 前言
在`Spring`中，类的创建不再由`new`进行，而是交给`Spring`通过`xml`文件进行反射创建，这种叫做控制反转`IoC`(`Inversion of Control`)，也叫做依赖注入`DI`(`Dependency Injection`)。
<!-- more -->
# 简单的Bean例子
导入[maven项目](https://mvnrepository.com/artifact/org.springframework/spring-context/4.3.6.RELEASE)
创建一个`Person`类，并在xml中配置bean信息
```xml
<?xml version="1.0" encoding="gbk"?>
<beans xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="http://www.springframework.org/schema/beans"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd"
>
    <bean id="personId" class="com.ahao.javaeeDemo.Person">
        <property name="name" value="张三" />
        <property name="age" value="12"/>
    </bean>
</beans>
```
在测试类中通过`ApplicationContext`进行创建对象
```java
@Test
public void testGetPerson(){
    ApplicationContext ac = new ClassPathXmlApplicationContext("spring-bean.xml");
    Person p1 = ac.getBean("personId", Person.class);
    System.out.println(p1.getName()+","+p1.getAge());
}
```

# Bean的生命周期
1. Bean先new进行`实例化`
1. 然后`注入属性`。
1. 若实现了`BeanNameAware`接口，将Bean的`ID`传入`setBeanName()`方法。
1. 若实现了`BeanFactoryAware`接口，将BeanFactory容器实例传入`setBeanFactory()`方法。
1. 若实现了`ApplicationContextAware`接口，通过`setApplicationContext()`方法获取应用上下文。
1. 调用`BeanPostProcessor`后处理器的预初始化方法。
1. 调用`InitializingBean`接口`afterPropertiesSet()`方法。
1. 配置文件`bean`标签下的`init-method`属性指定的`方法`。
1. 配置文件`beans`标签下的`default-init-method`全局属性指定的`方法`。
1. 调用`BeanPostProcessor`后处理器的预初始化后方法。
1. 使用Bean
1. 调用`DisposableBean`接口`destory`方法。
1. 配置文件`bean`标签下的`destory-method`属性指定的`方法`。
1. 配置文件`beans`标签下的`default-destory-method`全局属性指定的`方法`。

# Bean的创建
`Bean`的创建都交由`xml`配置文件执行，获取`Bean`实例都是通过`getBean`方法进行。
## 普通new创建
```xml
<beans>
    <bean id="person" class="com.ahao.javaeeDemo.bean.Person"/>
</beans>
```

## 静态工厂创建
需要一个静态工厂类
```java
public class BeanFactory{
    public static Person getPerson(String type){
        if(type.equals("chinese")){
            return new Chinese();
        }
    }
}
```
在`xml`文件中配置，指定`factory-method`属性，获取实例用`getBean()`方法即可
```xml
<beans>
   <bean id="chinese" class="com.ahao.javaeeDemo.factory.PersonFactory" factory-method="getPerson">
        <constructor-arg value="chinese" />
        <property name="axe" ref="steelAxe"/>
    </bean>
</beans>
```
## 实例工厂创建
需要一个工厂类，注意这里和静态工厂的不同是不用`static`修饰方法
```java
public class BeanFactory{
    public Person getPerson(String type){
        if(type.equals("chinese")){
            return new Chinese();
        }
    }
}
```
在`xml`文件中配置，指定`factory-method`属性，获取实例用`getBean()`方法即可
```xml
<beans>
    <bean id="personFactory" class="com.ahao.javaeeDemo.factory.PersonFactory" />
    <bean id="chinese" factory-bean="personFactory" factory-method="getPerson">
        <constructor-arg value="chinese" />
        <property name="axe" ref="steelAxe"/>
    </bean>
</beans>
```

## 工厂Bean创建
工厂`Bean`继承自`FactoryBean`
```java
public class PersonFactory implements FactoryBean<Person> {
    private Person person;

    @Override
    public Person getObject() throws Exception {
        if(person == null){
            person = new Chinese();
        }
        return person;
    }

    @Override
    public Class<?> getObjectType() {
        return person.getClass();
    }

    @Override
    public boolean isSingleton() {
        return true;
    }
}
```
在`spring-bean.xml`中配置，获取`BeanFactory`时使用`&chinese`
```xml
<beans>
    <bean id="chinese" class="com.ahao.javaeeDemo.factory.PersonFactory" />
</beans>
```
和上面一样使用
```java
@Test
public void testEvent(){
    ApplicationContext ac = new ClassPathXmlApplicationContext("spring-bean.xml");
    Person p1 = ac.getBean("chinese", Person.class);
    p1.setAxe(new StoneAxe());
    p1.useAxe();
    System.out.print(ac.getBean("&chinese"));//获取BeanFactory
}
```


# scope作用域
在`bean`标签中的`scope`属性有五个值
- `singleton`：单例模式，整个Spring容器中只有一个实例
- `prototype`：原型模式，每次通过getBean方法都将产生一个新的实例
- `request`：对每次request请求，都会产生一个新的实例
- `session`：对每次session会话，都会产生一个新的实例
- `global session`：[spring-bean-scopes-session-and-globalsession](https://stackoverflow.com/questions/15407038/spring-bean-scopes-session-and-globalsession)
其中`request`、`session`
在`Servlet2.4`以上要在`web.xml`中配置`Listener`
在`Servlet2.4`以下要在`web.xml`中配置`Filter`
并且要导入[maven项目](https://mvnrepository.com/artifact/org.springframework/spring-web)
```xml
<web-app>
    <listener><!--Servlet2.4以上-->
        <listener-class>org.springframework.web.context.request.RequestContextListener</listener-class>
    </listener>
    <filter><!--Servlet2.4以下-->
        <filter-name>requestContextFilter</filter-name>
        <filter-class>org.springframework.web.filter.RequestContextFilter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>requestContextFilter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
</web-app>
```

# 自动装配注入
自动装配减少了配置文件的工作量，但降低了依赖关系的透明性和清晰性。
显示指定的依赖会覆盖自动装配的依赖
## byName规则
在`bean`标签添加`autowire="byName"`属性，当`A`类中有`setB`方法，且`beans`中有`id`为`b`的`bean`，则自动装配注入。
```xml
<beans>
    <bean id="person" class="com.ahao.javaeeDemo.bean.Person" autoWire="byName"/>
    <bean id="axe" class="com.ahao.javaeeDemo.bean.StoneAxe" />
</beans>
```

## byType规则
在`bean`标签添加`autowire="byType"`属性，当`A`类中有`B`类型的`Field`，且`beans`中只有一个`B`类型或者`B`的子类型的`bean`，则自动装配注入。
如果有多个匹配的`bean`，则抛出异常，使用`autowire-candidate="false"`即可忽略该`bean`。
```xml
<beans>
    <bean id="person" class="com.ahao.javaeeDemo.bean.Person" autoWire="byType"/>
    <bean class="com.ahao.javaeeDemo.bean.StoneAxe" />
    <bean id="steelAxe" class="com.ahao.javaeeDemo.bean.SteelAxe" autowire-candidate="false"/>
</beans>
```
