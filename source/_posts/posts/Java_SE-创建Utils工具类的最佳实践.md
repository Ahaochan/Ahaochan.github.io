---
title: 创建Utils工具类的最佳实践
url: The_Best_practice_for_create_Utils_class
tags:
  - 最佳实践
categories:
  - Java SE
date: 2017-09-24 13:03:37
---
# 前言
有些类我们不希望实例化, 比如 ` ArrayUtils `。
实例化这些工具类是没有意义的。
<!-- more -->

# 最佳实践
1. 使用 ` final ` 、 ` abstract ` 修饰 ` class `。
2. 私有化构造函数
3. 构造函数抛出异常
```java
// abstract类不能直接实例化, 只能由子类实例化
// final类不能实例化
public abstract class ArrayUtils {
    // 私有化构造函数, 子类必须调用父类的构造函数, 但是又调用不了
    private ArrayUtils() {
        // 防止反射创建, 抛出异常
        throw new AssertionError("工具类不允许实例化");
    }
    // 工具方法
    public static void sort(Integer... arr){}
}
```
