---
title: Linux的资源限制ulimit命令
url: ulimit_Command_of_Linux
tags:
  - Linux
categories:
  - Linux
date: 2018-11-08 15:32:00
---

# 前言
`ulimit`是一个`Linux`命令, 用于限制`shell`进程及其子进程的系统资源使用。通俗且不严谨的讲，就是限制登录用户能一次性打开多少个进程，多少个文件等等。
> 假设有这样一种情况，当一台 Linux 主机上同时登陆了 10 个人，在系统资源无限制的情况下，这 10 个用户同时打开了 500 个文档，而假设每个文档的大小有 10M，这时系统的内存资源就会受到巨大的挑战。

<!-- more -->

# 参数说明
`ulimit`限制分为`soft`软上限和`hard`硬上限, 使用`ulimit`命令默认修改`soft`软上限。
- `soft`软上限: 任何进程都可以修改软上限，但是软上限不能超过硬上限
- `hard`硬上限: 普通进程可以降低硬上限，只有`root`可以提高硬上限

命令格式: `ulimit [options] [limit]`

| `options`参数 | 含义 | 例子 |
|:------------:|:----:|:----:|
| `-H` | 设置硬资源限制, 一旦设置不能增加。| `ulimit -Hs 64` 限制硬资源, 线程栈大小为 64K。|
| `-S` | 设置软资源限制, 设置后可以增加, 但是不能超过硬资源设置。| `ulimit -Sn 32` 限制软资源, 32 个文件描述符。|
| `-a` | 显示当前所有的 limit 信息, 默认显示软上限。 | `ulimit -a` 显示当前所有的 limit 信息。|
| `-c` | 最大的 core 文件的大小, 以 blocks 为单位。 | `ulimit -c unlimited`  对生成的 core 文件的大小不进行限制。|
| `-d` | 进程最大的数据段的大小, 以 Kbytes 为单位。 | `ulimit -d unlimited` 对进程的数据段大小不进行限制。|
| `-f` | 进程可以创建文件的最大值, 以 blocks 为单位。 | `ulimit -f 2048` 限制进程可以创建的最大文件大小为 2048 blocks。|
| `-l` | 最大可加锁内存大小, 以 Kbytes 为单位。 | `ulimit -l 32` 限制最大可加锁内存大小为 32 Kbytes。|
| `-m` | 最大内存大小, 以 Kbytes 为单位。 | `ulimit -m unlimited` 对最大内存不进行限制。|
| `-n` | 可以打开最大文件描述符的数量。 | `ulimit -n 128` 限制最大可以使用 128 个文件描述符。|
| `-p` | 管道缓冲区的大小, 以 Kbytes 为单位。 | `ulimit -p 512` 限制管道缓冲区的大小为 512 Kbytes。|
| `-s` | 线程栈大小, 以 Kbytes 为单位。 | `ulimit -s 512` 限制线程栈的大小为 512 Kbytes。|
| `-t` | 最大的 CPU 占用时间, 以秒为单位。 | `ulimit -t unlimited` 对最大的 CPU 占用时间不进行限制。|
| `-u` | 用户最大可用的进程数。 | `ulimit -u 64` 限制用户最多可以使用 64 个进程。|
| `-v` | 进程最大可用的虚拟内存, 以 Kbytes 为单位。 | `ulimit -v 200000` 限制最大可用的虚拟内存为 200000 Kbytes。|

# 配置方法

**对登录用户进行限制**
1. 在`/etc/profile`、`/etc/bashrc`、`~/.bash_profile`、`~/.bashrc`文件中写入`ulimit`命令。
1. 直接在控制台输入`ulimit`命令, 这是临时配置, 重启失效。

**对应用程序进行限制**
1. 对`Tomcat`进行限制, 编写启动脚本
```sh
ulimit -s 512;
startup.sh
```

**对多个用户或用户组进行限制**
1. 在`/etc/security/limits.conf`中输入`<domain> <type> <item> <value>`, 每一行一个限制。
>domain 表示用户或者组的名字，还可以使用 * 作为通配符。Type 可以有两个值，soft 和 hard。Item 则表示需要限定的资源，可以有很多候选值，如 stack，cpu，nofile 等等，分别表示最大的堆栈大小，占用的 cpu 时间，以及打开的文件数。通过添加对应的一行描述，则可以产生相应的限制

**对系统全局的进程进行限制**
1. 修改`/proc`下的文件

# 常用例子
1. `ulimit -a`: 查看当前 `shell` 的所有资源限制，默认显示软限制
1. `ulimit -Sa`: 查看当前 `shell` 的所有资源限制，`-S` 表示显示软限制
1. `ulimit -Ha`: 查看当前 `shell` 的所有资源限制，`-H` 表示显示硬限制
1. `ulimit -n`: 显示当前可打开的文件描述符数量，软限制
1. `ulimit -Hn`: 显示当前可打开的文件描述符数量，硬限制
1. `ulimit -n 10240`: 修改可打开的文件描述符数为 `10240`，默认软限制，除非指明参数 `H`
1. `ulimit -Hn 51200`: 修改可打开的文件描述符数为 `51200`，硬限制(如果是提高硬限制，则需要 `root` 权限)
1. `ulimit -s 102400`: 修改堆栈大小的软限制为 `102400 kbytes` 即 `100 MB`
1. `ulimit -Hs unlimited`: 修改堆栈大小的硬限制为 `unlimited`，即不限制上限

# 参考资料
- [通过 ulimit 改善系统性能](https://www.ibm.com/developerworks/cn/linux/l-cn-ulimit/index.html)
- [Linux ulimit详解](https://www.zfl9.com/ulimit.html)