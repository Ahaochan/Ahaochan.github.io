---
title: Linux命令提示符
url: Linux_command
tags:
  - Linux
categories:
  - Linux
date: 2016-07-14 22:04:06
---

# 命令提示符
## 用户及主机名:[root@localhost ~]
```shell
[root@localhost ~]#
```
<!-- more -->

`root`：当前登录用户
`localhost`：主机名
`~`：`/root`
`#`：超级用户
`$`：普通用户


## 查询目录中的内容：ls
`list`的缩写
```shell
ls -a    //显示全部文件，包括隐藏文件
ls -d    //查看目录属性
ls -l    //查询详细信息，ls -l可缩写为ll
ls -h    //显示为人们容易看的格式
ls -i    //显示inode，节点号
```

## 建立目录：mkdir
`make directories`的缩写
`-p`：递归创建
```shell
mkdir -p dir1/dir2    //创建dir1目录，并在dir之下创建dir2目录
```

## 切换目录：cd
`change directory`的缩写
按两次`tab`可以补全命令
```shell
cd ~   //进入当前用户的家目录
cd      //进入当前用户的家目录
cd -    //进入上次目录
cd ..   //进入上一级目录(相对路径使用)
cd .    //进入当前目录(相对路径使用)
```

## 查询所在目录位置：pwd
`print working directory`的缩写
```shell
pwd    //显示当前所在位置
```

## 删除文件或目录：rmdir和rm
`rm`是`remove`的缩写，常用
`rmdir`是`remove empty directories`的缩写，比rm更严格，只能删除空目录。
```shell
rm -rf [文件]    //-r删除目录，-f强制删除
```

## 复制命令：cp
`copy`的缩写
```shell
cp -r [原文件][新文件]    //-r复制目录
cp -p [原文件][新文件]    //-p连属性一起复制
cp -d [原文件][新文件]    //-d若源文件是链接文件，则复制链接属性
cp -a [原文件][新文件]    //-a上面三个一起选中，即-pdr
```

## 剪切或改名命令：mv
`move`的缩写，在相同目录下为改名，不同目录为剪切
```shell
mv [原文件名] [新文件名]
```

## 链接命令：ln
`link`的缩写，生成链接文件
硬链接可以看成复制，拥有相同的i节点和存储`block`块，不能跨分区，不能针对目录使用。删除原文件对硬链接文件没影响。
软链接可以看成快捷方式，拥有自己的`i`节点和存储`block`块，`block`块中存储原文件的`i`节点和文件名删除原文件对软链接文件有影响。
软链接文件权限固定为`lrwxrwxrwx`，真实权限要看原文件，创建软链接文件要写绝对路径。
```shell
link -s [原文件][目标文件]    //-s创建软链接(soft)
```

## 搜索命令：locate，find，whereis，whoami，whatis，which，grep
`locate`搜索速度快，在后台数据库`/var/lib/mlocate`中按文件名搜索，只能按照文件名搜索
`find`进行精确查询，要模糊查询使用`*`通配符
`whoami`搜索当前用户
`whatis`搜索命令的作用
`whereis`只能搜索系统命令的所在位置，搜索命令的所在位置和帮助文档
`which`搜索命令所在位置和别名
```shell
locate[文件名]    //创建新文件后，必须要updatedb更新数据库，才能找到新文件
find [位置] -name [文件名]
find [位置] -iname [文件名]    //不区分大小写
find [位置] -user [文件名]    //按照所有者搜索
find [位置] -nouser [文件名]    //查找没有所有者的文件
find [位置] -mtime +10    //查找10天前修改内容的文件，+10十天前，10十天当天，-10十天内
find [位置] -ctime +10    //查找10天前修改属性的文件
find [位置] -atime +10    //查找10天前访问过的文件
find [位置] -size 25k    //查找大小为25KB的文件，+25大于25KB，25等于25KB，-25小于25KB，k小写，M大写
find [位置] -size +25k -a -size -100k   //查找大于25k小于100k的文件，-a逻辑与，-o逻辑或
find [位置] -size +25k -a -size -100k -exec [命令] {} \    //对满足条件的文件执行命令
find [位置] -inum 123456    //查找i节点为123456的文件
whoami
whatis [命令]
whereis -bm[命令]     -b只查找可执行文件，-m只查找帮助文档
which [命令]
grep -iv [字符串] [文件名]    //在文件当中匹配符合的字符串，匹配使用正则表达式，-i忽略大小写，-v排除指定字符串(取反)
```
根据`/etc/updatedb.conf`配置文件进行搜索

| prune_bind_mounts="yes" | 开启搜索限制                    |
|:------------------------|:--------------------------------|
| prunefs                 | 搜索时，不搜索的文件系统        |
| prunenames              | 搜索时，不搜索的文件类型（后缀）|
| prunepaths              | 搜索时，不搜索的文件路径        |

## 帮助命令：man，help，info
`manul`的缩写
```shell
man -f [命令]    //相当于whatis，查看命令的作用
man -k [命令]    //相当于apropos，查看命令的所有帮助
ls --help    //命令的帮助
help [命令]    //help是专门获取shell内部命令的帮助命令
info [命令]    //-回车进入子帮助页面，-u进入上层页面，-n进入下一个帮助小节，-p进入上一个帮助小节，-q退出
```

## 压缩命令：zip，unzip，gzip，gunzip，bzip2，bunzip2，tar
常见压缩格式：`.zip`，`.gz`，`.bz2`，`.tar.gz`，`.tar.bz2`
```shell
zip [压缩文件名] [原文件]    //-r压缩目录
unzip [压缩文件]    //解压缩

gzip [原文件]    //自动压缩生成源文件.gz，并且删除原文件
gzip -r [原文件]    //-r压缩目录下的所有子文件，但不压缩目录
gzip -c [原文件] > [压缩文件]    //压缩文件，但不删除原文件
gzip -d [压缩文件]    //解压缩
gunzip [压缩文件]    //解压缩

bzip2 -k [原文件]   //-k保留原文件，不能压缩目录
bzip2 -d [压缩文件]   //-k保留压缩文件，解压缩
bunzip2 [压缩文件]   //解压缩

tar -cvf [压缩文件] [原文件]    //-c打包，-v显示过程，-f指定打包后的文件名，解决不能压缩目录的问题
tar -xvf [压缩文件]     //-x解打包，-v显示过程，-f指定打包后的文件名
tar -zcvf [压缩文件] [原文件1] [原文件2]    //-z压缩gz格式，可以压缩多个文件
tar -jcvf [压缩文件]  [原文件1] [原文件2]    //-j压缩bz2格式，可以压缩多个文件
tar -zxvf [压缩文件]     //-x解压缩
tar -jxvf [压缩文件] -c [新文件名]     //-x解压缩，并重命名
tar -ztvf [压缩文件] -c [新文件名]     //-t查看压缩内容，不解压
```

## 关机和重启命令：shutdown，halt，poweroff，init 0
`halt`，`poweroff`，`init 0`关机不安全，不能保存数据
`reboot`，`init 6`重启不安全
```shell
shutdown -c    //-c取消前一个关机命令
shutdown -h [时间]    
shutdown -h now    //-h关机，现在关机
shutdown -r 05:30 &  //-r重启，&放入后台，凌晨5点30分重启
```
`init`相关命令
{% qnimg 命令提示符_01.png %}

## 退出登录命令：logout
```shell
logout
```

## 挂载与卸载命令：mount，umount
```shell
mount    //查询挂载点
mount -a    //根据/etc/fstab的内容，自动挂载
mount -t [文件系统] -o [特殊选项] [设备文件名] [挂载点]    //进行挂载

umount [设备文件名或挂载点]    //卸载命令
```
`-o`特殊选项
{% qnimg 命令提示符_02.png %}

### 挂载光盘
```shell
mkdir /mnt/cdrom    //先建立挂载点
mount -t iso9660 /dev/sr0 /mnt/cdrom    //然后进行挂载
```
### 挂载U盘
```shell
fdisk -l    //查看U盘设备名
mkdir /mnt/usb    //先建立挂载点
mount -t vfat /dev/sdb1 /mnt/usb    //进行挂载
```
