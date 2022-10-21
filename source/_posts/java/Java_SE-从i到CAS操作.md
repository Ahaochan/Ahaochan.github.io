---
title: 从i++到CAS操作
url: From_i++_to_CAS_operation
tags:
  - Java SE
categories:
  - Java SE
date: 2019-04-17 09:49:00
---

# 前言
`i++`不是一个原子操作, 原子操作的意思是, 执行代码的时候, 不会发生线程的切换.
即使`i++`只有一行代码, 但是也不是一个原子操作, 主要就是三件事情, 很惭愧, 就做了一点微小的工作(
1. 取值: 从内存中取值到寄存器.
2. 自增: 寄存器进行`i+1`.
3. 回写: 将自增后的值回写到内存中.

<!-- more -->

# 多线程下的问题
`i++`不是一个原子操作, 那么就可能在多线程下出现问题. 
比如发生以下操作.
1. `Thread 1`从内存中取值`i = 0`, 在寄存器中自增`i = 1`.
1. `Thread 1`在回写到内存前, 时间片结束, 切换到`Thread 2`.
1. `Thread 2`从内存中取值`i = 0`, 在寄存器中自增`i = 1`.
1. `Thread 2`在回写到内存前, 时间片结束, 切换到`Thread 1`.
1. `Thread 1`将寄存器中的`i = 1`回写到内存中, 内存中`i = 1`, 执行结束, 切换到`Thread 2`.
1. `Thread 1`将寄存器中的`i = 1`回写到内存中, 内存中`i = 1`, 执行结束.

最终结果, `i = 1`, 但是我们期望的是两个线程执行了`i++`, 最终结果应该是`i = 2`.
这时就轮到`java.util.concurrent`包出场了, 下面是一个简单的例子.
```java
public class Main {
    private static int i = 0; // 加上 volatile 也没用
    private static AtomicInteger j = new AtomicInteger(0);
    public static void main(String[] args) throws Exception {
        ExecutorService threadPool = Executors.newFixedThreadPool(128);
        for(int i = 0; i < 1_000_000; i++) {
            threadPool.execute(() -> Main.i++);
            threadPool.execute(() -> Main.j.incrementAndGet());
        }
        threadPool.shutdown();
        threadPool.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS);
        System.out.println(Main.i); // 999063
        System.out.println(Main.j); // 1000000
    }
}
```
可以看到`AtomicInteger`类可以在多线程下, 输出我们预期的结果, 而普通的`i++`, 则与预期结果不符.

# Unsafe 类的存在
主要的代码就是`incrementAndGet`这个方法. 我们可以进去看看.
```java
public class AtomicInteger extends Number implements java.io.Serializable {
    private static final Unsafe unsafe = Unsafe.getUnsafe();
    public final int incrementAndGet() {
        return unsafe.getAndAddInt(this, valueOffset, 1) + 1;
    }
}
public final class Unsafe {
    public static Unsafe getUnsafe() {
        Class<?> caller = Reflection.getCallerClass();
        if (!VM.isSystemDomainLoader(caller.getClassLoader()))
            throw new SecurityException("Unsafe"); // 判断调用 Unsafe 的类是否是 BootstrapClassLoader 加载的类
        return theUnsafe;
    }
}
```
[源码`#L87-L92`](https://github.com/bpupadhyaya/openjdk-8/blob/master/jdk/src/share/classes/sun/misc/Unsafe.java#L87-L92)
可以看到, 里面借助了`sun.misc.Unsafe`这个类, 它是一个不安全的类, 可以绕过`JVM`直接操作本地内存.
所以为了不让人滥用, 调用`getUnsafe()`时会判断调用`Unsafe`的类是否是`BootstrapClassLoader`加载的类.
我们自己写的类是由`sun.misc.Launcher$AppClassLoader`加载的, 所以如果我们自己去调用`getUnsafe()`, 肯定会抛出`SecurityException`.
当然我们也可以通过反射获取.
```java
public class UnsafeHelper {
    public static Unsafe getUnsafe() {
        Field unsafeField = Unsafe.class.getDeclaredFields()[0];
        unsafeField.setAccessible(true);
        return (Unsafe) unsafeField.get(null);
    }
}
```

# 深入 getAndAddInt
[源码`#L1028-L1034`](https://github.com/bpupadhyaya/openjdk-8/blob/master/jdk/src/share/classes/sun/misc/Unsafe.java#L1028-L1034)
```java
public final class Unsafe {
    // unsafe.getAndAddInt(this, valueOffset, 1) + 1;
    public final int getAndAddInt(Object o, long offset, int delta) {
        int v;
        do {
            v = getIntVolatile(o, offset);
        } while (!compareAndSwapInt(o, offset, v, v + delta));
        return v;
    }
    public native int getIntVolatile(Object o, long offset);
    public final native boolean compareAndSwapInt(Object o, long offset, int expected, int x);
}
```
整个核心就是`compareAndSwapInt`这个`CAS`操作. 整个方法的逻辑就是
1. 读取`Object`的`value`属性在内存中的偏移量地址`offset`, 写入变量`v`.
2. `compareAndSwapInt`方法, 判断`Object`的地址`offset`的值, 是否为`v`, 是则将`v + delta`写入地址`offset`.
3. 如果地址`offset`的值和变量`v`不相等, 说明有其他线程修改了, 那么就再循环一次, 回到步骤`1`.

# 总结
再深入就是`c++`和汇编层次的代码了, 技术有限就不细说了~~(太菜)~~, 建议查看参考资料.
总的来说, `CAS`就是一个比较操作, 直接操作内存地址, 就不会发生寄存器的值来不及回写到内存中的问题.

# 参考资料
- [Java原子类中CAS的底层实现](http://www.cnblogs.com/noKing/p/9094983.html)
