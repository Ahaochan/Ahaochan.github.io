---
title: Redis持久化RDB和AOF
url: Redis_RDB_and_AOF
tags:
  - Redis
categories:
  - Redis
date: 2019-02-19 22:47:55
---

# 前言
`Redis`的高速建立在数据存储在内存中, 但是断电的话, 就会导致数据丢失的问题.
为此我们需要对数据进行持久化到硬盘中.
`Redis`提供了两种持久化存储方案, `Redis`在启动时会优先加载`AOF`文件恢复数据.
1. `AOF(Append Only File)`: 记录每次执行的命令到日志中, 恢复数据时重新执行一次日志文件中的命令.
2. `RDB(Redis Database Backup)`: 将数据库的所有数据直接写入磁盘

<!-- more -->

# RDB ( Redis Database Backup )
`RDB`会将当前`Redis`中所有存储的数据持久化到`dump.rdb`文件中.

## save 持久化 ( 阻塞 )
`Redis`是单线程的, 所以`save`命令一旦执行, 其时间复杂度是`O(n)`, 数据量一大, `Redis`就会阻塞后面的请求.
所以一般不直接使用`save`命令进行持久化.

## bgsave 持久化 ( fork子进程 )
`Redis`提供了`bgsave`命令, `fork`一个子进程来进行`save`. 这样就不会阻塞住原本的进程.
`fork`后的子进程执行`save`命令, 会创建一个临时`RDB`文件, 待持久化完毕后, 覆盖之前的`RDB`文件.
但是`fork`这个操作, 仍然是阻塞的, 

## save seconds changes ( 定时持久化 )
`Redis`的配置文件中, 还提供了另一种`RDB`持久化方式, 格式: `save <seconds> <changes>`
```bash
# save "" # 关闭 RDB
save 900 1
save 300 10
save 60 10000
```
表示`seconds`秒内改变了`changes`次数据, 则自动`bgsave`.
缺点也很明显, 无法控制生成RDB的频率

## 最佳配置 ( 开启 RDB 时 )
```bash
# 1. 注释掉所有的 save 命令
# save 900 1
# save 300 10
# save 60 10000

# 2. 指定 RDB 文件名
dbfilename dump-6379.rdb
# 3. 指定存储文件夹, 放RDB文件、AOF文件、log文件
dir /data
# 4. 指定 bgsave 发生错误时停止写入
stop-writes-on-bgsave-error yes 
# 5. 压缩 RDB 文件
rdbcompression yes
# 6. 校验 RDB 文件
rdbchecksum yes
```
值得注意的是, 即使在配置文件中关闭`RDB`自动持久化, 在以下情况, 仍会产生`RDB`文件.
1. 主从复制之全量复制时, 会生成RDB文件
2. `debug reload`重启Redis, 会生成RDB文件
3. `shutdown save`保存退出时, 会生成RDB文件

# AOF(Append Only File)
`AOF`会将执行的命令**优化(重写)**后, 保存到内存中, 然后再从内存`fsync`到硬盘中.
待恢复时, 重新执行这些命令.

```bash
# 1. 打开 AOF 持久化
appendonly no

# 2. 三种 fsync 方式
# appendfsync always # 每次执行命令都会 fsync
appendfsync everysec # 每秒执行 fsync
# appendfsync no     # 取决于操作系统执行 fsync (不可控)
```

## 手动重写
假设要执行以下命令
```bash
set a a
set a b
set a c
```
那么`AOF`肯定不会傻傻的将这`3`条命令写到`AOF`文件中, 因为只要保证`set a c`即可.
忽略中间态, 这就是`AOF`重写.
可以极大的减少`AOF`文件大小, 加快`AOF`恢复速度.

要手动重写, 只需要执行`bgrewriteaof`命令即可.
它会`fork`一个子进程来执行`AOF`重写操作.

## 自动重写
`Redis`也在配置文件`/etc/redis.conf`中提供了满足一定条件就自动重写的配置.
```bash
# 1. 当 AOF 文件大于某个值时进行重写
auto-aof-rewrite-min-size 64mb
# 2. AOF 文件增长率, 下次就是到达 128mb、 256mb 就会重写.
auto-aof-rewrite-percentage 100 
```

我们可以在`redis-cli`客户端查看`info`信息.
```bash
info persistence
# AOF开启, 才会追加以下信息
# aof_current_size  AOF 文件当前大小
# aof_base_size     上次AOF文件重写时的大小
```

当满足以下条件时, `AOF`文件会自动重写.
```text
aof_current_size > auto_aof_rewrite_min_size
aof_current_size - aof_base_size / aof_base_size > auto_aof_rewrite_percentage
```

## 最佳配置 ( 开启 AOF 时 )
```bash
# 1. 开启 AOF
appendonly yes
# 2. 指定 AOF 文件名
appendfilename appendonly-6379.aof
# 3. 指定存储文件夹, 放RDB文件、AOF文件、log文件
dir /data
# 4. AOF 每秒保存一次, 宕机最多丢失一秒数据
appendfsync everysec
# 5. AOF 重写时是否正常执行 AOF
no-appendfsync-on-rewrite yes
# 6. 当 AOF 文件大于 64mb 时进行重写
auto-aof-rewrite-min-size 64mb
# 7. AOF 文件增长率, 下次就是到达 128mb、 256mb 就会重写
auto-aof-rewrite-percentage 100
```

# 参考资料
- [slowlog官方文档](https://redis.io/commands/slowlog)
- [Redis高级功能 - 慢查询日志](https://segmentfault.com/a/1190000009915519)
- [docker 安装部署 redis（配置文件启动）](https://segmentfault.com/a/1190000014091287)
- [Redis 持久化 官方文档](http://redis.cn/topics/persistence.html)