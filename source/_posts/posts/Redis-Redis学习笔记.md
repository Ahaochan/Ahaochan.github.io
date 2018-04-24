---
title: Redis学习笔记
url: Redis_simple_use
tags:
  - Redis
categories:
  - Redis
date: 2017-07-02 23:00:55
---

# 介绍
`Redis`是一种NoSQL(No Only SQL) 非关系型数据库，是高性能`键值对`数据库。
常用于缓存、分布式Session分离，或者任务队列，网站访问统计。
`Redis`建议运行于`Linux`上。Java推荐`JRedis`
<!-- more -->

# 使用
`/usr/local/redis/bin`有以下可执行文件
```shell
# 性能测试工具
redis-benchmark
# AOF文件修复工具
redis-check-aof
# RDB文件检查工具
redis-check-dump
# 命令行客户端
redis-cli
# redis服务器启动命令
redis-server
```

在`/usr/local/redis/redis.conf`中修改配置信息
```shell
# 允许后台启动
daemonize yes
```
常用命令
```shell
# 通过配置信息启动Redis, 后台启动redis
/usr/local/redis/bin/redis-server /usr/local/redis/redis.conf
# 进入redis控制台
/usr/local/redis/bin/redis-cli
# 关闭redis
/usr/local/redis/bin/redis-cli shutdown
```


# 存储
Redis有`string`、`hash`、`list`、`set`、`sorted-set`五种存储方式.

## 字符串存储
```shell
set mykey value1 // 存储键值对

get mykey // 输出value1
getset mykey value2 // 输出value1，存入value2

del mykey // 删除键为mykey的键值对，返回nil

incr mykey // 自增1，若mykey不存在，则创建key为0，并自增1
decr mykey // 自减1，若mykey不存在，则创建key为0，并自减1
incrby mykey 5 // 自增5
decrby mykey 5 // 自减5

append mykey value // 在字符串末尾追加value
```

## hash存储
Hash存储一个对象，对象中可以创建属性。类似`Map<Object, Collection<Object>>`
```shell
hset mykey field1 value1
hmset mykey field1 value1 [fieldN valueN]

hget mykey [field1]
hmget mykey field1 [fieldN]
hgetall mykey // 获取所有属性及属性值

hdel mykey field1 [fieldN]
del mykey // 删除整个key集合

hincr by mykey field1 5 // key的field1属性自增5
hexists mykey field1 // 判断mykey中的field1属性是否存在
hlen mykey // 获取mykey中属性的数量
hkeys mykey // 获取mykey中所有的属性名
kvals mykey // 获取mykey中所有的属性值
```

## list存储
按插入顺序排序的字符串链表，用于`消息队列`
```shell
lpush mylist a b c // 往mylist左侧依次插入a b c
lpushx mylist a b c // 只有mylist存在才插入
rpush mylist 1 2 3 // 往mylist右侧依次插入1 2 3
rpushx mylist 1 2 3 // 只有mylist存在才插入
lset mylist index value // 往mylist下标为index插入value
linsert mylist before b x // 往mylist的第1个b元素之前插入x
linsert mylist after b x // 往mylist的第1个b元素之后插入x
rpoplpush mylist1 mylist2 // 弹出mylist1最后一个元素插入mylist2第一个元素

lpop mylist // 弹出mylist左侧的第一个元素
rpop mylist // 弹出mylist右侧的第一个元素

lrange mylist 0 -1 // 查看链表第0个元素到倒数第1个元素
llen mylist // mylist元素个数

lrem mylist 2 value // 从左往右删除2个value
lrem mylist -2 value // 从右往左删除2个value
lrem mylist 0 value // 删除所有value
```

## set存储
无排序的字符集合，类似`Set<Object>`
```shell
sadd myset a b c // 往myset中插入a b c
srem myset a b // 删除元素a b 
smembers myset // 查看所有元素
scard myset // 元素数量
sismember myset a // set是否存在元素a
srandmember myset // 返回set中随机一个成员

sdiff myset1 myset2 // 差集运算
sdiffstore myset3 myset1 myset2 // 将myset1和myset2差集运算结果存储到myset3
sinter myset1 myset2 // 交集运算
sinterstore myset3 myset1 myset2 // 将myset1和myset2交集运算结果存储到myset3
sunion myset1 myset2 // 并集运算
sunionstore myset3 myset1 myset2 // 将myset1和myset2并集运算结果存储到myset3
```

## sorted-set存储
使用`分数`排序的set，常用于排行榜、构建索引数据
```shell
zadd myset 90 a 80 b 60 c

zscore myset a // 获取myset中a的分数
zcard myset // 元素数量

zrange myset 0 -1 // 查看myset第0个元素到倒数第1个元素
zrange myset 0 -1 withscores// 包括分数，从小到大排序
zrevrange myset 0 -1 withscores// 从大到小排序
zrangebyscore myset 0 100 withscores limit 0 2 // 查看myset分数在0-100之间第0-2个元素
zcount myset 80 90 // 分数在80-90之间的元素个数

zrem myset b c // 删除元素a b
zremrangebyrank myset 0 -1 // 删除myset第0个元素到倒数第1个元素
zremrangebyscore myset 80 100 // 删除分数在80-100之间的元素

zincrby myset 5 a // a元素自增5
```

# keys操作
这里的key，相当于关系型数据库的table
```shell
keys my* // 获取所有的my开头的key
del myset1 myset2 myset3 
exists myset
rename myset newset
expire myset 1000 // 1000秒后过期
ttl myset // 剩余超时时间
type myset // 获取myset的类型, 如string、hash、set等
```

# 数据库
一个Redis实例可以提供16个数据库(下标0-15)
```shell
select 0 // 选择0号数据库(默认)
move myset 1 // 移动myset到1号数据库
```

# 事务
```shell
multi // 开启事务
exec // 提交事务
discard // 回滚事务
```

# 持久化
分为`RDB持久化`和`AOF持久化`两种

## RDB持久化(默认)
指定时间间隔内将数据库写入磁盘
优势, 只包含一个备份文件, 性能最大化, 通过fork进程让子进程完成持久化操作, 启动效率比AOF高.
劣势, 不能最大限度避免数据丢失.
`/usr/local/redis/redis.conf`
save 900 1 900秒至少有一个key发生变化就持久化一次

dbfilename dump.rdb
dir ./
保存在当前目录的dump.rdb文件中

## AOF持久化
以日志形式记录服务器每次操作
优势, 更高的数据安全性, 每秒同步、每修改同步、不同步, 当日志文件过大, 重写日志文件.
劣势, 运行效率低
```shell
# 默认关闭AOF方式
appendonly no
# 产生日志文件名
appendfilename "appendonly.aof"
# appendsync always
appendsync everysec
# appendsync no 三种同步策略
```
