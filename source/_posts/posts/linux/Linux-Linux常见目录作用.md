---
title: Linux常见目录作用
url: Linux_base_directory
tags:
  - Linux
categories:
  - Linux
date: 2016-07-21 22:21:38
---

# 常见目录作用
## 命令目录/bin，/sbin，/usr/bin，/usr/sbin
用来保存系统命令
`bin`中的命令普通用户就可以执行
`sbin`中的命令只有root用户才可以执行
<!-- more -->

## 启动目录/boot
`/boot` 存放内核以及启动所需的文件等
保存用户的启动数据，不能写满

## 设备文件保存目录/dev
存放硬件文件

## 配置文件目录/etc
保存系统配置文件

## 普通用户家目录/home

## root用户家目录/root

## 系统函数库保存目录/lib


## 外接存储目录/misc，/media，/mnt
`/misc` 挂载外接磁带机
`/media` 挂载光盘
`/mnt` 挂载U盘等移动硬盘

## 内存目录/proc，/sys
不能直接操作，保存内存的挂载点（内存的盘符）

## 临时目录/tmp
存放临时数据

## 保存系统相关文档目录/var
