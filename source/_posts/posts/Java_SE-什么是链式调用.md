---
title: 什么是链式调用
url: what_is_Methods_Chaining_in_Java
date: 2017-11-04 15:21:05
tags:
  - 最佳实践
categories:
  - Java SE
---

# 前言
Java8流行的函数式编程使用的方式类似于`a.b().c().d()`, 仿佛能无穷无尽点下去。
其实这个代码很简单, 换一种写法大概就懂了`this.getClass().getSimpleName().length();`。
在wiki上也有介绍: [Fluent_interface](https://en.wikipedia.org/wiki/Fluent_interface)
<!-- more -->

# 实现
其实链式调用很简单, 就是一个`return 对象;`的事情。
比如`return this;`等。
```java
public class Student{
    private String name;
    private int age;
    public static create(){
        return new Student();
    }
    public void setName(String name){
        this.name = name; // 普通的设置属性
    }
    public void setAge(int age){
        this.age = age; // 普通的设置属性
    }
    public Student name(String name){
        this.name = name; // 链式的设置属性
        return this;
    }
    public Student age(int age){
        this.name = name; // 链式的设置属性
        return this;
    }
}
```
调用结果如下
```java
public class Main{
    public static void main(String[] args){
        Student s1 = new Student();
        s1.setName("stu1");
        s1.setAge(12);
        // 明显链式调用方法比较优雅
        Student s2 = Student.create().name("stu2").age(12);
    }
}
```

# 优势和缺陷
显而易见, 使用链式调用的代码更加简洁优雅, 方法间的关联度紧密。
同样缺陷也在这里, 每个方法都依赖上一个方法, 如果有一个返回空指针, 那么就会报错。需要代码编写人员的功底比较强。
当然, `return this;`是不可能空指针异常的。
