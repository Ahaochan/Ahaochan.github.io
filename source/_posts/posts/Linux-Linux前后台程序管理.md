---
title: Linux前后台程序管理
url: Linux_front_end_program_management
tags:
  - Linux
categories:
  - Linux
date: 2018-07-07 15:23:46
---
# 前言
比如我打开电脑登录了`administrator`用户, 打开`QQ`, 微信, 然后开始下载游戏, 看视频。 
我在看视频, 那么这个视频就是在前台运行的, 而下载游戏, 我不需要看它是怎么下载的, 所以放到后台执行, 这个就是前后台的应用场景。

<!-- more -->

# 相关命令
1. `命令; Ctrl+z`: 执行命令后, 按住`Ctrl+z`,将命令切换到后台**暂停**。
1. `命令 > /tmp/log.txt 2>&1 &`: 将命令放到后台执行, 注意要将输出信息重定向, 否则会污染前台操作
1. `bg %jobNumber`: 将某个后台程序放到后台**运行**。
1. `jobs -l`: 查看所有的后台程序, `-l`显示PID。
1. `fg %jobNumber`: 将某个后台程序放到前台运行。
1. `kill -9 %jobNumber`: 将某个后台程序**强制**结束运行。
1. `kill -15 %jobNumber`: 将某个后台程序**正常**结束运行。
1. `nohup 命令 &`: 将某个后台程序放到系统后台运行, 注销登录不会终止程序。

# jobs -l
`$ jobs [-lrs]`可以查看所有的后台程序。
选项与参数：
`-l`  ：除了列出 `job number` 与命令串之外，同时列出 `PID` 的号码；
`-r`  ：仅列出正在背景 `run` 的工作；
`-s`  ：仅列出正在背景当中暂停 (`stop`) 的工作。
```sh
$ jobs -l
[1]- 10314 Stopped                 vim ~/.bashrc
[2]+ 10833 Stopped                 find / -print
```
`[1]`和`[2]`表示的是`jobNumber`, 作为`fg`、`bg`、`kill`命令的参数。
`+`表示最近一个暂停的程序, `-`表示倒数第二个暂停的任务, 其他的不显示`+`和`-`。

# 样例
```sh
# 1. Ctrl+Z跳到后台暂停
$ vim ~/test.txt
123
# 按Ctrl+z
[1]+  已停止               vim ~/test.tx# 2. vim跳到前台执行
$ fg %1
# 3. 后台执行
$ tar -zpcvf /tmp/etc.tar.gz /etc > /tmp/log.txt 2>&1 &
[1] 5143
# 一段时间后, 执行完毕
[1]+  完成                  tar -zpcvf /tmp/etc.tar.gz /etc > /tmp/log.txt 2>&1
```
