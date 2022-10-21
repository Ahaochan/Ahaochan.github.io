---
title: 文件特殊权限SUID和SGID和SBIT
url: File_permissions_SUID_and_SGID_and_SBIT
tags:
  - Linux
categories:
  - Linux
date: 2019-03-27 21:21:46
---
# 前言
特殊权限尽量少修改! 不安全!
(很久以前写的一篇学习笔记, 一直没有整理

# 作用
给执行该文件的用户临时赋予另一个用户(组)的权限。

<!-- more -->

比如**设置密码**
```bash
ll /etc/shadow /usr/bin/passwd 
----------. 1 root root  1232 10月  6 05:47 /etc/shadow
-rwsr-xr-x. 1 root root 27832 6月  10 2014 /usr/bin/passwd
```
`/etc/shadow`文件只能被`root`用户修改。
但是借助`passwd`命令, 普通用户可以临时变成`root`来执行这个`passwd`命令, 
进而修改`/etc/shadow`文件。

# 切换用户 SUID
只有可以执行的二进制程序才能设定`SUID`权限。
`SUID`可以看成是`Switch User ID`~~(一个瞎猜）~~, 就是切换用户`ID`.

1. 创建两个文件`file1`和`file2`
2. 添加`SUID`权限, 或者`chmod u+s file`
3. 取消`SUID`权限, 或者`chmod u-s file`

```bash
# 1. 创建两个文件
touch file1 file2 && ll
# -rw-rw-r--. 1 ahao ahao 0 11月 21 21:13 file1
# -rw-rw-r--. 1 ahao ahao 0 11月 21 21:13 file2

# 2. 添加SUID权限, 或者chmod u+s  file
chmod 4755 file1 && chmod 4655 file2 && ll
# -rwsr-xr-x. 1 ahao ahao 0 11月 21 21:13 file1
# -rwSr-xr-x. 1 ahao ahao 0 11月 21 21:13 file2

# 3. 取消SUID权限, 或者chmod u-s  file
chmod 0755 file1 && chmod 0655 file2 && ll
# -rwxr-xr-x. 1 ahao ahao 0 11月 21 21:13 file1
# -rw-r-xr-x. 1 ahao ahao 0 11月 21 21:13 file2

```
可以看到`x`执行权限的位置被`s`替换了。
`4755`和`4655`的区别在于文件本身有没有`x`执行权限。
并且可以得知`s=S+x`, 并且注意!!! 大写`S`是没有意义的。
只有小写`s`才能被执行, 才能正确设定`SUID`权限。

# 切换用户组 SGID
和`SUID`一样, 区别在于用户会临时赋予文件所属用户组`group`的身份, 而不是用户`user`身份。~~Switch Group ID~~

比如**`locate`命令**
```bash
ll /usr/bin/locate /var/lib/mlocate/mlocate.db 
# -rwx--s--x. 1 root slocate   40512 11月 21 23:21 /usr/bin/locate
# -rw-r-----. 1 root slocate 3678432 11月 21 23:21 /var/lib/mlocate/mlocate.db
```
`/var/lib/mlocate/mlocate.db`文件只能被`slocate`组查看。
但是借助`locate`命令, 普通用户可以临时变成`slocate`来执行这个`locate`命令, 
进而查看`/var/lib/mlocate/mlocate.db`文件。

除了和`SUID`差不多的功能外。
`SGID`对目录还有另一个功能。
就是**进入该目录后**, 用户的用户组会变成**SGID对应的用户组**。

1. `root`用户创建`test`目录并赋予`777`权限
2. `ahao`用户在`test`目录下创建`file1`
3. `root`用户为`test`目录赋予`SGID`权限
4. `ahao`用户在赋予`SGID`的`test`目录下创建`file2`

```bash
# 1. root用户创建test目录并赋予777权限
mkdir ~ahao/test && chmod 777 ~ahao/test && ll -d ~ahao/test
# drwxrwxrwx. 2 root root 6 11月 21 23:39 /home/ahao/test

# 2. ahao用户在test目录下创建file1
su - ahao
touch ~ahao/test/file1 && ll ~ahao/test
# -rw-rw-r--. 1 ahao ahao 0 11月 21 23:43 file1

# 3. root用户为test目录赋予SGID权限, 或者chmod g+s  file
su -
chmod 2777 ~ahao/test && ll -d ~ahao/test/
# drwxrwsrwx. 2 root root 19 11月 21 23:43 /home/ahao/test/


# 4. ahao用户在赋予SGID的test目录下创建file2
su - ahao
touch ~ahao/test/file2 && ll ~ahao/test
# -rw-rw-r--. 1 ahao ahao 0 11月 21 23:43 file1
# -rw-rw-r--. 1 ahao root 0 11月 21 23:45 file2
```
可以看到赋予`SGID`后, `ahao`用户创建的`file2`的所属组是`root`。

# 防止被删除 sticky bit ( SBIT )
除了`user`的`SUID`、`group`的`SGID`外, 还有`other`的`sticky bit`。

`sticky bit`有两个要求
1. 只对目录有效。
1. 文件权限为`rwxrwxrwx`, 也就是`777`的权限。
比如`/tmp`目录。

那么任何用户都能对目录下的文件进行读写执行操作, 这是很不安全的。
比如一个目录, 允许用户(`other`)创建文件(写权限), 拥有了写权限的用户也同样拥有了删除权限。
也就是说在`777`权限的目录下, `A`用户创建的文件可能被`B`用户删除。
`sticky bit`就是为了解决这个问题。
赋予目录`sticky bit`后。
1. 只有`root`有删除权限。
2. 其他用户只能删除自己创建的文件。
3. 其他用户拥有写权限。

下面举个例子
1. `root`用户创建`test`目录并赋予`777`权限。
2. `root`用户创建`file`文件。
3. `ahao`用户删除`file`文件成功, 因为`ahao`用户对`test`目录有w写权限。
4. `root`用户对`test`目录赋予`sticky bit`权限。
5. `root`用户创建`file`文件。
6. `ahao`用户删除`file`文件失败, 即使`ahao`用户对`test`目录有w写权限。

```bash
# 1. root用户创建test目录并赋予777权限
mkdir ~ahao/test && chmod 777 ~ahao/test/ && ll -d ~ahao/test/
# drwxrwxrwx. 2 root root 6 11月 22 23:23 /home/ahao/test/

# 2. root用户创建file文件
echo "hello" > ~ahao/test/file && ll ~ahao/test/
# -rw-r--r--. 1 root root 6 11月 22 23:26 file

# 3. ahao用户删除file文件成功, 因为ahao用户对test目录有w写权限
su - ahao && rm -rf ~ahao/test/file && ll ~ahao/test/

# 4. root用户对test目录赋予sticky bit权限
su -
# chmod 0777 ~ahao/test/ # 取消sticky bit, 或chmod o-t ~ahao/test/
chmod 1777 ~ahao/test/ # 赋予sticky bit, 或chmod o+t ~ahao/test/
ll -d ~ahao/test/
drwxrwxrwt. 2 root root 6 11月 22 23:27 /home/ahao/test/

# 5. root用户创建file文件
echo "hello" > ~ahao/test/file && ll ~ahao/test/
# -rw-r--r--. 1 root root 6 11月 22 23:32 file

# 6. ahao用户删除file文件失败, 即使ahao用户对test目录有w写权限
su - ahao
rm -rf ~ahao/test/file
# rm: 无法删除"/home/ahao/test/file": 不允许的操作
```
如果不能删除, 那我能不能覆盖掉呢? `echo '' > file`
我在`Ubuntu`尝试了不能, 但是以前在`CentOS`试过好像可以.

# 检查系统新增的SUID和SGID文件
```bash
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
