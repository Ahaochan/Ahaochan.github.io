---
title: Java异常捕捉顺序
url: The_capture_order_of_Java_Exception
tags:
  - Exception
categories:
  - Java SE
date: 2017-08-30 21:18:04
---

# 前言
一直对异常捕捉都是`e.printStackTrace()`就完事了, 突然对异常捕捉顺序很好奇, 就做了个测试, 直接看代码。

<!-- more -->

# 从小到大捕捉
```java
public class MyTest {
    @Test
    public void test(){
        try{
            throw new FileNotFoundException("文件没找到");
        } catch (FileNotFoundException e){
            // 结果输出 ` FileNotFoundException `
            System.out.println("FileNotFoundException ");
        } catch (IOException e){
            // 不执行, 已被FileNotFoundException捕捉
            System.out.println("IOException");
        } catch (Exception e){
            // 不执行, 已被FileNotFoundException捕捉
            System.out.println("Exception ");
        } catch (Throwable e){
            // 不执行, 已被FileNotFoundException捕捉
            System.out.println("Throwable ");
        }
    }
}
```


# 从大到小捕捉
```java
public class MyTest {
    @Test
    public void test(){
        try{
            throw new FileNotFoundException("文件没找到");
        } catch (Throwable e){
            System.out.println("Throwable ");
        } catch (FileNotFoundException e){
            // 编译错误, 提示异常已被 Throwable 捕捉
            System.out.println("FileNotFoundException ");
        } catch (IOException e){
            // 编译错误, 提示异常已被 Throwable 捕捉
            System.out.println("IOException");
        } catch (Exception e){
            // 编译错误, 提示异常已被 Throwable 捕捉
            System.out.println("Exception ");
        }
    }
}
```

# 结论
Java异常捕捉顺序是
1. 从上到下
2. 从小到大
