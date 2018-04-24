---
title: VMware虚拟机的网络连接方式
url: VMware_virtual_machine_network_connection
date: 2017-11-05 00:24:25
tags:
  - VMware
categories:
  - 工具
---

# 前言
安装VMware后, 可以在网络适配器看到两个虚拟网卡`VMnet1`和`VMnet8`。
<!-- more -->

# 连接方式
打开`网络与共享中心`, 点击左侧`更改适配器设置`, 右键`VMnet1`或`VMnet8`, 选择`属性`。
确保两个网卡都开启`VMware Bridge Protocal`协议。

打开VMware, 点击菜单栏`编辑`, 选择`虚拟网络编辑器`, 可以看到三种配置。

## 桥接模式
使用真实网卡连接, 选择可以`上网`的一块网卡。
推荐指定具体网卡, 不选择自动。

只要和真实机相同`网段`即可通信。
需要`占用`真实网段的ip地址。

## NAT连接模式
使用VMnet8虚拟网卡连接。
只能和真实机通信, 不能连接局域网其他设备。
可以访问互联网。

## Host-only连接方式
使用VMnet1虚拟网卡连接。
只能和真实机通信, 不能连接局域网其他设备。
只能连接真实机。