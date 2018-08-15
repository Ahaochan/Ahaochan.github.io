---
title: 使用inotifytools监控文件
url: Monitor_files_with_inotifytools
date: 2018-08-15 17:47:00
tags:
  - Linux
categories:
  - Linux
---

# 前言
监控文件变化是一个很常用的功能, 比如监控密码文件, `html`文件, 如果被恶意修改, 那就发送一个请求给服务器, 发送短信给管理员。
这里使用`inotify-tools`来监控文件变化, 安装命令如下:
```sh
$ yum install -y inotify-tools
```
`inotify-tools`提供了两个命令: 
1. `inotifywait`, 它是用来监控文件或目录的变化
2. `inotifywatch`, 它是用来统计文件系统访问的次数

<!-- more -->

# 默认内核参数
参数以文件形式存储
| 文件路径 | 默认值 | 说明 |
|:------------:|:---------:|:------:|
| `/proc/sys/fs/inotify/max_queued_evnets` | 16384 | 表示调用`inotify_init`时分配给`inotify instance`中可排队的`event`的数目的最大值，超出这个值的事件被丢弃，但会触发`IN_Q_OVERFLOW`事件。|
| `/proc/sys/fs/inotify/max_user_instances` | 128 |表示每一个real user [id](http://man.linuxde.net/id "id命令")可创建的`inotify instatnces`的数量上限 |
| `/proc/sys/fs/inotify/max_user_watches` | 8192 | 表示每个`inotify instatnces`可监控的最大目录数量。如果监控的文件数目巨大，需要根据情况，适当增加此值的大小。|

如修改每个`inotify instatnces`可监控的最大目录数量为`104857600 `
```sh
$ echo 104857600 > /proc/sys/fs/inotify/max_user_watches
```

# inotifywait监控文件变化
**部分常用参数说明**
| 参数 | 说明 |
|:------:|:------:|
| `-m, --monitor` | 一直监听, 不指定则默认在第一个事件发生后结束 |
| `-r, --recursive` | 使用递归形式监视目录, 注意监视文件的数量最多为`8192`, 要修改数量需要修改`max_user_watches`文件 |
| `-q, --quiet` | 指定一次减少输出信息(仅打印事件), 指定两次不输出非错误信息 |
| `--timefmt` | 指定时间的输出格式, 显示在`--format`的`%T`中, 格式参考[strftime函数](http://www.cplusplus.com/reference/ctime/strftime/) |
| `--format` | 指定日志输出格式, `%w`表示发生事件的目录, `%f`表示发生事件的文件, `%e`表示发生的事件, `%Xe`事件名以`X`分隔, `%T`使用由`--timefmt`定义的时间格式 |
| `--event`| 只监听某些事件, 事件参考[可监听的事件](http://man.linuxde.net/inotifywait) |

先来个简单的例子, 监控`test`文件夹下的变化。
```sh
# 1. 在终端1开启inotifywait, -r表示递归监视, -m表示持续监视, -q表示只输出事件
$ mkdir test
$ inotify -rmq test/
# 2. 在终端2写入文件
$ echo 123 > test/123.txt
# 3. 终端1显示如下信息
test/ CREATE 123.txt
test/ OPEN 123.txt
test/ MODIFY 123.txt
test/ CLOSE_WRITE,CLOSE 123.txt
```

下面来一个复杂点的例子, 后台监控`test`文件夹变化, 并将变化内容发送到邮箱。(注意! 这种注释方式会[损耗性能](https://stackoverflow.com/a/12797512/6335926)! 这里只是为了直观才加的注释)
```sh
# 在终端1操作
$ vim inotify.sh
#/bin/bash
/usr/bin/inotifywait -rmq               `# 1. -r表示递归监视, -m表示持续监视, -q表示只输出事件` \
   --timefmt '%Y-%m-%d %H:%M:%S'        `# 2. 时间格式为 2018-08-15 16:16:12` \
   --format  '%T %w%f %e'               `# 3. 输出格式为: 时间 目录 文件 事件` \
   --event modify,attrib,create,delete  `# 4. 只监控特定事件` \
   test/                                `# 5. 监控test文件夹` \
   | while read log; do echo $log | mail -s '文件改变' root; done; `# 6. 读取管道流, 执行发送邮件给 root 的命令`

$ chmod 755 inotify.sh
$ nohup inotify.sh >> /dev/null 2>&1 &

# 在终端2操作
$ echo 123 > test/123.txt

# 在终端3操作, ctrl+D结束查看邮件
$ mail
Heirloom Mail version 12.5 7/5/10.  Type ? for help.
"/var/spool/mail/root": 1 message 1 new
>N  1 root                  Wed Aug 15 17:14  18/697   "文件改变"
& Held 1 message in /var/spool/mail/root
```

# inotifywatch统计访问次数

一个简单的例子, 监控`test`文件夹下`60s`内的变化次数
```sh
inotifywatch -v -e modify,delete,create,attrib,move,open,close,access -e modify -t 60 -r test/
```

# 参考资料
- [inotifywait命令](https://www.cnblogs.com/martinzhang/p/4126907.html)
- [inotifywatch](http://linux.51yip.com/search/inotifywatch)