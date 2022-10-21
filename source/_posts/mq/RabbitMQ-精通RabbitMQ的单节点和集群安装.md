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
```shell script
mkdir -p /opt/rabbitmq/config && touch /opt/rabbitmq/config/rabbitmq.config
docker run -it --name rabbitmq -p 5672:5672 -p 15672:15672 \
    -v /opt/rabbitmq/config/rabbitmq.config:/etc/rabbitmq/rabbitmq.config \
    --hostname my-rabbit \
    rabbitmq:3-management
```
`rabbitmq:3-management`镜像整合了控制台插件, 访问`http://虚拟机IP:15672`就可以看到控制台了.

<!-- more -->

# 集群安装

## HAProxy 实现主备集群(Warren模式)
当主节点宕机的时候, `HAProxy`能够将备节点升级为主节点, 继续提供服务.
本质上还是`HAProxy`下的一个节点在提供服务, 所以一般在并发和数据量不高的情况下使用.
![Warren模式](https://yuml.me/diagram/nofunky;dir:UD/class/[HAProxy]->[RabbitMQ master],[HAProxy]->[RabbitMQ backup])

`HAProxy`是免费开源的高可用解决方案, 可以将请求分散到多个服务器上, 为基于`TCP`和`HTTP`的应用程序提供负载均衡和代理功能.
我们先创建一个简单的`HAProxy`配置文件`haproxy.cfg`
```shell script
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
      - ./haproxy:/usr/local/etc/haproxy:ro # HAProxy 的配置文件路径
  rabbitmq-master:
    image: rabbitmq:3-alpine
  rabbitmq-backup:
    image: rabbitmq:3-alpine
```

然后启动一下, 就可以在本地搭建好一个`Warren`模式的主备集群了. 为了简单, 这里是在单机用`Docker`部署的.
如果不用`Docker`部署也差不多, 最主要的就是`HAProxy`的配置
```shell script
# 1. 创建配置文件
mkdir -p /opt/rabbit-haproxy/haproxy && cd /opt/rabbit-haproxy
vim ./docker-compose.yml
vim ./haproxy/haproxy.cfg
# 2. 启动
docker-compose up
```

## Shovel模式
![Shovel模式](https://yuml.me/diagram/nofunky;dir:lr/class/[用户]->[RabbitMQ华南],[RabbitMQ华南]-同步>[RabbitMQ华北])
`Shovel`是`RabbitMQ`的一个插件, 本质上就是一个消费者, 消费当前节点的某个队列里的消息, 然后生产消息发送到目标节点的`Exchange`上, 使用`confirm`机制保证消息的可靠性投递.

这里先创建一个简单的`Docker`镜像, 官方并没有提供开启了`Shovel`的`RabbitMQ`镜像.
```dockerfile
FROM rabbitmq:3.7-management
RUN rabbitmq-plugins enable --offline rabbitmq_shovel rabbitmq_shovel_management
EXPOSE 5672 15672
# docker build -t rabbitmq-shovel .
# docker run -it --name rabbitmq1 -p 5672:5672 -p 15672:15672 rabbitmq-shovel
```

`Shovel`分为静态配置和动态配置

| 静态`Shovels` | 动态`Shovels` |
|:------------:|:-------------:|
| 在配置文件中设置 | 在命令行中设置 |
| 修改后要重启 | 修改后不需要重启 |

具体部署参阅官方文档
- [静态`Shovel`官方文档](https://www.rabbitmq.com/shovel-static.html)
- [动态`Shovel`官方文档](https://www.rabbitmq.com/shovel-dynamic.html)

## 镜像集群(Mirror模式)
![Mirror模式](https://yuml.me/diagram/nofunky;dir:ud/class/[应用]-VIP>[HAProxy&KeepAlived1],[应用]-VIP>[HAProxy&KeepAlived2],[HAProxy&KeepAlived1]->[RabbitMQ1],[HAProxy&KeepAlived1]->[RabbitMQ2],[HAProxy&KeepAlived1]->[RabbitMQ3],[HAProxy&KeepAlived2]->[RabbitMQ1],[HAProxy&KeepAlived2]->[RabbitMQ2],[HAProxy&KeepAlived2]->[RabbitMQ3])

```shell script
# https://github.com/pardahlman/docker-rabbitmq-cluster
git clone https://github.com/pardahlman/docker-rabbitmq-cluster.git
cd docker-rabbitmq-cluster
docker-compose up
```

## 异地多集群(多活模式)
![多活模式](https://yuml.me/diagram/nofunky;dir:ud/class/[应用]->[LBS负载均衡1],[应用]->[LBS负载均衡2],[LBS负载均衡1]->[RabbitMQ1,RabbitMQ2,RabbitMQ3],[LBS负载均衡2]->[RabbitMQ3,RabbitMQ4,RabbitMQ5])

# 参考资料
- [`Shovel`官方文档](https://www.rabbitmq.com/shovel.html)
- [静态`Shovel`官方文档](https://www.rabbitmq.com/shovel-static.html)
- [动态`Shovel`官方文档](https://www.rabbitmq.com/shovel-dynamic.html)