---
title: Docker数据持久化
url: Docker_data_persistence
tags:
  - Docker
categories:
  - Docker
date: 2019-02-03 00:28:00
---
# 前言
当我们使用`Docker`创建一个`mysql`的`container`, 数据是存储在`container`内的.
如果有一天不小心执行了`docker rm $(docker ps -aq)`删除所有`container`. 那么`mysql`里的数据也会被删掉, 这是不安全的.
我们需要将数据持久化, 存储在`container`外部. 即使删除`container`也不会删除原有的数据.

<!-- more -->

# Data Volume 数据持久化
`Volume`可以将数据持久化到宿主机的某个目录下.
我们在官方的`mysql`的[`Dockerfile`](https://github.com/docker-library/mysql/blob/bb7ea52db4e12d3fb526450d22382d5cd8cd41ca/5.7/Dockerfile#L73)里可以看到指定了`VOLUME`. 
```dockerfile
VOLUME /var/lib/mysql
```
说明这个`mysql`的数据存在这个文件夹下, **但是, 不是直接存在这个文件夹下, 里面还有多层目录**.

先看下下面的例子
```bash
# 1. 运行一个mysql, -v 等价于 VOLUME 关键字, -e 指定环境变量
docker run -d -v my-volume:/var/lib/mysql --name my-mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=true mysql
docker volume ls
# DRIVER   VOLUME NAME
# local    my-volume

# 2. 查看 my-volume 的详细信息, 可以看到 Mountpoint 指定了具体存储位置
docker volumn inspect my-volume
# [
#     {
#         "CreatedAt": "2019-02-03T10:25:00+08:00",
#         "Driver": "local",
#         "Labels": null,
#         "Mountpoint": "/var/lib/docker/volumes/my-volume/_data",
#         "Name": "my-volume",
#         "Options": null,
#         "Scope": "local"
#     }
# ]

# 3. 删除 container 后, volume 仍然存在
docker rm -f my-mysql
docker volume ls
# DRIVER   VOLUME NAME
# local    my-volume
```
既然数据是在`container`外部的, 那当然的, 我们可以创建另一个`mysql`连接到这个`Volume`.
```bash
docker run -d -v my-volume:/var/lib/mysql --name my-mysql-new -e MYSQL_ALLOW_EMPTY_PASSWORD=true mysql
```

# Bing Mounting 绑定挂载
`Bing Mounting`可以将`container`里的目录和宿主机的目录做映射.
比如`nginx`, 想要改里面的`html`, 每次都要`docker exec -it my-nginx /bin/bash`进去容器内部改.
并且, `container`删掉后, 里面的`html`也不见了.

使用`Bing Mounting`解决这个问题.
```bash
# 1. 创建一个自己的 index.html
mkdir /opt/nginx
cd /opt/nginx
echo "替换掉的html" > /opt/nginx/index.html

# 2. 将当前目录 /opt/nginx 和 container 内部的 html 目录做映射
docker run -v $(pwd):/usr/share/nginx/html -d -p 80:80 --name my-nginx nginx
```
这样, 在外部访问`nginx`时, 就可以看到被替换的`html`.