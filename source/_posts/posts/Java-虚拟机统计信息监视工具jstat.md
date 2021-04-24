---
title: 虚拟机统计信息监视工具jstat
url: jstat
tags:
  - JVM
categories:
  - Java
date: 2021-04-25 00:39:00
---

# 前言
`jstat`全称`JVM Statistics Monitoring Tool`虚拟机统计信息监视工具, 可以用来监视虚拟机进程中的类加载、内存、垃圾收集、即时编译等运行时数据.
命令格式: `jstat [option vmid [interval[s|ms] [count]]]`

<!-- more -->

| 参数 | 说明 |
|:------:|:------:|
| `vmid` | 如果是本地虚拟机, 那就是`jps`的进程号. 如果是远程虚拟机, 则应该是`[protocol:][//]lvmid[@hostname[:port]/servername]` |
| `interval` | 查询间隔 |
| `count` | 查询次数 |

选项`option`代表用户希望查询的虚拟机信息, 主要分为三类: 类加载、垃圾收集、运行期编译状况.
| 选项 | 作用 |
|:------:|:------:|
| `-gc` | 监视堆状况 |
| `-gcutil` | 和`-gc`基本相同, 但主要关注已使用空间占总空间的百分比 |

# 常用命令
## jstat -gc
执行`jstat -gc PID`命令, 查看`JVM`状态
| 列 | 值 | 说明 |
|:------:|:------:|:------:|
| `S0C` | `14848.0`  | `From Survivor`区的内存大小 |
| `S1C` | `14336.0` | `To Survivor`区的内存大小 |
| `S0U` | `0.0` | `From Survivor`区已使用内存大小 |
| `S1U` | `11904.5` | `To Survivor`区已使用内存大小 |
| `EC` | `147456.0` | `Eden`区的内存大小 |
| `EU` | `145865.4` | `Eden`区已使用内存大小 |
| `OC` | `168960.0` | 老年代的内存大小 |
| `OU` | `18178.0` | 老年代已使用内存大小 |
| `MC` | `44328.0` | 方法区的内存大小 |
| `MU` | `41720.7` | 方法区已使用内存大小 |
| `CCSC` | `6440.0` | 压缩类空间的内存大小 |
| `CCSU` | `5907.5` | 压缩类空间已使用内存大小 |
| `YGC` | `9` | 系统运行迄今为止的`Young GC`次数 |
| `YGCT` | `0.036` | `Young GC`耗时 |
| `FGC` | `2` | 系统运行迄今为止的`Full GC`次数 |
| `FGCT` | `0.041` | `Full GC`耗时 |
| `GCT` | `0.077` | 所有`GC`耗时 |

## 其他 jstat 命令
```bash
jstat -gccapacity PID # 堆内存分析
jstat -gcnew PID # 年轻代GC分析，这里的TT和MTT可以看到对象在年轻代存活的年龄和存活的最大年龄
jstat -gcnewcapacity PID # 年轻代内存分析
jstat -gcold PID # 老年代GC分析
jstat -gcoldcapacity PID # 老年代内存分析
jstat -gcmetacapacity PID # 元数据区内存分析
```

# 常用场景
## 新生代对象增长速率
使用命令`jstat -gc PID 1000 10`, 表示每`1000`毫秒输出一次统计信息, 共输出`10`次.
就可以根据每次的`EU`, 计算出新生代对象增长速率
## YoungGC的触发频率
既然知道了新生代对象增长速率，就可以用新生代内存大小除以速率, 得到新生代还有多久填满, 也就是多久触发一次`YoungGC`.
## YoungGC的每次耗时
直接用`YGCT`除以`YGC`就可以得到`YoungGC`的每次耗时
## 每次YoungGC后有多少对象进入老年代
其实就是看老年代的对象增长速率, 和新生代对象增长速率同样的方法.
使用命令`jstat -gc PID 1000 10`, 表示每`1000`毫秒输出一次统计信息, 共输出`10`次.
就可以根据每次的`OU`, 计算出新生代对象增长速率
## 每次YoungGC后有多少对象存活下来
看`S`区的内存大小, 加上老年代内存增长大小
## FullGC的触发频率
和`YoungGC`触发频率同样的计算方式.
既然知道了老年代对象增长速率，就可以用老年代内存大小除以速率, 得到老年代还有多久填满, 也就是多久触发一次`FullGC`.
## FullGC的每次耗时
直接用`FGCT`除以`FGC`就可以得到`FullGC`的每次耗时
