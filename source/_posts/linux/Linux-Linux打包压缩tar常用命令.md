---
title: Linux打包压缩tar常用命令
url: Linux_package_compression_common_tar_commands
tags:
  - Linux
categories:
  - Linux
date: 2018-07-13 00:03:00
---
# 打包存在的意义
打包是把多个文件变成一个文件。
压缩是把一个大文件变成小文件。
那么要把多个文件压缩成小文件, 就只能曲线救国, 先把多个文件打包成一个文件, 然后再对这个文件进行压缩。

<!-- more -->

# 常用命令
## .tar 
解包：`tar xvf FileName.tar`
打包：`tar cvf FileName.tar DirName`

## .gz
解压1：`gunzip FileName.gz`
解压2：`gzip -d FileName.gz`
压缩：`gzip FileName`

## .tar.gz 和 .tgz
解压：`tar zxvf FileName.tar.gz`
压缩：`tar zcvf FileName.tar.gz DirName`

## .bz2
解压1：`bzip2 -d FileName.bz2`
解压2：`bunzip2 FileName.bz2`
压缩： `bzip2 -z FileName`

## .tar.bz2
解压：`tar jxvf FileName.tar.bz2`
压缩：`tar jcvf FileName.tar.bz2 DirName`

## .Z
安装：`yum install -y ncompress`
解压：`uncompress FileName.Z`
压缩：`compress FileName`

## .tar.Z
安装：`yum install -y ncompress`
解压：`tar Zxvf FileName.tar.Z`
压缩：`tar Zcvf FileName.tar.Z DirName`

## .zip
安装：`yum install -y zip`
解压：`unzip FileName.zip`
压缩：`zip FileName.zip DirName`

## .rar
解压：`rar x FileName.rar`
压缩：`rar a FileName.rar DirName`

## .rpm
解包：`rpm2cpio FileName.rpm | cpio -div`

# 参考资料
- [linux下解压命令大全](https://www.cnblogs.com/eoiioe/archive/2008/09/20/1294681.html)
