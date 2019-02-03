---
title: Docker容器网络
url: Docker_network
tags:
  - Docker
categories:
  - Docker
date: 2019-02-02 23:36:00
---
# 前言
`Docker`有三种网络连接方式, `bridge`、`host`和`none`.
`Docker`会自动创建`3`个网络, 每种`1`个.
```bash
docker network ls
# NETWORK ID          NAME                DRIVER              SCOPE
# 7b083adc391a        bridge              bridge              local
# 5855c878dc68        host                host                local
# 9895a4ab897d        none                null                local
```

<!-- more -->

# bridge 网络隔离
默认的`container`使用的是`bridge`连接, `container`使用`--link <container>`可以连接到其他的`container`.
做到网络隔离的效果.

比如
```bash
# 1. 创建一个 bridge1 容器, 并查看ip地址
docker run -d --name bridge1 busybox /bin/sh -c "ping 192.168.0.1"
docker exec -it bridge1 ip a

# 2. 创建一个 bridge2 容器, 并 ping bridge1 的 ip 地址
docker run -d --name bridge2 --link bridge1 busybox /bin/sh -c "ping 192.168.0.1"
docker exec -it bridge2 /bin/ping bridge1的IP地址
docker exec -it bridge2 /bin/ping bridge1

# 3. 默认的 bridge 是单向的, bridge1 ping bridge2 失败
docker exec -it bridge1 /bin/ping bridge2
```
发现`bridge2`可以直接`ping bridge1`, 不用输入`IP`地址.
因为`--link bridge1`相当于给`bridge2`添加了一条`DNS`解析.
**而且, 默认的 `bridge` 是单向的, 这句话先记着, 后面讲**

我们可以自己创建一个`bridge`, 做网络隔离.
```bash
# 1. 创建自己的 bridge
docker network create -d bridge my-bridge
docker network ls

# 2. 创建一个新的 container 连接到 my-bridge
docker run -d --name bridge3 --link bridge1 --network my-bridge busybox /bin/sh -c "ping 192.168.0.1"

# 3. ping bridge1 失败
docker exec -it bridge3 /bin/ping bridge1的IP地址
docker exec -it bridge3 /bin/ping bridge1
```

把 `bridge1` 连接到 `my-bridge`上, 注意, 此时 `bridge1` 仍然存在于默认的 `bridge` 上.
```bash
# 1. 把 bridge1 连接到 my-bridge
docker network connect my-bridge bridge1

# 2. ping bridge1 成功
docker exec -it bridge3 /bin/ping bridge1的IP地址
docker exec -it bridge3 /bin/ping bridge1

# 3. ping bridge3 成功
docker exec -it bridge1 /bin/ping bridge3的IP地址
docker exec -it bridge1 /bin/ping bridge3
```
注意, 我们没有给`bridge1`添加`--link bridge3`, 只是连接到 `my-bridge`, 却可以`ping bridge3`.
因为和默认的`bridge`不同, **自己创建的`bridge`默认是双向的**.

# host 共享 network namespace
如果我们用`Docker`启动了一个`nginx`服务器. 
此时, 只有宿主机可以访问`Docker`容器里的`nginx`服务器.
```bash
# 1. 运行本地服务器 nginx
docker run -d --name web-local nginx
# 2. 查看container的容器地址, 默认连接到 bridge 上
#    看 Containers 下的 IPv4Address, 得知 IP 地址为 172.17.0.2
docker network inspect bridge
# 3. 测试连接 nginx, 访问成功
ping 172.17.0.2
curl http://172.17.0.2
```
在宿主机里可以访问这个`nginx`, 但是在局域网的其他机器上, 却不能访问`http://172.17.0.2`.
我们需要把宿主机里的`nginx`暴露到外部来, 使用端口映射达到这个目的.
将`container`的`80`端口, 映射到宿主机的`8080`端口, 这样, 我们直接访问宿主机的`8080`端口, 就可以间接的访问到`nginx`.
```bash
docker run -d -p 8080:80 --name web-port-map nginx
```

以上文字和`host`毫无关联, 只是为下文做铺垫.
`host`可以共享宿主机的`network namespace`, 关于`Linux network namespace`可以看我的另一篇文章.
把它想象成一个网络沙箱即可.
还是用`nginx`做个简单例子, 我们从上面可以知道部署`nginx`需要做端口映射.
但是使用`host`共享宿主机的`network namespace`就可以**不用做端口映射**.
```bash
docker run -d --name web-host --network host nginx
```
注意, **这里没有使用端口映射**.
然而, 我们依旧能在外部, 使用宿主机的`IP`地址, 访问到`80`端口的`nginx`.


# none 断网操作
一般用于安全性, 保密性较高的程序.
直接隔离网络, 断网.
```bash
docker run -d --name net-none --network none busybox /bin/sh -c "while true; do sleep 3600;done"
docekr exec -it net-none ip a
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
#     inet 127.0.0.1/8 scope host lo
#        valid_lft forever preferred_lft forever
```
