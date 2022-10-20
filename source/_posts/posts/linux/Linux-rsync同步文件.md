---
title: 使用rsync同步两台服务器的文件
url: use_rsync_to_sync_file_between_two_unix_system
tags:
  - Linux
categories:
  - Linux
date: 2020-05-24 17:07:00
---

# 前言
`rsync`是`unix`文件同步和传送工具。使用方法也很简单, 和`cp`类似。
首先安装`rsync`程序。
```bash
apt install -y rsync
```

<!-- more -->

# 简单例子
先做一个简单的例子测试下, 稍后再解释参数用法。
```bash
# 1. 初始化必要的文件
mkdir /opt/dir1 /opt/dir2 -p
echo 1 > /opt/dir1/file1
# 2. 现在 dir1 有 file1 文件, dir2 没有
ll /opt/dir1/ /opt/dir2/
# dir1/:
# -rw-r--r--. 1 root root 2 9月  18 10:12 file1
# dir2/:

# 3. 同步两个文件夹, 这里只会同步一次, 不会持续同步
rsync -avzP /opt/dir1/ /opt/dir2/
# sending incremental file list
# ./
# file1
#               2 100%    0.00kB/s    0:00:00 (xfr#1, to-chk=0/2)
#
# sent 107 bytes  received 38 bytes  290.00 bytes/sec
# total size is 2  speedup is 0.01

# 4. 现在 dir1/file1 已经同步到 dir2 中了
ll /opt/dir1/ /opt/dir2/
# dir1/:
# -rw-r--r--. 1 root root 2 9月  18 10:12 file1
# dir2/:
# -rw-r--r--. 1 root root 2 9月  18 10:12 file1
```

# 命令选项

| 选项缩写 | 选项全称 | 选项说明 |
|:-------:|:-------:|:-------:|
| `-a` | `--archive` | 完全的复制, 等于`-rlptgoD`。 |
| `-v` | `--verbose` | 输出详细日志 |
| `-q` | `--quiet`   | 输出简单日志 |
| `-r` | `--recursive` | 递归处理所有子目录 |
| `-z` | `--compress`  | 对备份的文件在传输时进行压缩处理 |
| `-P` | `--partial`   | 保留那些因故没有完全传输的文件, 用于加快随后的再次传输 |

更多选项查看: [`rsync命令`](https://man.linuxde.net/rsync)

# 配置文件
`rsync`有三个配置文件
1. `rsyncd.conf`是`rsync`服务器主要配置文件.
1. `rsyncd.secrets`是登录`rsync`服务器的密码文件.
1. `rsyncd.motd`是定义`rysnc`服务器信息的, 也就是用户登录信息. 非必须.

## rsyncd.conf
配置文件[官方`example`](https://download.samba.org/pub/rsync/rsyncd.conf.html)
如果`/etc/rsync.conf`不存在, 就手动创建。
```ini
# 全局通用配置
## 指定该模块以指定的 UID 传输文件。
uid = 0
## 指定该模块以指定的 GID 传输文件。
gid = 0
## 不使用 chroot 修改根的位置
use chroot = no

## 存放 rsync 后台守护进程的 pid 的值的文件
pid file = /var/run/rsyncd.pid
## 存放 rsync 的日志文件
log file = /var/log/rsyncd.log
lock file = /var/run/rsyncd.lock
## 存放远程服务器的用户名和密码, username:password 的形式
secrets file = /etc/rsyncd.passwd

## 最大并发连接数为4
max connections = 4

# 某个模块的配置
[module_test1]
auth users = root
path = /opt/dir1
comment = rsync test1 logs
read only = no

[module_test2]
auth users = root
path = /opt/dir1
comment = rsync test2 logs
read only = no
```

## rsyncd.secrets
将远程服务器用户名密码存入`/etc/rsyncd.passwd`文件, 重启服务
```bash
# 1. 存放用户名密码
echo "root:root" > /etc/rsyncd.passwd
chown root.root /etc/rsyncd.passwd
chmod 600 /etc/rsyncd.passwd

# 2. 以daemon方式重启服务
service rsync stop
rsync --daemon --config=/etc/rsync.conf
```

# 自动同步
自动同步有两种方案
1. 使用`crontab`定时调用
2. 使用`inotifytools`监控文件变化, 请参照另一篇文章**使用`inotifytools`监控文件**

这里提供一个简单的`shell`脚本
```bash
#!/bin/bash
# 1. 声明一个同步函数, rs(remoteIp, path)
function rs() {
    rsync -azP --delete $3 rsync://$1/$2  --password-file=/etc/rsyncd.passwd
}
# 2. 声明项目路径, 后面要加 / , 否则会连目录也一起传输过去
path=/opt/dir1/
module=module_test2
echo "开始同步到远程机器"
# 3. 开始传输
## B机器ip,格式：用户名@ip
rs root@192.168.154.128 ${module} ${path}
## C机器ip,格式：用户名@ip
rs root@192.168.154.129 ${module} ${path}
echo "结束同步"


## TODO 这个同步到远程的操作一直失败, 应该是哪里配错了, 等以后有机会再来改改吧
```

# 参考资料
- [官方文档](https://rsync.samba.org/examples.html)