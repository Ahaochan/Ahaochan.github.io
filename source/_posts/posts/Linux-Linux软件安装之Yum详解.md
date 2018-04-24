---
title: Linux软件安装之Yum详解
url: Yum_installation_of_Linux_software
tags: 
  - Linux软件安装
categories:
  - Linux
date: 2018-02-02 23:53:44
---
# 前言
`Yum(Yellow dog Updater, Modified)`是一个基于`RPM`包管理的字符前端软件包管理器。
能够从指定的服务器自动下载RPM包并且安装，可以自动处理**依赖性**关系，并且一次安装所有依赖的软件包，无须繁琐地一次次下载、安装。
不支持`RPM`查询和校验。

<!-- more -->

# Yum配置文件
配置文件在`/etc/yum.repos.d/`目录下
```sh
[root@localhost /]# cat /etc/yum.repos.d/CentOS-Base.repo 
[容器名]
name=容器说明
mirrorlist=镜像站点, 当baseurl无法访问时启用
#baseurl=Yum服务器地址
enabled=0禁用, 1启用, 默认启用
gpgcheck=0表示RPM数字证书失效, 1表示生效
gpgkey=数字证书的公钥文件保存位置

[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

# 省略其他容器
```

使用阿里云`Yum`源: [CentOS](https://mirrors.aliyun.com/help/centos)
配置好`repo`文件后, 清空缓存即可。
**注意, CentOS5已经过时, 很多网站都放弃了CentOS5的Yum源**
```sh
[root@localhost /]# yum clean all
[root@localhost /]# yum makecache
```

# 使用系统光盘创建本地Yum源
`Yum(Yellow dog Updater, Modified)`是一个基于`RPM`包管理的字符前端软件包管理器。
系统光盘自带了一堆`RPM`包, 也就是说, 使用系统光盘也可以创建一个本地的无需联网的`Yum`源。
```sh
# 1. 移除Yum网络源
[root@localhost /]# mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
# 2. 挂载光盘到 /mnt/cdrom 路径下
[root@locathost /]# mount -t auto /dev/cdrom /mnt/cdrom
# 2. 将挂载后的系统光盘路径设置为本地Yum源地址
[root@localhost /]# vim /etc/yum.repos.d/CentOS-Media.repo
[c5-media]
name=CentOS-$releasever - Media
baseurl=file:///mnt/cdrom/ # 光盘挂载点
# 只保留一个, 其他注释掉
#        file:///media/cdrom/
#        file:///media/cdrecorder/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5

# 3. 查看Yum列表, c5-media 为容器名, 说明本地Yum源设置成功
[root@localhost /]# yum list
[root@localhost ~]# yum list | grep 'httpd'
httpd.x86_64                              2.2.3-22.el5.centos          c5-media
httpd-manual.x86_64                       2.2.3-22.el5.centos          c5-media
system-config-httpd.noarch                5:1.3.3.3-1.el5              installed
```

# Yum常用命令
`Yum`安装等操作不用再使用包全名, 使用包名即可。
```sh
# 1. 安装, -y 自动回答yes
[root@localhost ~]# yum -y install httpd
# 2. 升级, 注意! 如果未加包名, 会更新所有软件, 包括系统内核!
[root@localhost ~]# yum -y update httpd
# 3. 卸载
[root@localhost ~]# yum -y remove httpd
# 4. 搜索, 或者使用 yum list | grep 'httpd'
[root@localhost ~]# yum search httpd
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
========================== Matched: httpd =============================
mod_ssl.x86_64 : Apache HTTP 服务器的 SSL/TLS 模块
system-config-httpd.noarch : Apache 配置工具。
httpd.x86_64 : Apache HTTP 服务器
httpd-manual.x86_64 : Apache HTTP 服务器的文档。
```

# Yum 软件组
软件组, 顾名思义, 就是一组软件。
```sh
# 1. 先将系统语言改为英文
[root@localhost ~]# LANG=en_US
# 2. 列出所有可用的软件组列表
[root@localhost ~]# yum grouplist
# 3. 安装 MySQL 软件组, 组名必须要英文, 第1步已经修改了系统语言
[root@localhost ~]# yum groupinstall "MySQL Server"
# 4. 卸载软件组
[root@localhost ~]# yum groupremove "MySQL Server"
# 5. 将系统语言改为中文UTF8
[root@localhost ~]# LANG=zh-CN.utf8
```