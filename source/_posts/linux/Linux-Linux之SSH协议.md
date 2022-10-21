---
title: Linux之SSH协议
url: Linux_SSH_protocol
tags:
  - Linux
categories:
  - Linux
date: 2017-10-09 23:55:19
---

# 前言
` SSH ` 为 ` Secure Shell ` 的缩写。在使用远程工具连接 ` Linux ` 时使用的就是 ` SSH协议 `。
` SSH协议 ` 使用的是非对称加密算法。
简单的说, 有一个管道, 用来传递数据, A和B在管道的两端, A和B各自拥有一把锁和一把钥匙。
B要传数据给A, 那么B先把自己的锁给A。
A用自己的A锁加上B锁给数据上锁, 这时候只有A的A钥匙和B的B钥匙能解开这个锁获取数据。
A和B使用不同的锁和钥匙, 这就是非对称加密。

<!-- more -->

# Linux下的SSH
这里使用 ` 127.0.0.1 ` 回环地址进行测试。
除了远程操作之外, 还可以使用 ` SSH ` 进行文件的上传和下载。
```shell
[ahao@localhost ~]$ ssh username@IP             # 远程管理指定Linux服务器
[ahao@localhost ~]$ ssh root@127.0.0.1           # 连接本机的root用户
The authenticity of host '127.0.0.1 (127.0.0.1)' can't be established.
ECDSA key fingerprint is 60:18:c3:85:f3:2e:f9:34:4d:2f:9a:0e:cf:e9:85:64.
Are you sure you want to continue connecting (yes/no)? yes                  # 选择yes进行连接
Warning: Permanently added '127.0.0.1' (ECDSA) to the list of known hosts.
root@127.0.0.1's password:                               # 输入密码
Last login: Tue Oct 10 00:06:25 2017
[root@localhost ~]# exit                                    # 退出

[ahao@localhost ~]$ scp [-r] 用户名@IP:文件路径 本地路径       # 下载文件
[ahao@localhost ~]$ scp [-r] 本地文件 用户名@IP:上传路径       # 上传文件
```

# Windows下的SSH
借助SSH工具[xshell](https://www.netsarang.com/products/xsh_overview.html)
使用 ` ifconfig ` 查看Linux的IP地址, 照着软件配置就好了, 百度很多使用教程。

# 小知识
Linux的SSH公钥存储在 ` ~/.ssh/known_hosts `。
Windows的SSH公钥存储在 ` %HOMEPATH%/.ssh/known_hosts `。
