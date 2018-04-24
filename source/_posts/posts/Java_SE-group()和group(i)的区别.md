---
title: group()和group(i)的区别
url: The_difference_between_group()_and_group(i)
tags:
  - 正则表达式
categories:
  - Java SE
date: 2016-08-23 21:00:22
---
# 前言
最近在做网络爬虫，需要用到正则表达式，所以学习一下。

# 先看代码
<!-- more -->
```java
public class Main{  
    public static void main(String[] args){  
            String Line = "abcdefg";  
            String regular = "(b)([\\s\\S]+?)(f)";  
            System.out.println(getRegular(Line, regular).get(0));  
    }  
      
    private static List<String> getRegular(String line, String regular) {  
            List<String> code = new ArrayList<String>();  

            Pattern pattern = Pattern.compile(regular);  
            Matcher matcher = pattern.matcher(line);  
            while(matcher.find()){  
                    code.add(matcher.group(1));//看这里的group的参数  
            }  
            return code;  
    }  
}  
```
我们的目的是获取字符串`Line`中的`cde`部分，也就是`ab`和`fg`之间的子字符串。
这里不详解`ab([\\s\\S]+?)fg`的含义，只要知道是满足上述要求的正则表达式即可。
在官方文档`jdk`中对`group()`的定义如下

|                           |                                                  |
|:--------------------------|:-------------------------------------------------|
| String  group();          | 返回由以前匹配操作所匹配的输入子序列。           |
| String  group(int group); | 返回在以前匹配操作期间由给定组捕获的输入子序列。 |
| int groupCount();         | 返回此匹配器模式中的捕获组数。                   |   

这里的捕获组数，简单来说就是，正则表达式中**有多少个括号**，通过`groupCount()`获取捕获组数

| 函数     | 获取数据组 | `(b)([\\s\\S]+?)(f)`对`abcdefg`正则结果 |
|:---------|:-----------|:----------------------------------------|
| group()  | 所有组     | `bcdef`                                 |
| group(0) | 所有组     |  `bcdef`                                |
| group(1) | 第1组      |  `b`                                    |
| group(2) | 第2组      |  `cde`                                  |
| group(3) | 第3组      |  `f`                                    |

那么问题来了，如果`String regular = "b([\\s\\S]+?)f";`
把`b`和`f`的括号去掉，结果使用`groupCount()`获取的组数为`1`，而不是之前的`3`。
也就是说，`group(1)`获取的是`cde`，而不是之前的`b`。

值得注意的是`group()`会出现越界问题，要注意。

