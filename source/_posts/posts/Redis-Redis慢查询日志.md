---
title: Redis慢查询日志
url: Redis_slow_log
tags:
  - Redis
categories:
  - Redis
date: 2019-02-09 12:38:55
---

# 前言
`Redis`的命令有一个生命周期, 比如发送一个`set key value`命令.
1. `Redis`客户端发送`set key value`到`Redis`服务端
1. 因为`Redis`是单线程, 所以命令在队列中排队.
1. `Redis`服务端执行`set key value`命令, 并产生结果
1. `Redis`服务端将结果发送给`Redis`客户端

而`Redis`命令的慢查询命令就是`Redis`服务端消耗时间较长的命令, 耗时过长是导致客户端超时的原因**之一**.

<!-- more -->

# 慢查询配置
慢查询其实就是一个固定长度的`FIFO`队列, 它保存在内存中.
既然是`FIFO`, 那么肯定会存在旧的慢查询丢失问题, 所以需要定期进行持久化到硬盘.

## 修改配置文件重启(不推荐)
`Redis`配置文件在`/etc/redis.conf`下, 里面有两个属性.
```
# 超过 10000 微秒的命令会被记录下来, 为0则记录所有命令, 为负数则禁用慢查询日志
slowlog-log-slower-than 10000
# 慢查询日志队列长度, slowlog reset 命令会清空队列回收内存
slowlog-max-len 128
```
实际我们不这样做, 因为`Redis`支持动态配置.

## 动态配置
`Redis`可以通过命令, 将配置写入内存中, 再调用`config rewrite`回写到配置文件中.
```bash
redis-cli
    # 慢查询日志队列长度, slowlog reset 命令会清空队列回收内存
    config set slowlog-max-len 256
    config get slowlog-max-len
    # 超过 20000 微秒的命令会被记录下来, 为0则记录所有命令, 为负数则禁用慢查询日志
    config set slowlog-log-slower-than 20000
    config get slowlog-log-slower-than
    config rewrite
```
**注意! 如果`Redis Server`启动时没有指定配置文件, 则`config rewrite`会报错!**

所以需要指定配置文件
```bash
redis-server /etc/redis.conf
```

## Docker 配置
如果是`Docker`启动的话, `Image`里是没有`redis.conf`的, 需要自己映射`volume`.
```bash
# 1. 准备外部文件
mkdir /opt/docker/redis/{conf,data} -p
cp /etc/redis.conf /opt/docker/redis/redis.conf
cd /opt/docker/redis

# 2. 映射到容器内
docker run -p 6380:6379 -v $PWD/data:/data -v $PWD/conf/redis.conf:/etc/redis/redis.conf -d redis redis-server /etc/redis/redis.conf
```

如果是`Docker-Compose`启动的话, 需要指定`volume`, 然后后台启动`docker-compose up -d`.
```yml
# https://github.com/docker-library/redis/issues/125#issuecomment-363322332
version: '3'
services:
  redis:
    image: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
      - ./conf/redis.conf:/etc/redis/redis.conf
volumes:
  redis-data:
```

# 慢查询命令
```bash
# 1. 查看慢查询里前100条命令, 注意这里是FIFO
slowlog get 100;
# 2. 记录超过0毫秒的命令, 即所有命令记录下来
config set slowlog-log-slower-than 0
# 3. 执行命令
set k1 v1
# 4. 查看慢查询里前100条命令, 注意这里是FIFO
slowlog get 100
# 1) 1) (integer) 1
#    2) (integer) 1549684719
#    3) (integer) 141
#    4) 1) "set"
#       2) "k1"
#       3) "v1;"
#    5) "172.17.0.1:56592"
#    6) ""
# 5. 清空慢查询队列
slowlog reset
```
可以看到慢查询日志由`6`个部分组成。[官方文档](https://redis.io/commands/slowlog)

| 条目 | 值 | 说明 |
|:------:|:---:|:------:|
| 1 | `(integer) 1` | 慢查询日志的`id`, 自增 |
| 2 | `(integer) 1549684719` | 开始命令的`unix`时间戳 |
| 3 | `(integer) 141` | 执行命令消耗的事件, 以微秒为单位 |
| 4 | `1) "set" 2) "k1" 3) "v1;"` | 组成命令的参数, 以数组形式存放 |
| 5 | `"172.17.0.1:56592"` | `4.0+`新增, 客户端的`ip:port` |
| 6 | `""` | `4.0+`新增, 客户端的名称 |

# 最佳实践
```
# 不要设置过大, 默认10ms, 通常设置1ms
config set slowlog-max-len 1
# 不要设置过小, 通常设置1000左右
config set slowlog-log-slower-than 1000
```
慢查询日志是一个`FIFO`队列, 如果一段时间没有处理, 则旧的慢查询日志则会从队列移除, 所以我们需要定期持久化慢查询日志到硬盘, 通过定时任务插入`MySQL`等方式.
```bash
slowlog get 100
```


# 参考资料
- [slowlog官方文档](https://redis.io/commands/slowlog)
- [Redis高级功能 - 慢查询日志](https://segmentfault.com/a/1190000009915519)
- [docker 安装部署 redis（配置文件启动）](https://segmentfault.com/a/1190000014091287)
