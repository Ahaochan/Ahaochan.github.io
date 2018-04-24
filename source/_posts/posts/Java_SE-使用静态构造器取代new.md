---
title: 使用静态构造器取代new
url: use_static_method_to_replace_new_object
date: 2017-11-04 15:21:05
tags:
  - 最佳实践
categories:
  - Java SE
---

# 前言
一般创建对象都是new出来的, Spring提供的是xml反射(或者使用注解)创建, 将创建对象的任务交给Spring完成。
不懂Spring可以将其理解为一个存储对象的容器。
控制反转并不是什么高大上的东西,  我们也可以做一个小的控制反转的例子。
<!-- more -->

# 使用静态构造器取代new
比如有个学生类, 将`构造函数`私有化, 同时创建一个静态的`create`方法。
```java
public class Student{
    private Student(){
    }
    public static Student create(){
        return new Student();
    }
}
```
这样做有什么好处呢?
很明显, 我们能给构造函数**命名**了。
维护者不再需要去猜测`new Student(true)`是什么意思。

还体现了职责分离, 创建对象的具体过程交给了对象类自己完成, 外部调用者不需要关心创建对象的流程。
这里为了体现差异, 将方法名写为中文, 实际开发不推荐写中文。
```java
public class Student{
    boolean 优秀;
    private Student(boolean status){
        this.优秀 = status;
    }
    public static Student 获得一个优秀学生(){
        return new Student(true);
    }
    public static Student 获得一个不好学生(){
        return new Student(false);
    }
}
```