---
title: Linux文件权限
url: Linux_File_Permissions
tags:
  - Linux
categories:
  - Linux
date: 2017-10-03 11:24:32
---
# 查看文件权限
在Linux使用 ` ll -ah ` 可以看到以下命令。
文件权限就存储在 ` drwxr-xr-x ` 这十个字符之中。

<!-- more -->

```sh
drwx------ 21 ahao ahao 4.0K 09-22 04:06 .
drwxr-xr-x  4 root root 4.0K 09-21 19:26 ..
-rw-------  1 ahao ahao 2.0K 09-22 02:59 .bash_history
-rw-r--r--  1 ahao ahao   33 2009-01-22 .bash_logout
-rw-r--r--  1 ahao ahao  176 2009-01-22 .bash_profile
-rw-r--r--  1 ahao ahao  124 2009-01-22 .bashrc
drwx------  2 ahao ahao 4.0K 09-21 19:29 .chewing
drwxr-xr-x  2 ahao ahao 4.0K 09-21 19:42 Desktop
```

# 权限分析
Linux的文件权限分为` 用户权限user ` 、 ` 用户所在群组权限group ` 、 ` 其他用户权限other `。
分别对应各个权限对这个文件的权限。
权限也分为 ` 读r ` 、` 写w ` 、 ` 执行x ` 三种。
所以3*3=9, 对应 ` drwxr-xr-x ` 后面九个字符。
最前面的字符, 则对应着文件的类型, Linux不是以文件后缀名来确定文件类型的。
1. 第1位是文件类型

| 文件类型 | 说明 |
| :----: | :----: |
| d | Directory、目录、文件夹 |
| - | 普通文件 |
| l | 软链接文件, Link快捷方式 |
| b | 区块(block)文件, 储存数据, 以提供系统随机存取的接口设备 |
| c | 字符(character)设备文件, 一些串行端口的接口设备, 例如键盘、鼠标(一次性读取装置) |
| s | 数据接口文件(sockets), 通常被用在网络上的数据传输 |
| f | 数据输送文件(FIFO, pipe), 解决多个程序同时存取一个文件所造成的错误问题 |

2. 后面九个字符, 三个为一组, 分别是 ` 用户权限user ` 、 ` 用户所在群组权限group ` 、 ` 其他用户权限other `。每一组有三个权限 ` 读r ` 、` 写w ` 、 ` 执行x `, 如果没有权限, 则用 ` - ` 代替。

3. 比如 ` drwxr-xr-x ` , 说明这是一个目录, 文件所有者有读、写、执行的权限。文件拥有者所在的群组有读、执行权限, 没有写的权限。不在文件拥有者所在群组的用户具有读、执行权限, 没有写的权限。

# 修改权限
- 修改群组change group, ` chgrp [选项] 群组名 文件名 `, 群组必须在 ` /etc/group ` 中存在。 使用 ` -R ` 可以递归recursive修改。
- 修改拥有者change owner, ` chown [选项] 用户名 文件名 `, 用户必须在 ` /etc/passwd ` 中存在。 使用 ` -R ` 可以递归recursive修改。

下面介绍修改权限的两种方法。
## 数字形式
经常可以看到 ` chmod [选项] 770 文件名 `这种形式。 使用 ` -R ` 可以递归recursive修改。
Linux将读、写、执行的权限赋予了权值。` 读4 ` 、 ` 写2 ` 、 ` 执行1 `。
为什么这样赋值, 这和二进制有关。1为001, 2为010, 4为100。组合后不会产生冲突。
比如说` drwxr-xr-x `
1.  ` rwx ` , 读写执行, r4+w2+x1=7
2. ` r-x ` , 读执行, r4+x1=5

所以修改权限的命令为 ` chmod 755 文件名 `。

## 字符形式
有人说算术记不住, Linux还提供了字符的形式赋予权限。
范围有 ` 用户u `、` 用户所在群组g `、` 其他用户o `、` 以上三个a `。
权限有 ` 读r ` 、` 写w ` 、 ` 执行x `。
操作运算符有 ` 新增+ `、` 移除- ` 、 ` 赋予= `。
比如，要设定 ` drwx------ ` 为 ` dr-xr-xr-x `。
则使用` chomd u-w,g+rx,o=rx 文件名`

# 默认权限
使用`umask`命令查看或修改默认权限。
`umask`命令是临时修改重启失效, 永久修改在`/etc/profile`文件中修改。
```sh
[ahao@localhost ~]$ umask 
0002
[ahao@localhost tmp]$ touch file
[ahao@localhost tmp]$ mkdir dir
[ahao@localhost tmp]$ ll
总用量 2
drwxrwxr-x. 2 ahao ahao   6 11月  4 16:17 dir
-rw-rw-r--. 1 ahao ahao   0 11月  4 16:16 file
```
这里的`0002`的第一位代表特殊权限, 后三位代表读写执行的权限掩码。
先看后3位。

1. 文件默认权限最大为`666`, 也就是`rw-rw-rw-`, 不能被执行。出于安全性考虑。
2. 目录默认权限最大为`777`, 也就是`rwxrwxrwx`, 可以被执行, 也就是进入目录。
3. umask权限用来和最大权限换算成字母(二进制)后进行相减运算。

```
比如文件默认最大权限为666, umask为022
换算成字母, rw-rw-rw- 减去 000010010 得到 110100100

比如文件默认最大权限为666, umask为033
换算成字母, rw-rw-rw- 减去 ----wx-wx 得到 rw-r--r--
```

特殊权限请参考另一篇文章


# 参考资料
- [鸟哥的Linux私房菜 - 第六章、Linux 的文件权限与目录配置](http://cn.linux.vbird.org/linux_basic/0210filepermission_2.php)
