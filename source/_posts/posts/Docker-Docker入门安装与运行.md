---
title: Docker入门安装与运行
url: Docker_simple_installation_and_operation
tags:
  - Docker
categories:
  - Linux
date: 2018-07-19 22:20:00
---
# 前言
`docker`是一个存放应用的容器, 将下载、安装、运行等进行了规范化。
本文将在虚拟机中`CentOS`使用桥接连接本机。关于桥接可以看我的另一篇文章, 上方搜索**桥接**即可。

<!-- more -->

# CentOS7安装
```
#!/bin/bash
# 1. 检查是否为root用户
echo "==================检查是否为root用户=================="
if [[ ${EUID} != 0 ]]; then
    echo "请切换到root用户";
    exit 1;
fi;
echo "当前用户是root"

# 2. 检查内核版本号大于3.10
echo "==================检查内核版本号大于3.10=================="
status=$(uname -r | awk -F '.' '{if($1>=3&&$2>=10) {print "0"} else { print "1"}}')
if [[ ${status} != 0 ]]; then
    echo "Kernel version must be >= 3.10, you version is $(uname -r)"
    exit 1;
fi;
echo "当前内核版本号是$(uname -r)"

# 3. 删除旧版本docker
echo "==================删除旧版本docker=================="
yum remove docker docker-common docker-selinux docker-engine

# 4. yum-util提供yum-config-manager功能, 另外两个是devicemapper驱动依赖的
echo "==================安装相关依赖=================="
yum install -y yum-utils device-mapper-persistent-data lvm2

# 5. 设置yum源
echo "==================设置yum源=================="
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 6. 安装docker并启动
echo "==================安装docker=================="
yum install -y docker-ce
service docker start

# 7. 验证是否安装成功
echo "==================验证是否安装成功=================="
docker version
```

# 安装运行Hello World
`docker`包含几个命令, `docker pull`下载, `docker images`查看镜像, `docker run` 运行。
这是一个`hello world`程序, [docker hub 地址](https://hub.docker.com/_/hello-world/)
```sh
# 1. 从仓库下载hello-world
$ docker pull hello-world
latest: Pulling from library/hello-world
9db2ca6ccae0: Pull complete 
Digest: sha256:4b8ff392a12ed9ea17784bd3c9a8b1fa3299cac44aca35a85c90c5e3c7afacdc
Status: Downloaded newer image for hello-world:latest

# 2. 查看已有镜像
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              2cb0d9787c4d        5 days ago          1.85kB

# 3. 运行 hello world, 打印如下信息
$ docker run hello-world
来自Docker的问好!
此消息表示您的安装似乎正常工作。

为了生成这些信息, Docker进行了以下的操作:
 1. Docker客户端 连接到 Docker daemon守护进程
 2. Docker daemon守护进程 从 Docker 仓库 下载(pull) 了 hello-world 镜像(image)
 3. Docker daemon守护进程从该镜像(image)创建了一个新容器(container)，该容器运行并执行可执行文件, 输出您现在看到的内容。
 4. Docker daemon守护进程将输出流输出到Docker客户端, Docker客户端会将信息发送到你的终端(terminal)
```
执行操作: 
1. `docker client`客户端向`docker daemon`服务端发送`docker run`命令
2. `docker daemon`检查是否有`image`镜像, 没有则向`docker hub`仓库下载`image`镜像
3. `docker daemon`会创建一个`container`容器运行这个`image`镜像

# 安装运行Nginx
先安装`docker pull nginx`, 然后运行`docker run -dp 8080:80 nginx`。
1. `-d`: 后台运行容器, 并返回容器ID
2. `-p`: 进行端口映射, 格式为: `主机端口:容器端口`

然后我们就可以在自己电脑输入`http://ip地址:8080`访问到`nginx`。

## WARNING: IPv4 forwarding is disabled. Networking will not work.
如果提示`IPv4`转发没有开启, 那就去开启。
```sh
$ echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
$ systemctl restart network
```

## 为什么要做端口映射?
`Docker`容器可以看成是一个`虚拟机`, 那我们的3台机器就有这种关系
![主机关系](https://yuml.me/diagram/nofunky/class/[win10%E7%9C%9F%E6%AD%A3%E7%9A%84%E4%B8%BB%E6%9C%BA]-%3E[CentOS7%E8%99%9A%E6%8B%9F%E6%9C%BA],[CentOS7%E8%99%9A%E6%8B%9F%E6%9C%BA]-%3E[Docker%20Nginx%E5%AE%B9%E5%99%A8])

如果是直接安装在`CentOS7虚拟机`上的话, 我们的`win10真正的主机`是可以直接访问`Nginx`的。 但是现在是运行在`Docker`容器里, 中间隔了个`CentOS7虚拟机`, 我们就需要做端口映射, 如`docker run -dp 8080:80 nginx`。

这样我们在`win10真正的主机`访问`CentOS7虚拟机`的`8080`端口时, `CentOS7虚拟机`会转发到`Docker`容器的`80`端口(这也是之前我们为什么要开启`IPv4`转发的原因)，我们就可以在`win10真正的主机`间接访问`Docker`容器中的`Nginx`了。

**注意**
实际最好端口要一致, 这里为了容易区分, 才分为`8080:80`, 最好为`80:80`。

## 修改Nginx配置文件
`Docker`容器就像一个虚拟机, 所以我们也可以通过`bash`进入。
```sh
# 1. 后台启动nginx, 映射虚拟机端口8080到容器端口80
[root@localhost ~]$ docker run -dp 8080:80 nginx
0df7493162a1e34d43c74e67b1bbe4c810ea821a994d85d5d45eae837d4ddf25

# 2. 查看docker进程, 找到nginx的容器id
[root@localhost ~]$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
0df7493162a1        nginx               "nginx -g 'daemon of…"   6 seconds ago       Up 5 seconds        0.0.0.0:8080->80/tcp   naughty_kilby

# 3. 执行bash命令进入docker容器内部
[root@localhost ~]$ docker exec -it 0df7493162a1 bash
# -i 让容器的标准输入保持打开
# -t 让Docker分配一个伪终端（pseudo-tty）并绑定到容器的标准输入上
root@0df7493162a1:/$ vim /etc/nginx/nginx.conf
```
进入容器, 就可以像普通的`Linux`一样进行操作了, 如编辑配置文件`vim /etc/nginx/nginx.conf`。