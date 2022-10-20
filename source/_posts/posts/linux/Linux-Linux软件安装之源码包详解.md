---
title: Linux软件安装之源码包详解
url: source_code_installation_of_Linux_software
tags: 
  - Linux软件安装
categories:
  - Linux
date: 2018-02-02 23:49:37
---
# 前言
源代码包则主要适用于自由软件的安装，用户需要自己编译它们。
通常从软件的官方网站获取下载。
就是开发者写的代码, 需要自己手动编译。

<!-- more -->

# 正文
以 `Apache` 的 `httpd` 包为例。[httpd各版本下载地址](http://archive.apache.org/dist/httpd/)

```sh
# 1. 安装 gcc 编译器, 源码包必须安装编译器
[root@localhost /]# yum -y install gcc
# 2. 下载 Apache 的 httpd 源码包, -C 断点续传, -o 指定输出文件
[root@localhost /]# curl -C -o /opt/httpd-2.2.9.tar.gz http://archive.apache.org/dist/httpd/httpd-2.2.9.tar.gz
# 3. 解压缩, 并进去该目录, -z 使用gzip压缩, -x 解压缩, -v 显示操作过程, -f 指定操作的文件, -C 解压在指定目录下
[root@localhost /]# tar -zxvf /opt/httpd-2.2.9.tar.gz -C /opt

# 4.1. 进入解压缩后的目录, 必须!!!
[root@localhost /]# cd /opt/httpd-2.2.9
# 4.2. 软件配置, 生成Makefile文件, 保存定义好的功能选项和检测系统环境的信息, 用于后续的安装
#        安装到 /opt/apache 目录下
[root@localhost httpd-2.2.9]# ./configure --prefix=/opt/apache
# 4.3. make是用来编译的，它从Makefile中读取指令，然后编译。
#        如果报错, 需要执行 make clean 清除缓存和临时文件。
[root@localhost httpd-2.2.9]# make
# 4.4. make install是用来安装的，它也从Makefile中读取指令，安装到指定的位置。
#        如果报错, 需要执行 make clean 清除缓存和临时文件, 并删除/opt/apache目录。
[root@localhost httpd-2.2.9]# make install

# 5. 编辑html, 启动apache, 关闭防火墙, 在浏览器输入服务器的 ip 地址即可访问
[root@localhost httpd-2.2.9]# vim /opt/apache/htdocs/index.html
[root@localhost httpd-2.2.9]# /opt/apache/bin/apachectl start
[root@localhost httpd-2.2.9]# systemctl stop firewalld.service

# 6. 卸载直接删除目录即可
[root@localhost httpd-2.2.9]# cd / && rm -rf /opt/http* /opt/apache
```