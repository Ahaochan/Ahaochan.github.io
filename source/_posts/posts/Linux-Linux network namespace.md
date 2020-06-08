---
title: Linux网络命名空间
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

<!-- more -->

# 命令使用
我们先建立起一个概念, 将网络命名空间看作是一台虚拟机, 添加删除网络命名空间, 就是添加删除一台虚拟机.
```bash
# 添加网络命名空间
ip netns add ns1
# 查看网络命名空间
ip netns list
# 删除网络命名空间
ip netns delete ns1

# 在 ns1 里执行 ip link 命令
ip netns exec ns1       ip link
# 1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00

# 在 ns1 里执行 ip link set dev lo up 命令, 将 lo 网卡 up 起来
ip netns exec ns1       ip link set dev lo up
ip netns exec ns1       ip link
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1
#     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
```
我们可以看到, 我们想在网络命名空间`ns1`里将`lo`网卡`up`起来, 但实际上却是从`DOWN`状态变成`UNKNOWN`状态, 并没有变成`UP`状态.
这也可以理解, 实际生活中, 我们给一台机器联网, 也不仅仅是将水晶头插入机器网卡上, 还要将另一头插入路由器.
![Veth pair](https://yuml.me/diagram/nofunky/class/[ns1]<->[ns2])



# 使用 Veth pair 进行一对一通信
在`Linux`网络命名空间担任网线一职的, 是叫做`Veth pair`的东西.
我们先来做一个实际的例子, ；将两个网络命名空间连通起来.

相互连接的两个网络命名空间, 各自拥有一个`Veth pair`, `Veth pair`是成对存在的, 删掉一个另一个也会被删掉.

下面是简单的一个拉网线例子, 将两个网络命名空间`ns1`和`ns2`连通起来.
```bash
# 1. 添加2个network namespace
ip netns add ns1
ip netns add ns2

# 2. 添加一对 veth pair
# ip link add <p1-name> type veth peer name <p2-name>
ip link add veth-test1 type veth peer name veth-test2

# 3. 绑定到对应的网络命名空间上
# ip link set <Veth-pair>  netns <network-namespace>
ip link set veth-test1 netns ns1
ip link set veth-test2 netns ns2

# 4. 为不同网络命名空间下的 veth pair 添加 ip 地址
ip netns exec ns1       ip addr add 192.168.1.1/24  dev veth-test1
ip netns exec ns2       ip addr add 192.168.1.2/24  dev veth-test2

# 5. 启用 veth pair
ip netns exec ns1       ip link set dev veth-test1 up
ip netns exec ns2       ip link set dev veth-test2 up

# 6. ping
ip netns exec ns1       ping 192.168.1.2
ip netns exec ns2       ping 192.168.1.1
ip netns exec ns1       ip link
ip netns exec ns2       ip link
```

# 使用 Bridge 进行多对多通信
如果有`100`台机器进行通信, 就需要`100*100=10000`个`Veth pair`. 这种拓扑结构明显是有问题的.
在实际生活中, 我们也不会在一台机器上部署`100`个网卡, 而是通过集线器或者路由器来实现多机通信.
`Bridge`提供了一个桥梁, 相当于一个中转站, 这样要追加`1`台机器, 只需要`1`个`Veth pair`, 连接到`Bridge`, `Bridge`会转发到目标机器上.

## 简单的 3 台机器通信例子
```bash
# 1. 创建 Bridge 并启动, 创建3个 network namespace
ip link add ahao-bridge type bridge
ip link set dev ahao-bridge up
ip netns add ns1
ip netns add ns2
ip netns add ns3

# 2. 创建 3对 Veth pair
ip link add veth-bridge1 type veth peer name veth-ns1
ip link add veth-bridge2 type veth peer name veth-ns2
ip link add veth-bridge3 type veth peer name veth-ns3

# 3. 绑定到各自的 network namespace
ip link set veth-ns1 netns ns1
ip link set veth-ns2 netns ns2
ip link set veth-ns3 netns ns3

# 4. 添加ip地址
ip netns exec ns1       ip addr add 192.168.1.1/24 dev veth-ns1
ip netns exec ns2       ip addr add 192.168.1.2/24 dev veth-ns2
ip netns exec ns3       ip addr add 192.168.1.3/24 dev veth-ns3

# 5. 连接到bridge
ip link set dev veth-bridge1 master ahao-bridge
ip link set dev veth-bridge2 master ahao-bridge
ip link set dev veth-bridge3 master ahao-bridge

# 5. 启用
ip netns exec ns1 ip link set dev veth-ns1 up
ip netns exec ns2 ip link set dev veth-ns2 up
ip netns exec ns3 ip link set dev veth-ns3 up
ip link set dev veth-bridge1 up
ip link set dev veth-bridge2 up
ip link set dev veth-bridge3 up

# 6. ping测试
ip netns exec ns1 ping 192.168.154.2
ip netns exec ns1 ping 192.168.154.3

# TODO 跑不起来
ip netns delete ns1
ip netns delete ns2
ip netns delete ns3
ip link delete ahao-bridge
ip netns list
ip link
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