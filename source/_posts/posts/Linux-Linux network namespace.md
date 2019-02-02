---
title: Linux network namespace
url: Linux_network_namespace
tags: 
  - 计算机网络
  - Linux
categories:
  - Linux
date: 2019-02-02 14:39:00
---

# network namespace
`Linux network namespace` 是 `Linux` 提供的网络虚拟化功能, 它能创建网络虚拟空间, 将容器(`Docker`)或虚拟机的网络隔离开来, 假装是一台独立的网络机器.
`Docker`也使用了`Linux network namespace`来隔离网络空间.
这里使用`ip`命令来查看网络信息.

<!-- more -->

# 使用 Veth pair 进行一对一通信

## 准备两个network namespace
先准备两个`network namespace`.
```bash
# 1. 添加3个network namespace
# ip netns add <name>
ip netns add test1
ip netns add test2
ip netns add test3
# 2. 删掉1个network namespace
ip netns delete test3
# 3，查看所有network namespace
ip netns list
```

默认的`network namespace`只有一个回环地址, 并且启动网卡也是`UNKNOWN`状态, 因为没有做网络连接.
```
[root@localhost ~]# ip netns exec test1 ip link
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
[root@localhost ~]# ip netns exec test1 ip link set dev lo up
[root@localhost ~]# ip netns exec test1 ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```

## Veth pair 绑定、启用、ping
`Veth pair`像一条网线, 连接两个`network namespace`. 
相互连接的两个`network namespace`, 各自拥有一个`Veth pair`, `Veth pair`是成对存在的, 删掉一个另一个也会被删掉.

创建一对`Veth pair`, 默认都是`DOWN`的.
```bash
# ip link add <p1-name> type veth peer name <p2-name>
ip link add veth-test1 type veth peer name veth-test2
46: veth-test2@veth-test1: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT qlen 1000
    link/ether 32:70:51:a9:bb:2d brd ff:ff:ff:ff:ff:ff
47: veth-test1@veth-test2: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT qlen 1000
    link/ether fa:7d:53:a0:13:9a brd ff:ff:ff:ff:ff:ff
```

将`Veth pair`和两个`network namespace`绑定.
```bash
#ip link  set <Veth-pair>  netns <network-namespace>
ip link  set veth-test1  netns test1
ip link  set veth-test2  netns test2

# 本机的ip link的两个Veth pair消失
ip link
# 两个 network namespace 各自多了个Veth pair
ip netns exec test1  ip link
ip netns exec test2  ip link
```

为`Veth pair`添加`ip`地址
```bash
ip netns exec test1  ip addr add 192.168.1.1/24  dev veth-test1
ip netns exec test2  ip addr add 192.168.1.2/24  dev veth-test2
```

启动`Veth pair`
```bash
ip netns exec test1  ip link set dev veth-test1 up
ip netns exec test2  ip link set dev veth-test2 up
```

这时候就`ping`通两个不同的`network namespace`了.
```bash
ip netns exec test1  ping 192.168.1.2
```

# 使用 Bridge 进行多对多通信
如果有`100`台机器进行通信, 现在再追加`1`台机器, 就需要`100`个`Veth pair`. 这种拓扑结构明显是有问题的.
`Bridge`提供了一个桥梁, 相当于一个中转站, 这样要追加`1`台机器, 只需要`1`个`Veth pair`, 连接到`Bridge`, `Bridge`会转发到目标机器上.

## 简单的 3 台机器通信例子
```bash
# 1. 创建 Bridge 并启动, 创建3个 network namespace
ip link add bridge-ns type bridge
ip link set dev bridge-ns up
ip netns add ns1
ip netns add ns2
ip netns add ns3

# 2. 创建 3对 Veth pair
ip link add veth-bridge1 type veth peer name veth-ns1
ip link add veth-bridge2 type veth peer name veth-ns2
ip link add veth-bridge3 type veth peer name veth-ns3

# 3. 绑定到各自的 network namespace
ip link  set veth-ns1  netns ns1
ip link  set veth-ns2  netns ns2
ip link  set veth-ns3  netns ns3

# 4. 添加ip地址
ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth-ns1
ip netns exec ns2 ip addr add 192.168.1.2/24 dev veth-ns2
ip netns exec ns3 ip addr add 192.168.1.3/24 dev veth-ns3

# 5. 连接到bridge
ip link set dev veth-bridge1 master bridge-ns
ip link set dev veth-bridge2 master bridge-ns
ip link set dev veth-bridge3 master bridge-ns

# 5. 启用
ip netns exec ns1 ip link set dev veth-ns1 up
ip netns exec ns2 ip link set dev veth-ns2 up
ip netns exec ns3 ip link set dev veth-ns3 up
ip link set dev veth-bridge1 up
ip link set dev veth-bridge2 up
ip link set dev veth-bridge3 up

# 6. ping测试
ip netns exec ns1 ping 192.168.1.2
ip netns exec ns1 ping 192.168.1.3
```

结果这`3`台机器都可以两两相互通信.
使用`bridge link`命令可以查看连接信息.
```bash
# brctl 命令需要安装依赖
yum install -y bridge-utils
bridge link
# 50: veth-bridge1 state UP @(null): <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master bridge-ns state forwarding priority 32 cost 2 
# 52: veth-bridge2 state UP @(null): <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master bridge-ns state forwarding priority 32 cost 2 
# 56: veth-bridge3 state UP @(null): <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master bridge-ns state forwarding priority 32 cost 2 
```

# 使用 NAT 连接外网
待续