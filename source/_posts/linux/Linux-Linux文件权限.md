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
所以`3*3=9`, 对应 ` drwxr-xr-x ` 后面九个字符。
最前面的字符, 则对应着文件的类型, `Linux`不是以文件后缀名来确定文件类型的。
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

比如 ` drwxr-xr-x `
说明这是一个目录, 文件所有者有读、写、执行的权限。
文件拥有者所在的群组有读、执行权限, 没有写的权限。
不在文件拥有者所在群组的用户具有读、执行权限, 没有写的权限。

# 普通权限

## 修改群组和拥有者
- 修改群组change group, ` chgrp [选项] 群组名 文件名 `, 群组必须在 ` /etc/group ` 中存在。 使用 ` -R ` 可以递归recursive修改。
- 修改拥有者change owner, ` chown [选项] 用户名 文件名 `, 用户必须在 ` /etc/passwd ` 中存在。 使用 ` -R ` 可以递归recursive修改。

## 修改文件权限(数字形式)
经常可以看到 ` chmod [选项] 770 文件名 `这种形式。 使用 ` -R ` 可以递归recursive修改。
`Linux`将读、写、执行的权限赋予了权值。` 读4 ` 、 ` 写2 ` 、 ` 执行1 `。
为什么这样赋值, 这和二进制有关。`1`为`001`, `2`为`010`, `4`为`100`。组合后不会产生冲突。
比如说` drwxr-xr-x `
1.  ` rwx ` , 读写执行, `r+w+x=4+2+1=7`
2. ` r-x ` , 读执行, `r+x=4+1=5`

所以修改权限的命令为 ` chmod 755 文件名 `。

## 修改文件权限(字符形式)
有人说算术记不住, Linux还提供了字符的形式赋予权限。
范围有 ` 用户u `、` 用户所在群组g `、` 其他用户o `、` 以上三个a `。
权限有 ` 读r ` 、` 写w ` 、 ` 执行x `。
操作运算符有 ` 新增+ `、` 移除- ` 、 ` 赋予= `。
比如，要设定 ` drwx------ ` 为 ` dr-xr-xr-x `。
则使用` chomd u-w,g+rx,o=rx 文件名`

# 默认权限
使用`umask`命令查看或修改默认权限掩码。默认权限掩码影响创建文件时赋予的默认权限。
`umask`命令是临时修改重启失效, 永久修改在`/etc/profile`文件中修改。
```sh
[ahao@localhost ~]$ umask 
0002
[ahao@localhost tmp]$ touch file1
[ahao@localhost tmp]$ mkdir dir
[ahao@localhost tmp]$ umask 0022 && touch file2
[ahao@localhost tmp]$ ll
总用量 2
drwxrwxr-x. 2 ahao ahao   6 11月  4 16:17 dir
-rw-rw-r--. 1 ahao ahao   0 11月  4 16:16 file1
-rw-r--r--. 1 ahao ahao   0 11月  4 16:16 file2
```
这里的`0002`的第一位代表特殊权限(稍后介绍), 后三位代表读写执行的权限掩码。
先看后`3`位。

1. 文件默认权限最大为`666`, 也就是`rw-rw-rw-`, 不能被执行。出于安全性考虑。
2. 目录默认权限最大为`777`, 也就是`rwxrwxrwx`, 可以被执行, 也就是进入目录。
3. `umask`权限用来和最大权限换算成字母后进行相减运算, `-`位不允许再减。

```text
比如文件默认最大权限为666, umask为022
换算成字母, 666(rw-rw-rw-) 减去 022(----w--w-) 得到默认权限 644(rw-r--r--)

比如文件默认最大权限为666, umask为033
换算成字母, 666(rw-rw-rw-) 减去 033(---wx-wx-) 得到默认权限 644(rw-r--r--)
```
所以可以看到上面的运算, 不能简单的使用数字运算, 需要转为字母进行运算, 或者进行二进制的不借位减法。

# 特殊权限(不安全)

**特殊权限尽量少修改! 不安全!**
给执行该文件的用户临时赋予另一个用户(组)的权限, 比如`root`权限。
特殊权限也有`421`的值, `4`为`SUID`, `2`为`SGID`, `1`为`SBIT`。


## SUID(SET USER ID)

1. `SUID`权限仅对二进制程序有效
2. 执行者对于该程序需要具有`x`的可执行权限
3. 本权限仅在执行该程序的过程中有效
4. 执行者将具有该程序**所有者**的权限

比如**设置密码**
```sh
[ahao@localhost tmp]$ ll /etc/shadow /usr/bin/passwd 
----------. 1 root root  1232 10月  6 05:47 /etc/shadow
-rwsr-xr-x. 1 root root 27832 6月  10 2014 /usr/bin/passwd
```
`/etc/shadow`文件只能被`root`用户修改。
但是执行`passwd`二进制文件的普通用户, 可以临时变成`passwd`拥有者`root`, 来修改`/etc/shadow`文件。
```sh
# 1. 创建两个文件
[ahao@localhost tmp]$ touch file1 file2
[ahao@localhost tmp]$ ll
总用量 0
-rw-rw-r--. 1 ahao ahao 0 11月 21 21:13 file1
-rw-rw-r--. 1 ahao ahao 0 11月 21 21:13 file2

# 2. 创建脚本打印文件, 添加SUID权限, 或者chmod u+s  file
[ahao@localhost tmp]$ chmod 4755 file1 
[ahao@localhost tmp]$ chmod 4655 file2
[ahao@localhost tmp]$ ll
总用量 0
-rwsr-xr-x. 1 root root 0 11月  6 23:53 file1
-rwSr-xr-x. 1 root root 0 11月  6 23:54 file2

# 3. 取消SUID权限, 或者chmod u-s  file
[ahao@localhost tmp]$ chmod 0755 file1
[ahao@localhost tmp]$ chmod 0655 file2
```
可以看到`x`执行权限的位置被`s`替换了。
`4755`和`4655`的区别在于文件本身有没有`x`执行权限。
并且可以得知`s=S+x`。大写`S`是没有意义的。
只有小写`s`才能正确设定`SUID`权限。

## SGID(SET GROUP ID)
和`SUID`一样, 区别在于用户会临时赋予文件所属用户组`group`的身份, 而不是用户`user`身份。
1. `SGID`对二进制程序有用
2. 程序执行者对该程序需具备`x`权限
3. 执行者在执行过程中会获得该程序**用户组**的支持

比如**locate命令**
```sh
[root@localhost ~]# ll /usr/bin/locate /var/lib/mlocate/mlocate.db 
-rwx--s--x. 1 root slocate   40512 11月  5 2016 /usr/bin/locate
-rw-r-----. 1 root slocate 3678432 11月 21 23:21 /var/lib/mlocate/mlocate.db
```
`/var/lib/mlocate/mlocate.db`文件只能被`slocate`组查看。
但是借助`locate`命令, 普通用户可以临时变成`slocate`**(`s`在group权限的范围)**来查看`/var/lib/mlocate/mlocate.db `文件。

除了和`SUID`差不多的功能外。
`SGID`对目录还有另一个功能。
就是**进入该目录后**, 用户的用户组会变成**SGID对应的用户组**。
```sh
# 1. root用户创建test目录并赋予777权限
[root@localhost ~]# mkdir ~ahao/test
[root@localhost ~]# chmod 777 ~ahao/test
[root@localhost ~]# ll -d ~ahao/test
drwxrwxrwx. 2 root root 6 11月 21 23:39 /home/ahao/test
[root@localhost ~]# exit

# 2. ahao用户在test目录下创建file1
[ahao@localhost ~]$ touch ~ahao/test/file1
[ahao@localhost ~]$ ll ~ahao/test/file1
总用量 0
-rw-rw-r--. 1 ahao ahao 0 11月 21 23:43 file1

# 3. root用户为test目录赋予SGID权限
[ahao@localhost test]$ su -c "chmod 2777 ~ahao/test" root
[ahao@localhost test]$ ll -d ~ahao/test/
drwxrwsrwx. 2 root root 19 11月 21 23:43 /home/ahao/test/
      ^

# 4. ahao用户在赋予SGID的test目录下创建file2
[ahao@localhost test]$ touch file2
[ahao@localhost test]$ ll
总用量 0
-rw-rw-r--. 1 ahao ahao 0 11月 21 23:43 file1
-rw-rw-r--. 1 ahao root 0 11月 21 23:45 file2
```
可以看到赋予`SGID`后, `ahao`用户创建的`file2`的所属组是`root`。

## SBIT(sticky bit)
除了`user`的`SUID`、`group`的`SGID`外, 还有`other`的`sticky bit`。

`sticky bit`有两个要求
1. 只对目录有效。
1. 文件权限为`rwxrwxrwx`, 也就是`777`的权限。
比如`/tmp`目录。

那么任何用户都能对目录下的文件进行读写执行操作, 这是很不安全的。
比如一个目录, 允许用户(`other`)创建文件(写权限), 拥有了写权限的用户也同样拥有了删除权限。
也就是说在`777`权限的目录下, A用户创建的文件可能被B用户删除。
`sticky bit`就是为了解决这个问题。
赋予目录`sticky bit`后。
1. 只有`root`有删除权限。
2. 其他用户只能删除自己创建的文件。
3. 其他用户拥有写权限。

下面举个例子
```sh
# 1. root用户创建test目录并赋予777权限
[root@localhost ~]# mkdir ~ahao/test
[root@localhost ~]# chmod 777 ~ahao/test/
[root@localhost ~]# ll -d ~ahao/test/
drwxrwxrwx. 2 root root 6 11月 22 23:23 /home/ahao/test/

# 2. root用户创建file文件
[root@localhost ~]# echo "hello" > ~ahao/test/file
[root@localhost ~]# ll ~ahao/test/
总用量 4
-rw-r--r--. 1 root root 6 11月 22 23:26 file

# 3. ahao用户删除file文件成功, 因为ahao用户对test目录有w写权限
[ahao@localhost ~]$ rm -rf ~ahao/test/file

# 4. root用户对test目录赋予sticky bit权限
[root@localhost ~]# chmod 0777 ~ahao/test/ # 取消sticky bit, 或chmod o-t ~ahao/test/
[root@localhost ~]# chmod 1777 ~ahao/test/ # 赋予sticky bit, 或chmod o+t ~ahao/test/
[root@localhost ~]# ll -d ~ahao/test/
drwxrwxrwt. 2 root root 6 11月 22 23:27 /home/ahao/test/
         ^

# 5. root用户创建file文件
[root@localhost ~]# echo "hello" > ~ahao/test/file
[root@localhost ~]# ll ~ahao/test/
总用量 4
-rw-r--r--. 1 root root 6 11月 22 23:32 file

# 6. ahao用户删除file文件失败, 即使ahao用户对test目录有w写权限
[ahao@localhost ~]$ rm -rf ~ahao/test/file
rm: 无法删除"/home/ahao/test/file": 不允许的操作
```

## 检查系统新增的SUID和SGID文件
特殊权限太危险了, 当有人使用特殊权限, 需要及时的发现。
将以下脚本加入定时任务中, 即可及时发现新增的特殊权限文件。
```sh
# 1. 先查找所有拥有SUID(4)和SGID(2)的文件
find / -perm -4000 -o -perm -2000 > /tmp/suid.list

# 2. 编写Shell脚本
#!/bin/bash
# 2.1 查找所有拥有SUID(4)或SGID(2)的文件, 并保存到临时文件suid.check中
find / -perm -4000 -o -perm -2000 > /tmp/suid.check

for line in $(cat /tmp/suid.check)
do
    # 2.3 遍历临时文件suid.check中的记录, 和最初查找到的文件/tmp/suid.list进行比较。
    grep $line /tmp/suid.list > /dev/null
    # 2.4 不存在则写入log文件中
    if [ "$?" != "0" ];then
        echo "$i isn't in listfile! " >> /tmp/suid_log_$(date +%F)
    fi
done
rm -rf /tmp/suid.check
echo "/tmp/suid_log_$(date +%F)"
cat /tmp/suid_log_$(date +%F)
```

# 隐藏权限 chattr
`SBIT`只是防止删除的情况。
但是不排除被篡改文件的情况出现。

如果用户对文件有`w`写权限, 即使加了`SBIT`权限, 用户依然可以把文件内容清空, 虽然没删除, 但也和删除的情况差不多了。

如果对**文件**设置`i`属性, 那么不允许对文件进行删除、改名, 也不能添加和删除数据; 
如果对**目录**设置`i`属性, 那么只能修改目录下文件的数据, 但不允许建立和删除文件。

如果对**文件**设置`a`属性, 那么只能在文件中增加数据, 但是不能删除也不能修改数据;
如果对**目录**设置`a`属性, 那么只允许目录中建立和修改文件, 但是不允许删除。

```sh
# 1. 创建隐藏权限文件
[root@localhost ~]# touch ~ahao/test/file1
[root@localhost ~]# chattr +i ~ahao/test/file1 
[root@localhost ~]# lsattr ~ahao/test/file1 
----i----------- /home/ahao/test/file1

# 2. root也不能修改文件
[root@localhost ~]# echo "hello" >> ~ahao/test/file1 
-bash: /home/ahao/test/file1: 权限不够

# 3. 去掉隐藏权限
[root@localhost ~]# chattr -i ~ahao/test/file1 
```

# 参考资料
- [鸟哥的Linux私房菜 - 第六章、Linux 的文件权限与目录配置](http://cn.linux.vbird.org/linux_basic/0210filepermission_2.php)
