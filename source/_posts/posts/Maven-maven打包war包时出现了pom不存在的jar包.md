---
title: maven打包war包时出现了pom不存在的jar包
url: maven_will_import_WEB-INF_lib_jar_to_war
tags:
  - Maven
categories:
  - Maven
date: 2017-08-30 21:26:05
---

标题是有点绕。
这几天在搞一个 ` SpringBoot ` 的短信项目, 在打包 ` war ` 包的时候, 
发现war包中的 ` commons-lang ` 包有两个版本, 一个 ` 1.0.1 ` , 一个 ` 2.6 ` 。
在 ` pom.xml ` 中我只导入了 ` 2.6 ` 的版本, 那么 ` 1.0.1 ` 的jar包是从哪来的呢?
<!-- more -->

# 先说结论
` maven ` 的 ` package ` 命令会把 ` WEB-INF/lib ` 中的jar包也打包进war包中。

# 排错
1. 首先先看maven的依赖, 使用的是IDEA。
点击 ` View -> Tool Windows -> Maven Projects `, 在右边出现的窗口, 点击 ` Show Dependencies `。
点击` Alt `可以打开放大镜。
并没有找到`commons-lang 1.0.1`。

2. 接下来把` pom.xml `的依赖全部注释掉, 只留下 ` spring-boot-starter-web `
运行`Hello world` 成功。
打包, 还是发现了`commons-lang 1.0.1`。
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
```

3. 手动排除`commons-lang`, 打包, 还是有`commons-lang 1.0.1`。
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>commons-lang</groupId>
            <artifactId>commons-lang</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

4. 发现war包的`commons-lang 1.0.1`是在`WEB-INF/lib`下的
于是在`src/main/webapp/WEB-INF/lib`下, 果然发现了`commons-lang 1.0.1`的包

# 结论
` maven ` 的 ` package ` 命令会把 ` WEB-INF/lib ` 中的jar包也会打包进war包中。
