---
title: 自动转型带来的NoSuchMethodError
url: NoSuchMethodError_caused_by_Automatic_Type_Conversion
tags:
  - 最佳实践
categories:
  - Java SE
date: 2018-12-04 17:03:16
---
# 前言
更新了`core`包里的通用方法, 结果本地代码没问题, 线上代码`500`, 看了下`localhost.log`, 发现报`NoSuchMethodError`. 特此记录下。

<!-- more -->

# 重现步骤
```java
// Main.java
public class Main {
    public static void main(String[] args) throws Exception {
        int page = 1;
        int pageSize = 10;
        Utils.test(page,pageSize);
    }
}
// Utils.java
public class Utils {
    public static void test(int page, int pageSize){
        System.out.println("page:"+page+", pageSize:"+pageSize);
    }
}
```
编译`javac Main.java Utils.java`
运行`java Main`后输出`page:1, pageSize:10`
修改`Utils`代码, 将`int`改为`long`, `Main`不用改动
```java
// Utils.java
public class Utils {
    public static void test(long page, int pageSize){
        System.out.println("第"+page+"页, 分页大小为"+pageSize);
    }
}
```
只编译`Utils`, 执行`javac Utils.java`
然后运行`java Main`, 抛出`NoSuchMethodError`.
```text
Exception in thread "main" java.lang.NoSuchMethodError: Utils.test(II)V
        at Main.main(Main.java:5)
```
重新同时编译两个文件`javac Main.java Utils.java`
运行`java Main`后又成功输出`page:1, pageSize:10`

# 分析
先把修改前的`class`文件反编译, 得到如下代码
```java
// Main.class
public class Main {
    public Main() {
    }
    public static void main(String[] var0) throws Exception {
        int var1 = 1;
        int var2 = 10;
        Utils.test(var1, var2);
    }
}
// Utils.class
public class Utils {
    public Utils() {
    }
    public static void test(int var0, int var1) {
        System.out.println("page:" + var0 + ", pageSize:" + var1);
    }
}
```
将`Utils`的`int`转为`long`之后进行反编译得到如下代码
```java
// Main.class
public class Main {
    public Main() {
    }
    public static void main(String[] var0) throws Exception {
        int var1 = 1;
        int var2 = 10;
        Utils.test(var1, var2);
    }
}
// Utils.class
public class Utils {
    public Utils() {
    }

    public static void test(long var0, int var2) {
        System.out.println("page:" + var0 + ", pageSize:" + var2);
    }
}  
```
同时编译`Main.java`和`Utils.java`之后进行反编译得到如下代码
```java
// Main.class
public class Main {
    public Main() {
    }

    public static void main(String[] var0) throws Exception {
        int var1 = 1;
        int var2 = 10;
        Utils.test((long)var1, var2);
    }
}
// Utils.class
public class Utils {
    public Utils() {
    }
    public static void test(long var0, int var2) {
        System.out.println("page:" + var0 + ", pageSize:" + var2);
    }
}
```

对比可以看到, 正常执行的代码, `page`参数的类型是对应的, 自动转型其实是在编译的时候对其进行了强制转换. 
当我们修改了方法参数类型后, 只编译部署`Utils.class`后, `Main`就找不到符合`test(int, int)`的方法, 因为`Utils.class`只有`test(long, int)`方法。
而当我们两个类都进行编译时, `Main`检测到`Utills.class`没有`test(int, int)`, 就会自动在调用的方法里加上强制类型转换`(long) var1`.

# 发生的情景
一般发生在增量更新的项目里面, 本地编译了`class`文件, 只替换服务器上对应的文件, 如果是全量更新的项目, 则不会出现这个问题。

# 如何避免
有两种方法
1. 全量更新
2. 保留旧的代码, 添加`@Deprecated`注解
```java
// Utils.java
public class Utils {
    @Deprecated
    public static void test(int page, int pageSize){
        System.out.println("page:"+page+", pageSize:"+pageSize);
    }
    public static void test(long page, int pageSize){
        System.out.println("page:"+page+", pageSize:"+pageSize);
    }
}
```