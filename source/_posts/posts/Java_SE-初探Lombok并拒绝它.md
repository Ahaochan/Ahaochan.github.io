---
title: 初探Lombok并拒绝它
url: learn_Lombok_and_reject_it
tags:
  - Lombok
categories:
  - Java SE
date: 2018-04-18 11:21:33
---
# 前言
在一个`GitHub`项目发现它使用了`Lombok`这个工具。没见过所以了解一下, 但是发现还是不太好用, 于是摒弃之。但好歹记录一下。

<!-- more -->

# 介绍
[Lombok](https://projectlombok.org/)是一个可以大量减少代码的工具, 通过`Pluggable Annotation Processing API`的方式解析注解, 在**编译期**为`class`文件注入`getter`或`setter`或`toString`等等诸如此类的代码。

# 准备工作
1. 开发工具[IDEA](https://www.jetbrains.com/idea/download/)
2. 在IDEA中安装[Lombok Plugin](https://plugins.jetbrains.com/plugin/6317)插件
3. 导入[org.projectlombok.lombok](https://mvnrepository.com/artifact/org.projectlombok/lombok)

# 示例
`Lombok`通过注解生效, [官方注解列表](https://projectlombok.org/features/all)
```java
@Getter
@Setter
public class User{
    private Long id;
    private String name;
}

public class MyTest() {
    public static void main(String[] args) {
        User user = new User();
        System.out.println("自动生成的方法:" + user.getId() + "," + user.getName());
    }
}
```

# 为什么摒弃它
1. `Lombok`具有太强的侵入性
2. 失去了封装的意义

## 具有太强的侵入性
我在第一次接触到到带有`Lombok`项目的时候, 编译报错, 虽然我导入了`Lombok`的`maven`地址, 但是仍然提示找不到`getter`方法。
点进去一看, 发现根本没有`getter`方法, 只有一个`@Getter`注解。

也就是说, 一旦你使用了`Lombok`, 所有编译你代码的人都必须使用`Lombok`编译, 传染性、侵入性太强

# 失去了封装的意义
更重要的是, **面向对象**。
如果我们只是不想写`getter`和`setter`方法, 不如就直接将`field`设置成`public`。
长久的写重复的`getter`和`setter`方法已经让人不知道为什么要这样写, 只知道大家都是这样写, 以前都是这样写, 所以这样写。
```java
public void setName(String name) {
    this.name = name;
}

public void setName(String name) {
    switch(name) {
        case "admin": this.name = "I am admin:"+name; break;
        case "user" : this.name = "I am user:" +name; break;
    }
}
```
第二个`setter`方法, 封装了逻辑操作, 和第一个方法不同, 这就是`setter`方法的意义。