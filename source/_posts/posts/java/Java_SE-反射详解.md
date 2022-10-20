---
title: 反射详解
url: Java_Reflection
tags:
  - 反射
categories:
  - Java SE
date: 2017-02-24 20:06:16
---

# 前言
学习框架底层必须要掌握反射。
<!-- more -->
```java
public class Person {
    /** 属性 */
    private String name;
    private int age;
    
    /** 构造器 */
    public Person(){    }
    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }
   
    /** getter And Setter */
}
```

# 获取类对象的三种方法
```java
@Test
public void testClass() throws ClassNotFoundException {
    Class c1 = Person.class;
    Class c2 = new Person().getClass();
    Class c3 = Class.forName("com.ahao.javaeeDemo.Person");
    System.out.print(c1+"\n"+c2+"\n"+c3);
}
```

# 通过反射创建对象
```java
@Test
public void testNew() throws ClassNotFoundException,
		IllegalAccessException, InstantiationException,
		NoSuchMethodException, InvocationTargetException {
    Class clazz = Class.forName("com.ahao.javaeeDemo.Person");
    Person p1 = (Person) clazz.newInstance();
    System.out.println("无参构造方法："+p1.toString());
    Person p2 = (Person) clazz.getConstructor(String.class, int.class).newInstance("张三", 12);
    System.out.println("有参构造方法："+p2.toString());
}
```

# 操作Field
```java
@Test
public void testField() throws ClassNotFoundException,
		NoSuchFieldException,
		IllegalAccessException, InstantiationException {
    Class clazz = Class.forName("com.ahao.javaeeDemo.Person");
    Person p1 = (Person) clazz.newInstance();

    Field name = clazz.getDeclaredField("name");//获取一个自己声明的Field，要访问父类Field要用getField()
    name.setAccessible(true);//默认只能操作public，如果要操作其他权限，需要使用这个方法
    name.set(p1, "张三");//相当于p1.name = "张三"
    System.out.println(p1.toString());
}
```

# 操作Method
```java
@Test
public void testMethod() throws ClassNotFoundException,
		IllegalAccessException, InstantiationException,
		NoSuchMethodException, InvocationTargetException {
    Class clazz = Class.forName("com.ahao.javaeeDemo.Person");
    Person p1 = (Person) clazz.newInstance();

    Method method = clazz.getDeclaredMethod("setName", String.class);//获取一个自己声明的Method，要访问父类Field要用getMethod()
    method.setAccessible(true);//默认只能操作public，如果要操作其他权限，需要使用这个方法
    method.invoke(p1, "张三");//相当于p1.setName("张三")
    System.out.println(p1.toString());
    //method.invoke(null, args);//当对象为null时，操作static方法
}
```
