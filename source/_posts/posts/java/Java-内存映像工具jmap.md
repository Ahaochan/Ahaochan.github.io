---
title: 内存映像工具jmap
url: jmap
tags:
  - JVM
categories:
  - Java
date: 2021-04-25 22:27:00
---

# 前言
`jmap`全称`Memory Map For Java`虚拟机统计信息监视工具, 可以生成堆内存的快照, 在事后进行分析.
当然我们还可以给`JVM`加上`-XX:+HeapDumpOnOutOfMemoryError`, 在内存溢出的时候自动生成堆内存的快照.
命令格式: `jmap [option] vmid`

<!-- more -->

| 参数 | 说明 |
|:------:|:------:|
| `vmid` | 如果是本地虚拟机, 那就是`jps`的进程号. 如果是远程虚拟机, 则应该是`[protocol:][//]lvmid[@hostname[:port]/servername]` |

选项`option`代表要查询的数据

| 选项 | 作用 |
|:------:|:------:|
| `-dump` | 生成堆内存快照. 格式为`-dump:[live,]format=b,file=/tmp/heap.dump`, 其中`live`说明是否只`dump`存活的对象 |
| `-finalizerinfo` | 显示在`F-Queue`中等待`Finalizer`线程执行`finalize`方法的对象. |
| `-heap` | 显示堆详细信息 |
| `-histo` | 显示堆中对象统计信息 |
| `-permstat` | 以`ClassLoader`为统计口径显示永久代内存状态 |
| `-F` | `-dump`没响应的时候, 强制生成`dump`快照 |

# 常用命令
## jmap -heap PID
用来查看堆内存, `jstat`已有相同的功能了, 并且更全面.
`jstat`除了堆内存信息, 还有`GC`的相关信息.
## jmap -histo PID
所以一般`jmap`都是用来查看堆内对象的具体内存信息的. 这是`jstat`做不到的事情.
```text
 num     #instances         #bytes  class name
----------------------------------------------
   1:        190803       63620528  [B
   2:         33239       40343096  [I
   3:        349476       39534528  [C
   4:        186246        4469904  java.lang.String
   5:         14783        4389000  [Ljava.util.HashMap$Node;
   6:         54116        2809872  [Ljava.lang.Object;
   7:         29125        2563000  java.lang.reflect.Method
...
Total       1671051      186914432
```
从输出信息可以看出
`byte[]`类型有`190803`个实例, 占用`63620528`个字节.
`int[]`类型有`33239`个实例, 占用`40343096`个字节.
`char[]`类型有`349476`个实例, 占用`39534528`个字节.
以此类推

## jmap -dump:live,format=b,file=dump.hprof PID
当然生产环境不会给你慢慢的分析, 一般都是输出到文件, 把文件传到本地慢慢分析.
可以用`jhat dump.hprof -port 7000`分析, 但一般使用的是`MAT`做分析.
