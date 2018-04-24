---
title: 解析String为数字用valueOf还是parseXxx?
url: valueOf_method_and_parseXxx_method
tags:
  - 最佳实践
categories:
  - Java SE
date: 2017-08-27 17:23:09
---

# 前言
findBuds真是一个好插件, 找到了许多平时都不知道的高危bug。
在我解析字符串时
```java
@Override
public long getLong(String key) {
    return Long.valueOf(key == null ? "0" : key.toString());
}
```
<!-- more -->

给我爆了这个警告
```
Boxing/unboxing to parse a primitive
A boxed primitive is created from a String, just to extract the unboxed primitive value. It is more efficient to just call the static parseXXX method.
```

意思是`一个包装类由字符串创建, 只是为了获取基本数据类型的值, 调用parseXxx更有效`。

# 两个方法的返回值不同
jdk7提供的自动拆装箱语法糖是很不错的。
但是过份依赖语法糖就会出现一些 ` 常识性 ` 问题。
两个方法如下
```
public static long parseLong(String s);
public static Long valueOf(String s);
```
先说结论
- 要获取基本数据类型就使用 ` parseXxx ` 
- 要获取包装数据类型就使用 ` valueOf `

看返回类型就知道了, 滥用会导致一些性能问题, 毕竟拆装箱多了一步操作。

# 源码分析
我们先看 ` valueOf ` 的源码
```java
// java.lang.Long
public final class Long extends Number implements Comparable<Long> {
    public static Long valueOf(String s) throws NumberFormatException {
        // 调用 parseLong 方法解析字符串
        return Long.valueOf(parseLong(s, 10));
    }
    
    public static Long valueOf(long l) {
        final int offset = 128;
        if (l >= -128 && l <= 127) { // 从缓存中获取
            return LongCache.cache[(int)l + offset];
        }
        return new Long(l);
    }
}
```
很明显 ` valueOf ` 是调用了 ` parseLong ` 方法的。
所以这个解析字符串的实现是交由 ` parseLong ` 完成的。
然后再从 ` 缓存 ` 中获取, 缓存中没有这个值的话, 再去 ` new ` 一个。

再看 ` parseLong ` 方法。
在此之前, 先复习下进制转换的算法。
![abc_16=10*16^2+11*16^1+12*16^0=2748](http://latex.codecogs.com/svg.latex?abc_{16}=10*16^2+11*16^1+12*16^0=2748)
下面的算法公式为
![abc_16=-(((-10*16)-11)*16-12)=2748](http://latex.codecogs.com/svg.latex?abc_{16}=-%28%28%28-10*16%29-11%29*16-12%29=2748)
这项算法是[秦九韶公式](https://zh.wikipedia.org/zh-hans/%E7%A7%A6%E4%B9%9D%E9%9F%B6%E7%AE%97%E6%B3%95)
简单的说, 就是降低了多项式的计算复杂度(叹服古人的智慧, 居然应用到计算机领域)

为了避免溢出, 是基于 ` 负数 ` 进行运算的。
```java
// java.lang.Long
public final class Long extends Number implements Comparable<Long> {
    public static long parseLong(String s, int radix) throws NumberFormatException {
        // 省略抛出异常的代码

        long result = 0; // 结果值
        boolean negative = false; // 是否为负数
        int i = 0, len = s.length(); // i 为字符串下标, len为字符串长度
        long limit = -Long.MAX_VALUE; // 
        long multmin; // 
        int digit; // 进制

        // 获取第一个字符
        char firstChar = s.charAt(0);
        if (firstChar < '0') { // 非数字和字母
            if (firstChar == '-') { // 判断是否为负号
                negative = true; // 标记为负数
                limit = Long.MIN_VALUE;
            } else if (firstChar != '+'){
                // 不是数字, 不是字母, 不是负号, 不是正号, 那肯定不是数字
                throw NumberFormatException.forInputString(s);
            }

            if (len == 1) {
                // 字符串长度为1, 则只有一个符号, 不能解析
                throw NumberFormatException.forInputString(s);
            }
            i++; // 下标移到下一个字符
        }
        
        multmin = limit / radix; // 设定不同进制下的极限值
        while (i < len) {
            // Accumulating negatively avoids surprises near MAX_VALUE
            // 负数运算避免大于MAX_VALUE发生溢出
            digit = Character.digit(s.charAt(i++),radix); // 获取radix进制下的值, 5=>5, A=>10
            
            // 秦九韶公式的核心算法
            result *= radix;
            result -= digit;
        }
        
        // 最后把负数转为正数(或者负数转为正数)
        return negative ? result : -result;
    }
}
```
