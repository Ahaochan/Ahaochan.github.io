---
title: Linux以不同方式执行Shell导致的变量生命周期问题
url: Linux_performs_variable_life_cycle_issues_caused_by_the_shell_in_different_ways
date: 2017-11-12 00:20:40
tags:
  - Linux
  - Shell
categories:
  - Linux
---

# 前言
在`Tomcat/bin/catalina.sh`中有一段代码如下
```sh
# 判断setenv.sh是否存在, 存在就执行
if [ -r "$CATALINA_BASE/bin/setenv.sh" ]; then
  . "$CATALINA_BASE/bin/setenv.sh" # 以点、空格、Shell的方式执行Shell
elif [ -r "$CATALINA_HOME/bin/setenv.sh" ]; then
  . "$CATALINA_HOME/bin/setenv.sh"
fi
```

<!-- more -->

# 不同的执行shell方式
先添加一个`setenv.sh`文件
```sh
export JAVA_HOME=/opt/jdk/jdk1.8.0_151
export JAVA_OPTS=-Xmx512m
```

执行以下代码
```sh
# 查找当前shell中的JAVA变量, 没找到
[root@127.0.0.1 ~]# set | grep JAVA
# 1.1. 以开启子shell的方式执行setenv.sh
[root@127.0.0.1 ~]# sh /opt/tomcat/tomcat-test/bin/setenv.sh 
# 1.2. setenv.sh的变量生命周期在子shell中, 不影响当前shell, 所以没找到JAVA变量
[root@127.0.0.1 ~]# set | grep JAVA
# 2.1. 在当前shell执行的方式, 点+空格+shell的格式执行
[root@127.0.0.1 ~]# . /opt/tomcat/tomcat-test/bin/setenv.sh 
# 2.2. 变量生命周期在当前shell, 找到了JAVA变量
[root@127.0.0.1 ~]# set | grep JAVA
JAVA_HOME=/opt/jdk/jdk1.8.0_151
JAVA_OPTS=-Xmx512m
# 3.1. 退出shell重新打开shell, 清除之前的变量
[root@127.0.0.1 ~]# exit
[ahao@127.0.0.1 ~]$ su -
# 3.2. 确认JAVA变量已经清除
[root@127.0.0.1 ~]# set | grep JAVA
# 3.3. 使用source在当前shell执行, 和方式2等价
[root@127.0.0.1 ~]# source /opt/tomcat/tomcat-test/bin/setenv.sh 
# 3.4. 变量生命周期在当前shell, 找到了JAVA变量
[root@127.0.0.1 ~]# set | grep JAVA
JAVA_HOME=/opt/jdk/jdk1.8.0_151
JAVA_OPTS='-Xms2000m -Xmx2000m'
```

# 总结
1. 有三种执行shell脚本的语法, 实际上只有两种执行shell的方式, 一种在当前shell执行, 一种在子shell中执行。
2. `. /opt/tomcat/tomcat-test/bin/setenv.sh`和`source /opt/tomcat/tomcat-test/bin/setenv.sh `等价。