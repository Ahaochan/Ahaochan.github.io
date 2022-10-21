---
title: Tomcat部署外部应用最佳实践
url: Best_Practices_of_deploys_Outside_Application_with_Tomcat
tags:
  - Tomcat
  - 最佳实践
categories:
  - Java Web
date: 2017-08-30 21:45:31
---

# 前言
Tomcat有一个扩展点, 可以配置环境变量
` Tomcat 8.5\bin\setenv.sh `, 如果没有可以手动创建。
- Windows用 ` bat ` 后缀
- Linux用 ` sh ` 后缀

<!-- more -->

# 配置setenv.bat
在 ` Tomcat\bin ` 目录下新建 ` setenv.bat `文件。
输入如下配置
Windows
```shell
set JAVA_HOME=D:\Java\jdk1.8.0_112(替换为jdk的路径)
set JAVA_OPTS=-Xmx512m
set TITLE=自定义的标题
```

Linux
```
JAVA_HOME=/opt/jdk/jdk1.8.0_181
JAVA_OPTS=-Xmx512m
CATALINA_PID=$CATALINA_HOME/bin/CATALINA_PID # shutdown.sh -force 必须参数
```

# 配置ahao.xml
在 ` Tomcat\conf\Catalina\localhost ` 目录下(没有则创建), 创建 ` ahao.xml ` 文件。
输入如下配置
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/" docBase="F:\ahao" 
        reloadable="true" privileged="true">
</Context>
```
` docBase ` 是 ` war ` 包的解压路径。
通俗讲, 就是包含子目录为 ` WEB-INF ` 、 ` META-INF ` 的一个目录。

# 运行   
打开 ` Tomcat\bin\startup.bat ` 即可。
输入 ` http://localhost:8080/ahao ` 。
这里的项目名就是之前配置的 ` xml ` 的名称。

# 原理
在catalina.sh文件中会自动载入环境变量
```shell
if [ -r "$CATALINA_BASE/bin/setenv.sh" ]; then
  . "$CATALINA_BASE/bin/setenv.sh"
elif [ -r "$CATALINA_HOME/bin/setenv.sh" ]; then
  . "$CATALINA_HOME/bin/setenv.sh"
fi
```
