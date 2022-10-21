---
title: RUN和CMD和ENTRYPOINT
url: RUN_CMD_ENTRYPOINT
tags:
  - Docker
categories:
  - Docker
date: 2019-01-31 12:34:00
---
# 前言
`Docker`有三种命令执行方式
1. `RUN`: 执行命令并创建新的`Image Layer`
1. `CMD`: 设置容器启动后默认执行的命令和参数
1. `ENTRYPOINT`: 设置容器启动时运行的命令

<!-- more -->

# RUN
`RUN`命令一般用来安装一些依赖, 删除缓存等操作.
但是每一次`RUN`都会产生一层`Image Layer`, 所以需要尽可能的少用`RUN`, 尽量一行代码搞定.
```dockerfile
RUN yum update && yum install -y vim
RUN apt-get update && apt-get install -y \
        vim && rm -rf /var/lib/apt/lists/*
RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
```

# CMD
`CMD`是`container`启动时默认执行的命令.
等价于`docker run -it [image] /bin/bash`.
并且会被覆盖.
1. 多个CMD只会执行最后一个.
1. 外部命令会覆盖内部的`CMD`.

利用外部命令会覆盖内部`CMD`的特性, 我们可以从外部传入参数.
```dockerfile
FROM centos
ENTRYPOINT ["/usr/bin/curl"]
# 默认查看curl版本号
CMD ["--version"] 
```
然后执行以下命令
```bash
docker build -t centos-curl .
docker run -it centos-curl --head www.baidu.com
```
等价于在`container`中执行`/usr/bin/curl --head www.baidu.com`.

# ENTRYPOINT
`ENTRYPOINT`让`container`以应用程序或者服务的形式运行.
和`CMD`相比, `ENTRYPOINT`不会被忽略, 一定会执行.
最佳实践就是写一个`shell`作为`ENTRYPOINT`
```dockerfile
COPY docker-entrypoint.sh /usr/local/bin
ENTRYPOINT ["docker-entrypoint.sh"]
```

# 参数格式 SHELL 和 EXEC
另外, `RUN`和`CMD`和`ENTRYPOINT`的参数规则有两种, `SHELL` 和 `EXEC`.
以`ENTRYPOINT`为例, 这两种`ENTRYPOINT`的写法是等价的.
```dockerfile
FROM centos
ENV name Ahao
# ENTRYPOINT echo "hello ${Ahao}"
ENTRYPOINT ["/bin/bash", "-c", "echo hello ${Ahao}"]
# ENRTYPOINT [COMMAND] 等价于 ENTRYPOINT ["/bin/bash", "-c", "[COMMAND]"]
```

# 总结
1. 使用`RUN`安装软件依赖, 并记得删除缓存.
1. 构建服务时使用`Exec`格式的`ENTRYPOINT`.
1. 默认启动命令使用`CMD`.