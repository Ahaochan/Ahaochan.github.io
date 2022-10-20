---
title: Spring自动装配@Autowired的三种方式
url: Spring_uses_@Autowired_in_three_ways
tags:
  - Spring
  - 最佳实践
categories:
  - Java Web
date: 2017-05-03 22:18:29
---
# 前言
在IDEA升级2017版后，发现以前使用的`@Autowired`出现了个警告`Field injection is not recommended`。
虽然不是异常，但就是看着不舒服，所以google了一下，发现了[stackoverflow](http://stackoverflow.com/questions/39890849/what-exactly-is-field-injection-and-how-to-avoid-it) 已经有人提了这个问题，并得到了解答。
<!-- more -->

# @Autowired的不推荐用法
在一个Bean内，可以使用`@Autowired`注入另一个Bean。
```java
@Component
public class Dependency{
}

@Component
public class DI{
    @Autowired
    private Dependency dependency;
}
```
事实上，这就是我平常使用的方式，直接在`Field`上添加注解，简洁又好看。
但这是不推荐的使用方法。

# @Autowired的三种使用方式
1. 通过构造器注入
1. 通过setter方法注入
1. 通过field反射注入

```java
public class DI{
    //通过构造器注入
    private DependencyA a;
    @Autowired
    public DI(DependencyA a){
        this.a = a;
    }

    //通过setter方法注入
    private DependencyB b;
    @Autowired
    public void setDependencyB(DependencyB b){
        this.b = b;
    }
    
    //通过field反射注入
    @Autowired
    private DependencyC c;
}
```

# 弊端
**如果你使用的是构造器注入**
恭喜你，当你有十几个甚至更多对象需要注入时，你的构造函数的`参数个数`可能会长到无法想像。

**如果你使用的是field反射注入**
如果不使用Spring框架，这个属性只能通过反射注入，太麻烦了！这根本不符合`JavaBean`规范。
还有，当你不是用过`Spring`创建的对象时，还可能引起`NullPointerException`。
并且，你不能用`final`修饰这个属性。

**如果你使用的是setter方法注入**
那么你将不能将属性设置为`final`。

# 两者取其轻
Spring3.0官方文档建议使用setter注入覆盖构造器注入。
Spring4.0官方文档建议使用构造器注入。

# 结论
如果注入的属性是`必选`的属性，则通过构造器注入。
如果注入的属性是`可选`的属性，则通过setter方法注入。
至于field注入，不建议使用。

# 参考资料
1. [Field Dependency Injection Considered Harmful](http://vojtechruzicka.com/field-dependency-injection-considered-harmful/)
1. [What exactly is Field Injection and how to avoid it?](http://stackoverflow.com/questions/39890849/what-exactly-is-field-injection-and-how-to-avoid-it)

