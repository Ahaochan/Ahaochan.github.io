---
title: Linux用户管理之配置文件
url: configuration_file_of_user_management 
tags:
  - Linux
categories:
  - Linux
date: 2017-12-06 23:16:37
---

# 前言
Linux 用户管理涉及到几个文件
1. `/etc/passwd` 存储用户账号信息
2. `/etc/shadow` 存储用户密码信息
3. `/etc/group`存储用户组信息
3. `/etc/gshadow`存储用户组管理员密码信息

<!-- more -->

# 文件结构
## /etc/passwd文件结构
`/etc/passwd`是存储账号的文件。
```sh
[root@localhost ~]# cat /etc/passwd | grep -E "ahao|root"
ahao:x:500:500:ahao:/home/ahao:/bin/bash
root:x:0:0:root:/root:/bin/bash
```
以冒号分割, 分为7个部分。
1. ahao: 用户名。
1. x: 以前存储密码的字段, 现在改为`/etc/shadow`文件。
1. 500: 第一个500是`uid`用户id。
1. 500: 第二个500是`gid`群组id, 在`/etc/group`文件中。
1. ahao: 这个是用户信息说明栏, 用来解释这个账号的意义。
1. /home/ahao: 家目录
1. /bin/bash: 默认使用`Bash`

用户uid的编码规则

| id 范围 | 该 ID 使用者特性 |
|:---------:|:-----------------------:|
| 0          | root用户, 系统管理员 |
| 1~99  | 系统id, 由 distributions 自行创建的系统账号, 启动系统服务使用该账号 |
| 100~499 | 系统id, 若用户有系统账号需求时, 可以使用的账号UID, 启动系统服务使用该账号 |
| 500~65535 | 可登陆账号, 一般用户使用 |


## /etc/shadow 文件结构
`/etc/shadow`是存储密码的文件。
```sh
[root@localhost ~]# cat /etc/shadow | grep -E "ahao|root"
ahao:$1$eoG3CKlq$D8deyAR.qvEws9kA5pFLd1:17431:0:99999:7:::
root:$1$zQeO.jbw$ZyXVaa7yPIb2K/3BopdSa.:17431:0:99999:7:::
```
以冒号分割, 分为8个部分。
1. ahao: 用户名
1. `$1$eoG3CKlq$D8deyAR.qvEws9kA5pFLd1`: 加密后的密码
1. 17431: 最近改密码的日期距离1970年1月1日的天数。
1. 0: 只有0天后密码才能再次修改。
1. 99999: 必须在99999天后修改密码, 否则账号标记为过期。
1. 7: 警告该账号, 还有7天不修改密码的话, 账号就会过期。
1. null: 在账号标识为过期后, 还有null天宽限期可以登录该账号, 登录后会强制让用户修改密码。
1. null: 1970年1月1日的null天后账号失效, 和过期不同。
1. null: 保留字段, 暂时没用。

## /etc/group文件结构
`/etc/group`是存储用户组的文件。
```sh
[root@localhost ~]# cat /etc/group | grep -E "ahao|root"
root:x:0:root
ahao:x:500:
```
1. ahao: 用户组名, 在不指定用户组的情况下，创建用户并指定密码后会默认创建同名用户组。
1. x: 用户组密码, 改存储到`/etc/gshadow`文件。
1. 500: 用户组ID, 对应`/etc/passwd`第四个字段。
1. null: 用户组支持的账号, 一个账号可以有多个用户组, 比如`ahao`用户要加入`root`用户组, 则编辑为`root:x:0:root,ahao`即可。

## /etc/gshadow文件结构
`/etc/gshadow`是存储用户组密码的文件。
```sh
[root@localhost ~]# cat /etc/gshadow | grep -E "ahao|root"
root:::root
ahao:!!::
```
1. ahao: 用户组名, 在不指定用户组的情况下，创建用户并指定密码后会默认创建同名用户组。
1. !!: 用户组密码。**!**表示没有密码, 即没有用户组管理员。
1. null: 用户组管理员的账号。
1. null: 用户组的下属账号

# 命令操作

```sh
[root@localhost ~]# useradd user1 # 新增用户user1
[root@localhost ~]# passwd user1  # 设置user1的密码, 创建用户后必须设置密码才能登录。 

[root@localhost ~]# usermod -L user1  # 锁定user1的用户(仅改 /etc/shadow的密码部分)
[root@localhost ~]# usermod -U user1  # 解锁user1的用户(仅改 /etc/shadow的密码部分)

[root@localhost ~]# userdel -r user1 # 删除用户, -r连同家目录

[root@localhost ~]# groupadd -r oldGroup1 # 新增用户组oldGroup1, -r创建系统用户组, 即GID<500
[root@localhost ~]# groupmod -g 201 -n group1 oldGroup1 # 修改用户组oldGroup1的GID为201, 修改组名为group1
[root@localhost ~]# gpasswd group1 # 设置用户组group1的群组管理员密码

[root@localhost ~]# gpasswd -A user1 group1 # 设置用户user1为用户组group1的管理员
[user1@localhost ~]$ gpasswd -a user2 group1 # 群组管理员user1将用户user2加入用户组group1
[user1@localhost ~]$ gpasswd -d user2 group1 # 群组管理员user1将用户user2移出用户组group1
[root@localhost ~]# gpasswd -M user2 group1 # 用户root将用户user2加入用户组group1

[root@localhost ~]# groupdel group1 # 删除用户组group1
```
不指定其他选项的情况下, `useradd`和`passwd`命令默认完成以下步骤, 默认配置文件在`/etc/default/useradd`中。
1. `/etc/passwd`新增一行用户信息, 包括创建UID/GID/家目录等。
2. `/etc/shadow`新增一行密码信息。
3. `/etc/group` 新增一个和用户名同名的用户组。