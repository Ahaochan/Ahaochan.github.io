---
title: 自定义Annotation学习笔记
url: how_to_custom_annotation
tags:
  - Annotation
categories:
  - Java SE
date: 2016-12-23 14:38:09
---

# JDK元注解
对注解使用的注解又称为**元注解**。
<!-- more -->

## @Retention
`Retention`意思是保留，声明这个注解的生存时间，包含了一个`RetentionPolicy`的枚举类的`value`成员变量。

```java
@Documented//1.3节知识
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)//1.2节知识
public @interface Retention {
    RetentionPolicy value();
}
```

| RetentionPolicy枚举 | 说明                                                    |
|:--------------------|:--------------------------------------------------------|
| CLASS               | 将Annotation记录在class文件中，运行时抛弃，这是默认值   |
| RUNTIME             | 将Annotation记录在class文件中，运行时保留，可以使用反射 |
| SOURCE              | 只将Annotation记录在java源代码中，用于编译提示报错      |

## @Target
`Target`意思是目标，表示这个注解可以用于`类`、`方法`、`Field`等不同地方。
可以看到`value`是一个`ElementType`枚举类的数组，即可以接收多个参数。
```java
@Documented//1.3节知识
@Retention(RetentionPolicy.RUNTIME)//1.1节知识
@Target(ElementType.ANNOTATION_TYPE)
public @interface Target {
    ElementType[] value();
}
```

| ElementType枚举 | 修饰范围             |
|:----------------|:---------------------|
| ANNOTATION_TYPE | 注解Annotation       |
| PACKAGE         | 包                   |
| TYPE            | 类、接口、注释、枚举 |
| CONSTRUCTOR     | 类构造器             |
| METHOD          | 方法                 |
| FIELD           | 成员变量             |
| LOCAL_VARIABLE  | 局部变量             |
| PARAMETER       | 形式参数             |

## @Documented
`Documented`意思是文档，修饰的`Annotation`将被`javadoc`提取成文档
```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Documented {
}
```

## @Inherited
`Inherited`意思是遗传，修饰的`Annotation`所修饰的类将具有继承性。即如果`A注解`被`@Inherited`修饰，那么被`A注解`修饰的`B类`的子类`C类`将默认被`A注解`修饰。
```java
@Documented
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.ANNOTATION_TYPE)
public @interface Inherited {
}
```

# 自定义Annotation
有了元注解，就可以自定义注解

## 声明
和普通的类、接口声明一样，使用`@interface`关键字即可。还可以添加成员变量(以方法的形式)，指定默认值。
```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface MyAnnotation{
    String name();
    int age() default 20;
}
```

## 获取注解信息
```java
public class Main {
    @MyAnnotation(name = "小明")
    public static void main(String[] args) {
        Test.test(Main.class);
    }
    @MyAnnotation(name = "小行", age=12)
        public void test1(){
    }
}
public class Test {
    @MyAnnotation(name="小明", age = 21)
    public static void test(Class c){
        for(Method m : c.getMethods()){
            for(Annotation a : m.getAnnotations()){
                if(a instanceof MyAnnotation){
                    MyAnnotation ma = (MyAnnotation) a;
                    System.out.println(m.getName()+":"+ma.name()+","+ma.age());
                }
            }
        }
    }
}
```
