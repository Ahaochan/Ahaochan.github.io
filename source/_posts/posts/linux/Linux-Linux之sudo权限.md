---
title: Linux之sudo权限
url: sudo_permissions_of_Linux
tags:
  - Linux
categories:
  - Linux
date: 2018-02-03 17:17:05
---
# 前言
sudo权限, 是可以临时把用户变成另一个用户(比如root)去执行某个命令。

<!-- more -->

# 添加sudo权限

使用`visudo`命令。即可修改`/etc/sudoers`文件。
切换到最后一行。输入命令即可。
格式如下
```
用户名  允许sudo的远程ip=(可使用的身份) 授权命令(绝对路径)
%组名   允许sudo的远程ip=(可使用的身份) 授权命令(绝对路径)
```

比如`shutdown -r now`重启命令, 不能被普通用户执行。
现在要赋予`ahao`用户重启服务器的权限。
命令越详细, 权限越小。最好写绝对路劲。
```
ahao    ALL=(ALL)       /sbin/shutdown -r now
```
这里的`ALL=(ALL)`的意思是

1. 左边的ALL, 表示被管理的主机的地址, 即是哪个**远程主机**或**ip**登录的这台服务器。
2. 右边的ALL, 表示用户可使用的身份, **省略的话会赋予root权限**。

下面是个简单的例子
```bash
# 1. 临时切换为 root , 执行 visudo
[ahao@localhost ~]$ su -c "/usr/sbin/visudo" root
    ahao    ALL=(ALL)       /sbin/shutdown -r now
# 2. 查看可用sudo命令
[ahao@localhost ~]$ sudo -l 
用户 ahao 可以在该主机上运行以下命令：
    (ALL) /sbin/shutdown -r now
# 3. 普通用户执行sudo赋予的命令
[ahao@localhost ~]$ sudo /sbin/shutdown -r now 

# 4. root用户可以随意切换用户, 随意执行sudo命令
# 下面root以user1的身份创建/tmp/hello文件
[root@localhost ~]# sudo -u user1 touch /tmp/hello
[root@localhost ~]# ls -l /tmp/hhh 
-rw-r--r-- 1 user1 user1 0 10-18 08:29 /tmp/hello
```

# sudo支持正则、取反

添加以下规则
```
ahao    ALL=/usr/sbin/useradd # 赋予用户创建角色的权限
ahao    ALL=/usr/bin/passwd   # 赋予用户修改密码的权限, 危险!!
```
为`ahao`用户添加**创建角色**的权限, 还要添加**修改密码**的权限, 才能真正使用创建的用户。
但是如果使用上述规则, 则会允许`ahao`执行`/usr/bin/passwd root`修改`root`的密码, 这样很**不安全**。

修改为以下规则
```
ahao    ALL=/usr/sbin/useradd
ahao    ALL=/usr/bin/passwd [A-Za-z]*, !/usr/bin/passwd "", !/usr/bin/passwd root
# 使用正则表达式限定用户名为字母的用户, 使用 ! 取反, 不允许修改root的密码
```

# sudo的别名
调用`visudo`命令, 插入别名, 别名名称必须大写, 多个值用逗号分隔。
- 用户别名: `User_Alias MYUSER = user1, user2, user3`
- 主机别名: `Host_Alias MYHOST = 192.168.0.1, 192.168.0.2`
- 命令别名: `Cmnd_Alias MYCMD = !/usr/bin/passwd, /usr/bin/passwd [A-Za-z]*, !/usr/bin/passwd root`

# 警告
`sudo`很容易造成不安全的行为, 如同上面的修改密码的权限。
所以在使用的时候一定要注意安全问题。
