---
title: 被忽视的初始化块
url: Ignored_initialization_block
tags:
  - 最佳实践
categories:
  - Java SE
date: 2018-03-27 11:12:04
---

# 前言
从学过初始化块之后, 就一直没用到, 今天学习`Mybatis`, 居然有一处语法没看懂。特此记录一下。
```java
public class PrivilegeProvider {
    public String selectById(final Long id){
        return new SQL(){
            {
                SELECT("id, privilege_name, privilege_url");
            }
        }.toString();
    }
}
```

<!-- more -->

# 初始化块
这可不是`Lambda`表达式, 因为环境是`JDK 1.7`。
而是**初始化块**。
我们自己创建个例子。
```java
public class MyList<E> {
    private ArrayList<E> list = new ArrayList<>();
    // 链式编程, 返回this
    public MyList<E> add(E e) {
        list.add(e);
        return this;
    }
}

public class MyTest {
    @Test
    public void test1() {
        MyList<String> list = new MyList<String>() {
            // 初始化块
            {
                add("test1");
                add("test2");
                for (int i = 3; i < 5; i++) {
                    add("test3");
                }
            }
        };
        Assert.assertEquals(4, list.list.size());
    }

    @Test
    public void test2() {
        MyList<String> list = new MyList<String>()
                .add("test1")
                .add("test2");
        for (int i = 3; i < 5; i++) {
            list.add("test3");
        }
        Assert.assertEquals(4, list.list.size());
    }
}
```
看`test1`方法, 是不是和上面的很熟悉, 其实就是使用了初始化块, 进行初始化。和下面`test2`方法是等价的。

而且也不会产生匿名内部类, 对于某些需要参数进行初始化, 而不得不将其设计为抽象类的类, 是一种很好的代码优化手段。