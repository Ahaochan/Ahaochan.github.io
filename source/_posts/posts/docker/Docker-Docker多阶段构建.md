---
title: Docker多阶段构建
url: docker_multi_stage_build
tags:
  - Docker
categories:
  - Docker
date: 2020-06-22 22:36:00
---

# 前言
> Docker多阶段构建是17.05以后引入的新特性，旨在解决编译和构建复杂的问题。
> 减小镜像大小。因此要使用多阶段构建特性必须使用高于或等于17.05的Docker。

在`Docker`多阶段构建出现之前, 要将`java`程序打包运行, 需要编写两个`Dockerfile`文件, 一个用来打包, 一个用来部署.
<!-- more -->

# 两个 Dockerfile 的部署方式
创建用于打包的`Dockerfile`文件

```dockerfile
# Dockerfile.build
FROM registry.cn-hangzhou.aliyuncs.com/acs/maven:3-jdk-8
WORKDIR /usr/app
VOLUME /root/.m2
COPY ../../../.. .
CMD ["mvn", "clean", "package", "-DfinalName=ahao"]
```
创建用于部署的`Dockerfile`文件.
```dockerfile
FROM java:8-jre-alpine
COPY ./ahao.jar /ahao.jar
ENTRYPOINT ["/usr/bin/java", "-jar"]
CMD ["/ahao.jar"]
```
然后编写`shell`脚本, 将两个`Dockerfile`构建镜像后, 关联起来
```bash
# 1. 构建打包镜像
docker build -t ahao-build-image -f Dockerfile.build .
# 2. 创建 volume 存储, 缓存依赖项
docker volume create --name maven-repo
# 3. 执行打包命令
docker run -it -v maven-repo:/root/.m2 --name ahao-build ahao-build-image
# 4. 将打包后的 jar 包移出容器
docker cp ahao-build:/usr/app/target/ahao.jar .

# 5. 构建部署镜像
docker build -t ahao-jar-deploy -f Dockerfile .
# 6. 启动部署容器
docker run -it --name ahao-deploy ahao-jar-deploy
```

# Docker 多阶段构建
在`Docker`多阶段构建出现之前, 除了两个`Dockerfile`文件之外, 还要编写`shell`脚本.
真复杂, 于是多阶段构建就出现了.

在编写`Dockerfile`之前, 先把`pom.xml`几个重要的参数设置一下.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project>
    <properties>
        <file.encoding>UTF-8</file.encoding>
        <start-class>moe.ahao.docker.Main</start-class>
        <finalName>${project.artifactId}-${project.version}</finalName>
    </properties>
    <build>
        <finalName>${finalName}</finalName>
        <plugins>
            <plugin>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.1.2</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>${start-class}</mainClass>
                            <addDefaultImplementationEntries>true</addDefaultImplementationEntries>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```
这里用`maven-jar-plugin`打包, 还用到几个参数
1. `finalName`, 用于指定打包出来的`jar`名称, 方便编写`Dockfile`
2. `mainClass`, 用于指定`jar`包的主类.

将上面的打包部署脚本翻译一下.
```dockerfile
FROM registry.cn-hangzhou.aliyuncs.com/acs/maven:3-jdk-8 AS build
WORKDIR /usr/app
COPY pom.xml .
RUN ["/usr/local/bin/mvn-entrypoint.sh", "mvn", "verify", "clean", "--fail-never"]
COPY src ./src
RUN ["/usr/local/bin/mvn-entrypoint.sh", "mvn", "verify", "-DfinalName=ahao"]

FROM java:8-jre-alpine
COPY --from=build /usr/app/target/ahao.jar /usr/app/app.jar
ENTRYPOINT ["/usr/bin/java", "-jar"]
CMD ["/usr/app/app.jar"]
# docker build -t ahao-docker .
# docker run -it ahao-docker
```
然后构建镜像, 部署.

相关代码可以看我的[例子](https://github.com/Ahaochan/project/tree/master/ahao-docker)

# 参考资料
- [`Is it possible to rename a maven jar-with-dependencies?`](https://stackoverflow.com/a/14417340)