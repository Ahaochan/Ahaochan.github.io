---
title: 分布式系统中的CAP理论
url: cap_theorem
tags:
  - 分布式
categories:
  - 编程杂谈
date: 2020-04-07 17:42:00
---

# 前言
- 2020-02-06: 初版
- 2020-04-07: 阅读[从0开始学架构-想成为架构师，你必须知道CAP理论](http://gk.link/a/10hoK)后觉得还有不足之处, 于是再次修改.

一个分布式系统, 我们要关注的是它的可用性、一致性、分区容错性
1. **C**onsistency 一致性
2. **A**vailability 可用性
3. **P**artition tolerance 分区容错性

<!-- more -->

# 什么样的系统适合CAP理论
在了解什么是`CAP`之前, 我们先来看看什么样的系统适合CAP理论.

从**参考资料**里的所有英文文章得知
1. [`Silverback`](https://www.teamsilverback.com/understanding-the-cap-theorem/)提到`A distributed system (generally running in a datacenter)`.
2. [`Wikipedia`](https://en.wikipedia.org/wiki/CAP_theorem#cite_note-Brewer2012-6)提到`A distributed data store`.
3. [`IBM`](https://cloud.ibm.com/docs/services/Cloudant/guides?topic=cloudant-cap-theorem&locale=en#cap-)只提到了`a distributed computer system`.
4. [`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)一开始提到[`any distributed system`](https://robertgreiner.com/cap-theorem-explained/), 两个月后重新定义为[`In a distributed system (a collection of interconnected nodes that share data.)`](https://robertgreiner.com/cap-theorem-revisited/)

大家都认为, 分布式系统才适合`CAP`理论, 但是, 不是所有分布式系统都适合.
[`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)强调了这个分布式系统是`interconnected`互联和`share data`共享数据的.

举一个反例, 比如`Memcache`集群.
![Memcache集群](https://yuml.me/diagram/nofunky/class/[客户端]-1到100>[Memcache Server 1],[客户端]-101到200>[Memcache Server 2])
`Memcache`的各个节点之间是不互联和共享数据的, 客户端根据路由规则, 自行决定存储数据到哪个节点上.
这确实是一个分布式系统, 但是却不适用于`CAP`理论.

举一个正例, 比如`MySQL`集群.
`MySQL`我们熟, 主从复制, 就是`interconnected`和`share data`.

> In a distributed system (a collection of interconnected nodes that share data.)

所以这里还是以[`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)的文章为准, 一个互联且共享数据的节点集合, 才是适用`CAP`的分布式系统. 

# 什么是CAP
我们假设一个分布式系统有`4`个终端, 数据库`DB1`和`DB2`以及应用端`App1`和`App2`.
![分布式系统](https://yuml.me/diagram/nofunky/class/[DB1]->[App1],[DB2]->[App1],[DB1]->[App2],[DB2]->[App2])
假设有数据`a=1`

## C 一致性
从**参考资料**里的所有英文文章得知
1. [`Silverback`](https://www.teamsilverback.com/understanding-the-cap-theorem/)提到`all nodes have access to the same data simultaneously`.
2. [`Wikipedia`](https://en.wikipedia.org/wiki/CAP_theorem#cite_note-Brewer2012-6)提到`Every read receives the most recent write or an error`.
3. [`IBM`](https://cloud.ibm.com/docs/services/Cloudant/guides?topic=cloudant-cap-theorem&locale=en#cap-)提到`where all nodes see the same data at the same time`.
4. [`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)一开始提到[`All nodes see the same data at the same time.`](https://robertgreiner.com/cap-theorem-explained/), 两个月后重新定义为[`A read is guaranteed to return the most recent write for a given client.`](https://robertgreiner.com/cap-theorem-revisited/)

在客户端看来, 每次读都要能读到最新写入的数据.
举个例子, 如果`App1`往`DB1`写入数据`a=2`, 然后从`APP2`读`DB2`得到数据`a=2`, 对于客户端来说, `DB1`和`DB2`的数据保持一致.

但是实际情况下, 对于这个**最新写入**的理解, 是不同的.
同一时刻, 不同节点可能拥有不同的最新数据.
我举个例子, 在事务执行过程中, 不同的节点的数据并不完全一致.

|     | `App1`                   | `App2`                   |
|:---:|:------------------------:|:------------------------:|
|     | `start transaction`      |                          |
|     | `update t set a = 2`     |                          |
|  t1 |                          | `select a from t`(a=1)   |
|  t2 | `select a from t`(a=2)   |                          |
|     | `commit`                 |                          |
|  t3 |                          | `select a from t`(a=2)   |

`t1`和`t2`时刻, `App1`能读到最新写入的`a=2`的数据. `App2`能读到最新写入的`a=1`的数据.
此时, `App1`的事务还没有提交, 对于`App2`来说, `App1`的写入的数据是感知不到的, `App2`的最新数据还是`a=1`.
等到`t3`时刻, `App1`提交事务后, `App2`才能读到最新的`a=2`.

如果`App1`的事务回滚了, 那么`App2`是不知道`a=2`这个事件发生过的.

## A 可用性
从**参考资料**里的所有英文文章得知
1. [`Silverback`](https://www.teamsilverback.com/understanding-the-cap-theorem/)提到`a promise that every request receives a response, at minimum whether the request succeeded or failed`.
2. [`Wikipedia`](https://en.wikipedia.org/wiki/CAP_theorem#cite_note-Brewer2012-6)提到`Every request receives a (non-error) response, without the guarantee that it contains the most recent write`.
3. [`IBM`](https://cloud.ibm.com/docs/services/Cloudant/guides?topic=cloudant-cap-theorem&locale=en#cap-)提到`which guarantees that every request receives a response about whether it succeeded or failed.`.
4. [`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)一开始提到[`Every request gets a response on success/failure.`](https://robertgreiner.com/cap-theorem-explained/), 两个月后重新定义为[`A non-failing node will return a reasonable response within a reasonable amount of time (no error or timeout).`](https://robertgreiner.com/cap-theorem-revisited/)

`Silverback`、`IBM`和`Robert Greiner`都认为只要每个请求能收到响应, 无论是成功还是失败, 就算满足可用性.
`Robert Greiner`的第二篇文章和`Wikipedia`则认为请求要返回合理的成功的响应, 无论数据对错. 也就是说, 可用性的定义更严格一点.

我个人赞同第二种观点, 成功和失败的定义太广泛. 请求超时、错误也算失败的响应, 但这算可用吗? 我认为是不可用的.
比如`App1`读取`DB1`的数据
1. 得到正确的数据`a=1`, `DB1`是可用的.
2. 得到错误的数据`a=111`, `DB1`是可用的.
3. 得到`connection timeout`, `DB1`是不可用的.

## P 分区容错性
从**参考资料**里的所有英文文章得知
1. [`Silverback`](https://www.teamsilverback.com/understanding-the-cap-theorem/)提到`the system will continue to work even if some arbitrary node goes offline or can’t communicate`.
2. [`Wikipedia`](https://en.wikipedia.org/wiki/CAP_theorem#cite_note-Brewer2012-6)提到`The system continues to operate despite an arbitrary number of messages being dropped (or delayed) by the network between nodes`.
3. [`IBM`](https://cloud.ibm.com/docs/services/Cloudant/guides?topic=cloudant-cap-theorem&locale=en#cap-)提到`where the system continues to operate even if any one part of the system is lost or fails.`.
4. [`Robert Greiner`](https://robertgreiner.com/cap-theorem-revisited/)一开始提到[`System continues to work despite message loss or partial failure.`](https://robertgreiner.com/cap-theorem-explained/), 两个月后重新定义为[`The system will continue to function when network partitions occur.`](https://robertgreiner.com/cap-theorem-revisited/)

分区容错性就是当网络发生分区的时候, 集群能够继续完成工作, 返回合理的成功的响应.
网络分区是一种现象, 举个例子, 就是`DB1`和`DB2`之间的通信断了, 主从复制失败.

## 总结
`C`: 对客户端来说, 读操作保证能够返回最新的写操作结果. 这就是一致性.
`A`: 对客户端来说, 非故障的节点在合理的时间内返回合理的响应, 不是错误和超时的响应. 这就是可用性
`P`: 对集群来说, 当出现网络分区后, 系统能够继续返回合理的响应. 这就是分区容错性

# 那么`CAP`能同时做到吗?
正常情况下是可以的, 我们说的只能三选二的情况一般都是网络故障的时候, 才会进行取舍.
还是以这张图为例
![分布式系统](https://yuml.me/diagram/nofunky/class/[DB1]->[App1],[DB2]->[App1],[DB1]->[App2],[DB2]->[App2])
因为网络的不可靠性, **`P`**分区容错性是一定要保证的.
那么当`DB1`和`DB2`之间的网络发生故障, 此时就要对**`AC`**进行取舍.
1. 保障**`A`**, `App`能正常读写`DB1`和`DB2`, 但是一旦进行了写入操作, `DB1`和`DB2`是不能进行通信做主从复制的, 换句话说, 就会导致数据不一致的情况.
2. 保障**`C`**, 那么为了保证数据一致性, `App`就应该等待`DB1`和`DB2`之间的网络恢复, 这样就不能访问数据库了, 舍弃了可用性.

那有人问, 能不能只保证**`AC`**?
可以啊, 我们把两个数据库都放在一台服务器上, 这样就不会因为网络分区导致**`AC`**二选一的问题了, 因为根本没有网络.
但是这还能叫做分布式吗?

# 参考资料
- [An Illustrated Proof of the CAP Theorem](https://mwhittaker.github.io/blog/an_illustrated_proof_of_the_cap_theorem/)
- [IBM CAP 定理](https://console.bluemix.net/docs/services/Cloudant/guides/cap_theorem.html#cap-)
- [Wiki CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem#cite_note-Brewer2012-6)
- [Understanding the CAP Theorem](https://www.teamsilverback.com/understanding-the-cap-theorem/)
- [cap-theorem-availability-and-partition-tolerance](https://stackoverflow.com/a/12347673)
- [cap-theorem-revisited](https://robertgreiner.com/cap-theorem-revisited/)
- [cap-theorem-explained][https://robertgreiner.com/cap-theorem-explained/]