---
title: Linux软件安装之RPM包详解
url: RPM_package_installation_of_Linux_software
tags: 
  - Linux软件安装
categories:
  - Linux
date: 2018-02-02 23:55:26
---
# 前言
`RPM`包管理员是在Linux下广泛使用的软件包管理器。

<!-- more -->

# 数据源
`RPM`包一般在系统光盘里就有。不同系统的`RPM`包在不同的路径下。
`CentOS5`在`CentOS`目录下。
```sh
# 1. 先装入系统安装光盘, 切换到 root 用户
[ahao@locathost /]$ su -
# 2. 挂载光盘到 /mnt/cdrom 目录, 目录需要手动创建
[root@locathost /]# mount -t auto /dev/cdrom /mnt/cdrom
# 3. 查看 RPM 包目录, 不同光盘的 RPM 包目录不同
[root@locathost /]# ll /mnt/cdrom/CentOS
# 4. 在用完之后记得卸载光盘
[root@locathost /]# umount /mnt/cdrom
```

# RPM包命名规则
这里以`Apache`的`httpd`包为例
```sh
[root@localhost /]# ll /mnt/cdrom/CentOS | grep 'httpd'
-rw-r--r-- 2 root root  1280858 2009-03-17 httpd-2.2.3-22.el5.centos.x86_64.rpm
```

| httpd    | 2.2.3    | 22           | el5.centos      | x86_64         | rpm         |
|:--------:|:--------:|:------------:|:---------------:|:--------------:|:-----------:|
| 软件包名 | 软件版本 | 软件发布次数 | 适合的Linux平台 | 适合的硬件平台 | rpm包扩展名 |

# RPM查询

包和包之间可能存在依赖关系, 比如**软件`A`**需要调用**软件`B`**, 那么安装**软件`A`**之前就必须安装**软件`B`**, 否则可能会出现找不到**软件`B`**的某个**函数**的问题。
这叫做**树形依赖**, 其他还有其他依赖。

1. 树形依赖: a -> b -> c, 安装c需要先安装b, 安装b需要先安装a, 卸载的时候要先卸载a, 再卸载b, 最后卸载c
1. 环形依赖: a -> b -> c -> a, 用一条命令同时安装, `rpm -ivh a b c`
1. 模块依赖: 依赖另一个包的某个so库文件模块, 查询模块对应的软件: [www.rpmfind.net](www.rpmfind.net)

以`httpd`包为例, 已安装的软件包在`/var/lib/rpm/`数据库中, 只用输入包名即可。
```sh
# 1. 安装httpd软件包, -i 安装, -v 显示详细信息, -h 显示进度, 
#    会发现安装失败, 需要解决依赖性问题, 将依赖的包依次安装即可
[root@localhost /]# rpm -ivh /mnt/cdrom/CentOS/httpd-2.2.3-22.el5.centos.x86_64.rpm 
# 2. 查询所有已安装的RPM包, -q 查询, -a 查询所有
[root@localhost /]# rpm -qa
# 3. 查询包信息, -i 包信息, -p 未安装的包
[root@localhost /]# rpm -qi httpd
[root@localhost /]# rpm -qip /mnt/cdrom/CentOS/httpd-2.2.3-22.el5.centos.x86_64.rpm 
# 4. 查询包所有文件安装位置
[root@localhost /]# rpm -ql httpd
[root@localhost /]# rpm -qlp /mnt/cdrom/CentOS/httpd-2.2.3-22.el5.centos.x86_64.rpm
# 5. 查询文件名属于哪个包
[root@localhost /]# rpm -qf /etc/httpd/
httpd-2.2.3-22.el5.centos
# 6. 升级httpd包, 除非是重大安全漏洞, 避免升级
[root@localhost /]# rpm -U httpd
# 7. 卸载http包, 需要解决依赖性问题
[root@localhost /]# rpm -e httpd
```

# RPM验证
有时候网络波动或网络攻击会导致文件缺失或者文件被植入木马等问题, 就需要验证下载下来的文件和RPM包的文件是否一致。

```sh
# 1. 修改 httpd 包的配置文件 httpd.conf, 随便添加几个字符
[root@localhost ~]# vim /etc/httpd/conf/httpd.conf
# 2. verify 校验RPM包中的文件, 发现被修改过了, S.5....T 对应表一, c 对应表二
[root@localhost ~]# rpm -V httpd
S.5....T  c /etc/httpd/conf/httpd.conf
```

| S(Size)  | M(Mode)            | 5(MD5)  | D(Device)    | L(Link)  | U(User)    | G(Group )  | T(mTime)     |
|:--------:|:------------------:|:-------:|:------------:|:--------:|:----------:|:----------:|:------------:|
| 文件大小 | 文件类型或文件权限 | MD5校验 | 设备主从代码 | 文件路径 | 文件所有者 | 文件所属组 | 文件修改时间 |

| c(config) | d(documentation) | g(ghost)            | L(license) | r(readme) |
|:---------:|:----------------:|:-------------------:|:----------:|:---------:|
| 配置文件  | 普通文件         | 不在RPM包的幽灵文件 | 授权文件   | 描述文件  |

```sh
# 3. 使用 rpm2cpio 将 rpm 包中转为 cpio, 再通过 cpio 提取其中的 ./etc/httpd/conf/httpd.conf 文件, 保存到 /tmp 目录下
# -i copy-in模式还原, -d 还原时自动新建目录, -v verbose 显示还原过程
[root@localhost ~]# cd /tmp
[root@localhost /tmp]# rpm2cpio /mnt/cdrom/CentOS/httpd-2.2.3-22.el5.centos.x86_64.rpm | cpio -idv ./etc/httpd/conf/httpd.conf
# 4. 覆盖被改变的 httpd.conf
[root@localhost /tmp]# cp /tmp/etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf
# 5. 再次校验RPM包, 发现没有异常, 只有时间被修改了
[root@localhost tmp]# rpm -V httpd
.......T  c /etc/httpd/conf/httpd.conf
```