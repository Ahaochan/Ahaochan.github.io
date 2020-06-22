---
title: 精通RabbitMQ的单节点和集群安装
url: RabbitMQ_single_and_cluster_installation
tags:
  - RabbitMQ
categories:
  - 消息队列
date: 2019-09-02 22:28:00
---

# 使用 Docker 单节点安装
官方提供了一个`Docker`镜像, 直接执行下面命令即可.
```bash
mkdir -p /opt/rabbitmq/config && touch /opt/rabbitmq/config/rabbitmq.config
docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 \
    -v /opt/rabbitmq/config/rabbitmq.config:/etc/rabbitmq/rabbitmq.config \
    --hostname my-rabbit \
    rabbitmq:3-management
```
`rabbitmq:3-management`参数是启用控制台的意思.
然后访问`http://虚拟机IP:15672`.

<!-- more -->

# 集群安装

## HAProxy 实现主备集群(Warren模式)
当主节点宕机的时候, `HAProxy`能够将备节点升级为主节点, 继续提供服务.
本质上还是`HAProxy`下的一个节点在提供服务, 所以一般在并发和数据量不高的情况下使用.
![Warren模式](https://yuml.me/diagram/nofunky;dir:UD/class/[HAProxy]->[RabbitMQ master],[HAProxy]->[RabbitMQ backup])

`HAProxy`是免费开源的高可用解决方案, 可以将请求分散到多个服务器上, 为基于`TCP`和`HTTP`的应用程序提供负载均衡和代理功能.
我们先创建一个简单的`HAProxy`配置文件`haproxy.cfg`
```bash
listen rabbitmq_cluster
    # 监听端口
    bind 0.0.0.0:5672
    # 配置TCP模式
    mode tcp
    # 轮询策略, 顺序轮询
    balance roundrobin
    # 主节点, 绑定rabbitmq-master容器的5672端口, 每5秒检测一次心跳, 2次正确证明服务可用, 2次失败证明服务不可用
    server rabbit-master rabbitmq-master:5672        check inter 5000 rise 2 fall 2
    # 备节点, 绑定rabbitmq-backup容器的5672端口, 每5秒检测一次心跳, 2次正确证明服务可用, 2次失败证明服务不可用
    server rabbit-backup rabbitmq-backup:5672 backup check inter 5000 rise 2 fall 2
```
这里用`Docker Compose`搭建一套一主一备的集群
```yaml
version: "3"
services:
  haproxy:
    image: haproxy
    ports:
      - 5672:5672
    volumes:
      - ./haproxy:/usr/local/etc/haproxy # HAProxy 的配置文件路径
  rabbitmq-master:
    image: rabbitmq:3-alpine
  rabbitmq-backup:
    image: rabbitmq:3-alpine
```

然后启动一下, 就可以在本地搭建好一个`Warren`模式的主备集群了. 为了简单, 这里是在单机用`Docker`部署的.
如果不用`Docker`部署也差不多, 最主要的就是`HAProxy`的配置
```bash
# 1. 创建配置文件
mkdir -p /opt/rabbit-haproxy/haproxy && cd /opt/rabbit-haproxy
vim ./docker-compose.yml
vim ./haproxy/haproxy.cfg
# 2. 启动
docker-compose up
```

# 不研究了, 都是运维相关的, 有机会再补充
## 远程模式(Shovel模式)
在跨地域的集群进行数据复制
![Shovel模式](https://yuml.me/diagram/nofunky;dir:lr/class/[用户]->[RabbitMQ华南],[RabbitMQ华南]-同步>[RabbitMQ华北])
```bash
rabbitmq-plugins enable amqp_client rabbitmq_shovel
```

## 镜像集群(Mirror模式)

## 异地多集群(多活模式)
![多活模式](https://yuml.me/diagram/nofunky;dir:ud/class/[应用]->[LBS负载均衡1],[应用]->[LBS负载均衡2],[LBS负载均衡1]->[RabbitMQ1,RabbitMQ2,RabbitMQ3],[LBS负载均衡2]->[RabbitMQ3,RabbitMQ4,RabbitMQ5])
