---
title: Linux权限管理之ACL权限
url: ACL_permissions_for_Linux_rights_management
tags:
  - Linux
categories:
  - Linux
date: 2017-12-06 23:18:45
---
# 前言
ACL权限 Access Control List
适用于当一个用户不满足所有者`owner`, 所属组`group`, 其他人`other`的情况。
比如一个家庭账本权限为`-rwxrwx---`, 所有者`owner`是我, 所属组`group`是直系亲属, 其他人`other`是陌生人。
现在三姑六婆想阅读这个家庭账本, 要求权限为`r--`, 不满足拥有者(我), 所属组(直系亲属), 其他人(陌生人), 这时候就是使用ACL权限的时候。

<!-- more -->

# 开启ACL权限
执行以下`shell`脚本, 查看是否已经开启了`ACL`权限。
```sh
#!/bin/bash
[[ $UID != "0" ]] && echo "you must be root" && exit 1;

filesystem=$(mount | grep " / " | cut -d " " -f 5)

if [[ ${filesystem} == "ext3" ]];then
    /sbin/dumpe2fs -h /dev/sda2 | grep "acl"
    [[ $? == "0" ]] && echo "enabled acl" || echo "disabled acl"
fi
```

一般默认开启, 如果没有开启, 进行以下配置即可
```sh
# 1. 临时配置, 重新挂载/根目录, 加入ACL权限
[ahao@localhost ~]$ mount -o remount,acl /
# 2. 永久配置, 写入/etc/fstab文件, 重启生效
[root@localhost ~]# vim /etc/fstab 
LABEL=/                 /                       ext3    defaults,acl        1 1
```

# 查看和设置文件ACL权限
设置ACL权限用`setfacl -m [u|g]:[用户名|组名]:权限 文件名`命令。
查看ACL权限用`getfacl 文件名`

| 选项 | 说明 | 使用 |
|:----:|:----:|:----:|
| m |     设置ACL权限 | setfacl -m [u&#124;g]:[用户名&#124;组名]:权限 文件名 |
| x | 删除指定ACL权限 | setfacl -x [u&#124;g]:[用户名&#124;组名] 文件名 |
| b | 删除全部ACL权限 | setfacl -b 文件名 |
| d | 设定默认ACL权限(子文件继承目录ACL权限) | setfacl -m d:[u&#124;g]:[用户名&#124;组名]:权限 文件名 |
| k | 删除默认ACL权限(子文件继承目录ACL权限) | setfacl -m |
| R | 递归设置ACL权限(容易给文件x权限) | setfacl -m [u&#124;g]:[用户名&#124;组名]:权限 -R 目录名 |

这是一个例子。
```sh
# 1. 创建权限为drwxrwx---, 用户和用户组为root的dir目录
[root@localhost ~]# mkdir ~ahao/dir 
[root@localhost ~]# chmod 770 ~ahao/dir
[root@localhost ~]# ll ~ahao
总用量 0
drwxrwx---. 2 root root 6 11月  4 22:32 dir

# 2. 操作1: ahao用户尝试进入dir目录失败, 权限不足
[ahao@localhost ~]$ cd dir
-bash: cd: dir: 权限不够

# 3. root用户设置ACL权限, 给ahao用户赋予rx权限
[root@localhost ~]# setfacl -m u:ahao:rx ~ahao/dir
[ahao@localhost ~]$ ll
总用量 0
drwxrwx---+ 2 root root 6 11月  4 22:32 dir

# 4. 操作2: ahao用户尝试进入dir目录成功, dir的+权限位代表ACL权限
[ahao@localhost ~]$ cd dir
[ahao@localhost dir]$ # 成功进入dir目录 

# 5. 操作3: 查看ACL权限
[ahao@localhost dir]$ getfacl ~ahao/dir/ 
getfacl: Removing leading '/' from absolute path names
# file: home/ahao/dir/
# owner: root
# group: root
user::rwx
user:ahao:r-x # ACL权限
group::rwx
mask::rwx
other::---
```

# mask掩码
上面的例子在使用`getfacl dir`之后, 可以看到有一项是`mask`。
这个和默认权限`umask`差不多, 也是一个权限掩码, 表示所能赋予的权限最大值。
这里的`mask`和`ACL权限`进行`&与`运算, 得到的才是真正的`ACL权限`。
用人话讲, 就是
> 你考一百分是因为实力只有一百分
> 我考一百分是因为总分只有一百分

`mask`限制了权限的最高值。
```sh
# 1. 修改ACL权限mask为r-x
[root@localhost ~]# setfacl -m m:rx ~ahao/tmp/av 
[root@localhost ~]# getfacl ~ahao/tmp/av
getfacl: Removing leading '/' from absolute path names
# file: home/ahao/tmp/av
# owner: root
# group: root
user::rwx
group::r-x
mask::r-x # 修改ACL权限mask为r-x
other::---

# 2. 为用户ahao添加ACL权限rwx
[root@localhost ~]# setfacl -m u:ahao:rwx ~ahao/tmp/av/ 
[root@localhost ~]# getfacl ~ahao/tmp/av
getfacl: Removing leading '/' from absolute path names
# file: home/ahao/tmp/av
# owner: root
# group: root
user::rwx
user:ahao:rwx
group::r-x
mask::rwx # 注意, 这里的mask掩码会改变, 因为赋予的ACL权限大于mask
other::---

# 3. 修改ACL权限mask为r-x
[root@localhost ~]# setfacl -m m:rx ~ahao/tmp/av
[root@localhost ~]# getfacl ~ahao/tmp/av
getfacl: Removing leading '/' from absolute path names
# file: home/ahao/tmp/av
# owner: root
# group: root
user::rwx
user:ahao:rwx			#effective:r-x # 这里会提示真实的ACL权限为r-x
group::r-x
mask::r-x # 这里mask不会再改变
other::---
```

1. ` mask ` 会限制 ` ACL ` 权限的最大值。
2. 赋予` ACL ` 权限大于 ` mask ` 的时候, 会将 ` mask ` **撑大**。
