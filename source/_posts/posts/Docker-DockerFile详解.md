---
title: DockerFile详解
url: DockerFile
tags:
  - Docker
categories:
  - Docker
date: 2020-06-19 00:47:00
---
# 前言
我们使用`Docker`镜像, 一般都是从远程[`Registry`](https://hub.docker.com/)仓库`pull`下来的.
```bash
docker pull hello-world
```
但是实际开发过程中, 经常会需要把自己的应用程序打包成一个`images`镜像. 这个镜像是需要自己打包的.
打包的方式一般有两种, `Docker File`和`Docker Compose`.

<!-- more -->

# 如何在已有 image 上做修改
官方虽然提供了很多的`Image`, 但是我们总会要做一些定制化需求.
比如往`Image`里面塞一些应用程序. 下面列举一个不推荐使用的修改`Image`的方法.
```bash
# 1. 拉取基础image
docker pull alpine
# 2. 运行基础image, 并创建一个 hello.txt 文件
docker run -it --name base-alpine alpine /bin/sh
# /bin/echo hello > /hello.txt
# exit

# 3. 使用这个退出后的container, 重新构建一个新的image
docker commit base-alpine ahao-alpine
# 4. 使用这个新构建的镜像, 能找到之前编辑过的 hello.txt
docker run -it ahao-alpine /bin/sh
# /bin/cat /hello.txt
```
但是这种方法不推荐, 也不安全.
如果是有恶意的人, 在第二步创建了一个恶意脚本, 然后发布到官方仓库. 使用者根本不知道上传者做了什么操作, 无法进行`Review`.
为了能进行`Review`代码审查, `Docker`提供了一个叫`DockerFile`的文件. 用来记录修改了哪些操作.

# 使用 Dockerfile 改造上述例子
```dockerfile
# 1. 基于 alpine 镜像构建
FROM alpine
# 2. 创建一个 hello.txt 文件
RUN /bin/echo hello > /hello.txt
# 3. 输出 hello.txt
ENTRYPOINT ["/bin/cat", "/hello.txt"]
```
我们创建了一个`Dockerfile`文件, 然后执行构建命令, 输出了`hello`
```bash
# 1. 在当前目录根据 Dockerfile 构建 Docker 镜像
docker build -t ahaochan/ahao-alpine .
# 2. 运行构建的镜像, 输出
docker run ahaochan/ahao-alpine
# hello
```

# Dockerfile 语法

下面讲讲`Dockerfile`的一些命令的语法和使用, 不过建议还是看[官方文档](https://docs.docker.com/engine/reference/builder/)的好.

## FROM
`FROM`表示当前镜像是基于哪个镜像做的.
比如之前用的`FROM alpine`, 表示当前镜像是基于`alpine`来做定制化需求.
推荐使用官方的`Image`来作为`FROM`基础镜像.

## LABEL
`LABEL`用来标记一些元数据`metadata`, 相当于镜像的注释.
虽然可以没有, 但是建议要有. 不然就是一个三无产品`Image`, 谁敢放心用呢?
```dockerfile
# 1. 基于 alpine 镜像构建
FROM alpine
# 2. 元数据 metadata
LABEL maintainer="作者" version="版本号" description="描述"
```

## WORKDIR
`WORKDIR`相当于`linux`的`cd`命令, 用于进入某个目录中, 如果目录不存在会自动创建目录.
有两点需要注意
1. 千万不要使用`RUN cd`, 因为每一次`RUN`都会产生一层`Image Layer`.
2. 尽量使用绝对目录, 避免弄混淆了

```dockerfile
WORKDIR /test
WORKDIR demo
# 输出 /test/demo
RUN pwd
```

## ENV 
`ENV`用于设置环境变量, 提高可维护性.
比如我要升级`MySQL`版本, 改变量就可以了.
```dockerfile
ENV MYSQL_VERSION 5.6
RUN apt-get update && \
    apt-get install -y mysql-server="${MYSQL_VERSION}" && \
    rm -rf /var/lib/apt/lists/*
```
除了上面这种简单用法还有一些高级用法
```dockerfile
FROM alpine
ENV VAR ahao
CMD ["/bin/sh", "-c", "echo ${VAR} ${VAR:-default} ${NO:-default} ${VAR:+value} ${NO:+value}"]
# ahao ahao default value
```
1. `${VAR:-default}`的意思是, 当`VAR`没有被定义的时候, 使用后面的`default`值
2. `${VAR:+default}`的意思是, 当`VAR`被定义的时候, 使用后面的`value`值, 否则使用空字符串

当重复定义一个变量的时候, 当前`Image Layer`会使用上一层`Image Layer`定义的变量.
```dockerfile
FROM alpine
ENV a=hello
ENV a=world b=$a
ENV c=$a
CMD ["/bin/sh", "-c", "echo ${a} ${b} ${c}"]
# world hello world
```

## ARG
`ARG <name>[=<default value>]`
在`docker build`镜像的时候使用`--build-arg <varname>=<value>`参数, 可以将外部参数传入`Dockerfile`文件中, 用来构建镜像.
```dockerfile
ARG VERSION=latest
FROM alpine:${VERSION}
CMD /bin/echo hello
```
构建镜像
```bash
# 1. 构建基于 最新alpine 的镜像
docker build -t ahaochan/ahao-alpine-last .
# 2. 构建基于 2.7 alpine 的镜像
docker build --build-arg VERSION=2.7 -t ahaochan/ahao-alpine-2.7 .
```
值得注意的是, 官方文档提到, `ARG`不要传递敏感数据, 不安全.

还有就是同名变量`ENV`会覆盖`ARG`. 根据这个特性, 可以做一些默认的操作.

```dockerfile
FROM alpine
ARG VERSION
ENV VERSION ${VERSION:-lastest}
CMD /bin/echo $VERSION
```

## COPY
`ADD`和`COPY`都是在构建镜像的时候, 将上下文的文件拷贝到镜像中.

```bash
docker build -t ahaochan/ahao-alpine .
```
关于上下文, 其实我们一直有在用, 在构建的时候会传入一个参数`.`, 表示将当前目录作为上下文.
构建的时候, `docker`客户端会把上下文中的所有文件发送给`docker daemon`.
那么如果`docker`客户端和`docker daemon`不在同一台机器上, `docker daemon`是获取不到除了上下文之外的文件的.
所以`Dockerfile`里面的文件, 都要基于这个上下文来访问.


如果只是简单的将文件复制到镜像中, 直接使用`COPY`就可以了
```dockerfile
FROM alpine
# 1. 将 file1 文件 复制到镜像内 /tmp/test1/ 目录下
COPY file1  /tmp/test1/
# 2. 将 file2开头的 文件 复制到镜像内 /tmp/test2/ 目录下
COPY file2* /tmp/test2/
# 3. 将 file3开头的 文件 复制到镜像内 /tmp/test3/ 目录下, ?占一个字符, *占多个字符
COPY file3? /tmp/test3/
# 4. 将 dir4目录下的 文件 复制到镜像内 /tmp/test4/ 目录下
COPY dir4/ /tmp/test4/
# 5. 将 dir5目录下的 文件 复制到镜像内 /tmp/test4/ 目录下, 不会复制 dir5目录本身
COPY dir5 /tmp/test5/
CMD /bin/ls /tmp/test*
```
构建完毕后, 我们进去看看
```bash
# 1. 准备文件
touch file1
touch file2 file22 file222
touch file3 file33 file333
mkdir dir4 && touch dir4/1 dir4/2 dir4/3
mkdir dir5 && touch dir5/1 dir5/2 dir5/3

# 2. 构建镜像并运行
docker build -t ahaochan/ahao-alpine .
docker run ahaochan/ahao-alpine
# /tmp/test1:
# file1
# /tmp/test2:
# file2     file22       file222
# /tmp/test3:
# file33
# /tmp/test4:
# 1         2           3
# /tmp/test5:
# 1         2           3
```

另外, `COPY`还能在多阶段构建中使用, 这是区别于`ADD`的一个用法.
多阶段构建常用在编译打包阶段, 这里不细讲.
```dockerfile
FROM alpine
RUN /bin/echo hello > /hello.txt

FROM alpine
# from = 0 引用第一个阶段的 stage, 拉取 hello.txt
COPY --from=0 /hello.txt .
CMD ["/bin/sh", "-c", "/bin/cat hello.txt"]
```

## ADD
`ADD`和`COPY`差不多, 也是将上下文的文件拷贝到镜像中.
`ADD`除了不能应用在多阶段构建的场景之外, `ADD`比`COPY`多了两个功能.
1. 自动解压缩文件并添加到镜像中
2. 从`url`拷贝文件并添加到镜像中. ([官方不推荐](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy), 使用`curl`或`wget`替代)

```dockerfile
FROM alpine
ADD hello.tar.gz /
ADD https://greasyfork.org/zh-CN/users/30831.json /
CMD ["/bin/sh", "-c", "/bin/ls -l hello.txt 30831.json"]
```
```bash
# 1. 准备压缩包
echo hello > hello.txt
tar zcvf hello.tar.gz hello.txt

# 2. 构建镜像
docker build -t ahaochan/ahao-alpine .
docker run ahaochan/ahao-alpine
# -rw-------    1 root  root  7748 Jan  1  1970 30831.json
# -rw-r--r--    1 root  root     6 Jun  7 08:09 hello.txt
```

## RUN
`RUN`有2种形式
1. `shell`形式: `RUN <command>`
1. `exec`形式: `RUN ["executable", "param1", "param2"]`

```dockerfile
FROM alpine
ENV VAR ahao
RUN echo "${VAR}"
# ahao
RUN echo ${VAR}
# ahao
RUN ["/bin/echo", "${VAR}"]
# ${VAR}
RUN ["/bin/sh", "-c", "echo ${VAR}"]
# ahao
```
可以看到, `exec`形式的`RUN`命令(其实不止`RUN`, 还有`CMD`和`ENTRYPOINT`), 不会去解析`${VAR}`.

`RUN`命令一般用来安装一些依赖, 删除缓存等操作.
但是每一次`RUN`都会产生一层`Image Layer`, 所以需要尽可能的少用`RUN`, 安装依赖尽量一行代码搞定.
```dockerfile
# yum 安装例子
RUN yum update && \
    yum install -y vim
# apt 安装例子, 注意删除缓存
RUN apt-get update && \
    apt-get install -y vim && \
    rm -rf /var/lib/apt/lists/*
```

## CMD
`CMD`有3种形式
1. `shell`形式: `CMD <command>`
1. `exec`形式: `CMD ["executable", "param1", "param2"]`
1. `exec`形式: `CMD ["param1","param2"]`, 作为`ENTRYPOINT`的默认参数.
`CMD`是`container`启动时默认执行的命令.
使用`CMD`有几个需要注意的地方.
1. 如果`Dockerfile`有多个`CMD`, 就只会执行最后一个.
1. 外部命令会覆盖内部的`CMD`.

```dockerfile
# 1. 基于 alpine 镜像构建
FROM alpine
# 2. 第1个 CMD 命令
CMD ["/bin/ping", "127.0.0.1"]
# 3. 第2个 CMD 命令
CMD ["/bin/echo", "hello"]
```
编写完`Dockerfile`后, 我们来构建它.
```bash
# 1. 构建镜像
docker build -t ahaochan/ahao-alpine .
# 2. 不指定外部命令, 默认执行 Dockerfile 最后一个 CMD 命令 
docker run ahaochan/ahao-alpine
# hello
# 3. 指定外部命令, 覆盖 Dockerfile 里的 CMD 命令
docker run -it ahaochan/ahao-alpine /bin/echo ahao
# ahao
```

## ENTRYPOINT
`ENTRYPOINT`有2种形式
1. `shell`形式: `ENTRYPOINT command param1 param2`
1. `exec`形式: `ENTRYPOINT ["executable", "param1", "param2"]`, 推荐使用.

`ENTRYPOINT`让`container`以应用程序或者服务的形式在后台运行.
等价于`docker run --entrypoint "command"`

```dockerfile
FROM alpine
ENTRYPOINT ["/bin/ping", "127.0.0.1"]
```
```bash
docker build -t ahaochan/ahao-alpine .
# 1. 错误使用--entrypoint覆盖
docker run --entrypoint "/bin/echo hello" ahaochan/ahao-alpine
# docker: Error response from daemon: OCI runtime create failed: container_linux.go:345: starting container process caused "exec: \"/bin/echo hello\": stat /bin/echo hello: no such file or directory": unknown.
# 2. 正确使用--entrypoint覆盖
docker run --entrypoint /bin/echo ahaochan/ahao-alpine hello
# hello
# 3. 循环执行ping 127.0.0.1
docker run ahaochan/ahao-alpine 
# 4. CMD 和 ENTRYPOINT 组合使用, ping 127.0.0.1 -c 3
docker run ahaochan/ahao-alpine -c 3
```

# Docker Compose 语法
我们在进行容器间的通信的时候, 要分别启动容器, 关闭还要一个个关闭.
比如我要在`ahao-alpine2`向`ahao-alpine1`发送请求, 需要先启动`ahao-alpine1`, 然后再启动`ahao-alpine2`.
```bash
docker run -d --name ahao-alpine1  alpine /bin/ping 127.0.0.1
docker run --name ahao-alpine2 --link ahao-alpine1 alpine /bin/ping ahao-alpine1
```
为了解决这个繁琐的操作, `Docker`提供了一个工具`Docker Compose`.
```bash
# 不推荐使用 apt install, 这安装的是旧版本
# apt install docker-compose -y

# https://docs.docker.com/compose/install/#install-compose-on-linux-systems
curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```
我们创建一个`docker-compose.yml`文件
```yaml
version: "3"
services:
  ahao-alpine1:
    image: alpine
    command: ["/bin/ping", "127.0.0.1"]
  ahao-alpine2:
    image: alpine
    links:
      - ahao-alpine1
    command: ["/bin/ping", "127.0.0.1"]
```
一个`Service`代表一个`Container`, 启动类似`docker run`, 可以为其指定`network`和`volume`.
然后执行以下命令
```bash
# 在后台启动 compose
docker-compose up -d
# 进行容器间的网络通信
docker-compose exec ahao-alpine2 /bin/ping -c 3 ahao-alpine1
# 关闭进程并删除镜像
docker-compose down
```

## 搭建 wordpress
```yaml
version: "3"
services:
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    networks:
      - my-bridge
  db:
    image: mysql:5.7
    restart: always
    volumes:
      - mysql-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      - my-bridge
  pma:
    depends_on:
      - db
    image: phpmyadmin/phpmyadmin
    restart: always
    ports:
      - 8080:80
    environment:
      # https://docs.phpmyadmin.net/en/latest/setup.html#docker-environment-variables
      PMA_HOST: db
      PMA_PORT: 3306
      MYSQL_ROOT_PASSWORD: root
    networks:
      - my-bridge
volumes:
  mysql-data: {}
networks:
  my-bridge:
    driver: bridge
```

# 参考文档
- [官方文档](https://docs.docker.com/engine/reference/builder/)