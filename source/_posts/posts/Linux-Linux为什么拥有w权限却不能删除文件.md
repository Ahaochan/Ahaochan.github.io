---
title: Linux为什么拥有w权限却不能删除文件
url: Why_have_write_permission_but_can_not_delete_the_file
tags:
  - Linux
categories:
  - Linux
date: 2017-10-31 23:51:57
---
# 前言
Linux中万物皆文件, 目录是文件, 硬件是文件.
这里的文件和Windows的概念可完全不一样.
经常遇到的是, 对文件拥有w写权限, 可是却提示没有删除权限.
<!-- more -->

# 初始化情景
```sh
[ahao@localhost ~]$ su -                                # 切换为root用户
[ahao@localhost ~]$ mkdir testDir                # 创建testDir目录
[ahao@localhost ~]$ echo 123 > testDir/file # 创建testDir目录下的file文件
[ahao@localhost ~]$ chmod 555 testDir/      # 取消testDir目录的w写权限
[ahao@localhost tmp]$ rm testDir/file          # 删除testDir目录下的file文件, 失败
rm: 无法删除"testDir/file": 权限不够
```

# 分析
先查看文件和文件夹的权限信息
```sh
dr-xr-xr-x. 2 ahao ahao 18 10月 31 23:30 testDir
-rw-rw-r--. 1 ahao ahao  4 10月 31 23:30 file
```
`testDir目录文件`和`file文件`的拥有者和用户组毫无疑问是`ahao`.
那么对应的权限应该是`r-x`和`rw-`, 也就是`第2-4位`.

那么用户`ahao`对`file文件`是有w写权限的, 为什么不能删除呢?
**原因在于**
删除`file文件`, 是对`testDir目录文件`进行w写操作, 而不是对`file文件`进行w写操作.
对于Windows用户来说, 这是有点绕, 很难理解的.
![文件结构](https://yuml.me/diagram/nofunky/class/[testDir目录文件]->[file文件],[file文件]->[123字符串])
Linux的w写权限的意思是, 允许对其**子数据**进行写入.
`file文件`的w写权限是允许修改`123字符串`.
`testDir目录文件`的w写权限是允许修改`file文件`.

从文件和文件夹的权限信息可以看出, 
`用户ahao`是没有`testDir目录文件`的w写权限的, 换句话说, 就是不能修改`file文件`, 自然也就不能删除了。
```sh
dr-xr-xr-x. 2 ahao ahao 18 10月 31 23:30 testDir
-rw-rw-r--. 1 ahao ahao 4 10月 31 23:30 file
```

