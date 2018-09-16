---
title: Nginx的负载均衡配置
url: Nginx_Server_load_balancing_configuration
tags:
  - Nginx
categories:
  - Nginx
date: 2018-09-16 18:36:00
---

# 前言
负载均衡本质就是一个反向代理。
通俗点讲, 就类似`10086`客服电话, 如果只有一个通话员, 那全国十几亿人肯定处理不过来, 这时候就多招聘一堆通话员, 做负载均衡, 这样就减少了通话员的压力。

<!-- more -->

# SLB和GSLB

负载均衡又分为
1. `GSLB(Global Server Load Balance)`全局负载均衡
2. `SLB(Server load balancing)`负载均衡

还是以`10086`为例, 如果只有北京开设了一个通话员中心(`SLB`), 即使通话员(`server`)的数量足够, 但是广东省的要打电话过去, 西藏的要打电话过去, 路途遥远。那么就设立多个通话员中心(`SLB`), 广东省的打广东省的`10086`, 西藏的打西藏的`10086`, 如果解决不了问题, 再上升到北京的`10086`。
![](https://yuml.me/diagram/nofunky/class/[1广东用户]->[1广东10086],[2西藏用户]->[2西藏10086],[1广东10086]->[3北京10086],[2西藏10086]->[3北京10086])
也就是说, 多个`SLB`组成了`GSLB`。

# OSI模型上的负载均衡
学过计算机网络的应该都知道[`OSI`模型](https://zh.wikipedia.org/wiki/OSI模型), 分为物理层、数据链路层、网络层、传输层、会话层、表示层、应用层。
比如数据链路层是根据`mac`地址进行数据包发送的, 那么就可以在这里做负载均衡。（一般是用虚拟`mac`地址方式，外部对虚拟`mac`地址请求，负载均衡接收后分配后端实际的`mac`地址响应）。

最常用的就是
**四层负载均衡(`IP + port`)**
**七层负载均衡(`IP + port + URL`)**
`Nginx`是应用层, 也就是七层负载均衡。


# 基本配置
假设我们有三台机器`192.168.0.100`、`192.168.0.101`、`example.com`。
下面是一个简单的配置方法, `upstream`块必须在`http`块内。
```
http {
    upstream tomcats {
        server 192.168.0.100:8080;
        server 192.168.0.101:8080;
        server example.com:8080;
    }
    server {
        # 1. 负载均衡, 首页单独处理, 加快速度
        location = / {
            proxy_pass http://tomcats/index
        }
        location / {
            proxy_pass http://tomcats
        }
    }
}
```
默认是以请求次数做轮询条件, 比如第一次请求, 则分配到`192.168.0.100:8080`, 第二次请求, 则分配到`192.168.0.101:8080`, 以此类推。

## 额外配置
追加到`server`后面
```
upstream tomcats {
    server 192.168.0.100:8080;
    server 192.168.0.101:8080 weight=2;
    server example.com:8080 down;
}
```
| 配置 | 说明 |
|:------:|:------:|
| `weight=2` | 权重越高, 越容易被轮询到 |
| `down` | 暂不参与负载均衡 |
| `backup` | 预留的备份服务器, 当其他所有服务挂了的时候启用 |
| `max_fails=1` | 允许请求失败的次数 |
| `fail_timeout=10s` | 经过`max_fails`失败后, `server`暂停的时间, 默认`10s` |
| `max_conns=10` | 限制最大的接收连接数 |

# 轮询策略
当然, 还有其他的轮询策略, 配置到`upstream`内即可。

| 轮询策略 | 说明 |
|:------------:|:------:|
| 轮询(默认) | 按请求顺序分配到不同的`server` |
| 加权轮询 | `weight`值越大, 分配到的访问几率越高 |
| `ip_hash` | 每个请求按访问`IP`的`hash`结果分配, 同一个`IP`固定访问一个`server` |
| `url_hash` | 按照访问的`URL`的`hash`结果分配, 同一个`URL`固定访问一个`server` |
| `least_conn` | 最少链接数, 哪个`server`连接数少就分配给谁 |
| `hash关键数值` | `hash`自定义的`key`, `url_hash`是具体实现, 在`Nginx 1.7.2`后可用

## ip_hash
用于需要对`Session`或`Cookie`保持一致的情况。
但是如果多台机器走同一个代理服务器, `Nginx`根据代理服务器的`IP`做`Hash`, 会导致多台服务器走的都是同一个`server`.
```
    upstream tomcats {
        ip_hash;
        server 192.168.0.100:8080;
        server 192.168.0.101:8080;
        server example.com:8080;
    }
```

## url_hash
`url_hash`是将`$request_uri`作为自定义`hash`的`key`。
注意, 自定义`hash key`只有在`Nginx 1.7.2`后可用。
```
    upstream tomcats {
        hash $request_uri;;
        server 192.168.0.100:8080;
        server 192.168.0.101:8080;
        server example.com:8080;
    }
```

# 参考资料
- [四层和七层负载均衡 - 详细总结](http://blog.51cto.com/dmwing/1896879)