---
title: Logback日志配置
url: Logback_xml_configuration
tags:
  - Logback
categories:
  - Java Web
date: 2017-09-05 22:54:30
---

# 前言
回想以前都是用 ` System.out.println ` 作为调试的主要手段的, 但是当部署到服务器时, 我们不可能一直盯着控制台看, 并且这种方法也不能进行分级输出。 ` System.out.println ` 也就满足不了需求了。
` Logback ` 是一个 Java 领域的日志框架。它被认为是 ` Log4J ` 的继承人，实现了 ` SLF4J ` 标准。反正就是个特好用的东西。

<!-- more -->

# 导入maven
- [slf4j-api](https://mvnrepository.com/artifact/org.slf4j/slf4j-api)
- [logback-classic](https://mvnrepository.com/artifact/ch.qos.logback/logback-classic) : 包含了[slf4j-api](https://mvnrepository.com/artifact/org.slf4j/slf4j-api)、[logback-core](https://mvnrepository.com/artifact/ch.qos.logback/logback-core)
- [logback-ext-spring](https://mvnrepository.com/artifact/org.logback-extensions/logback-ext-spring): 提供的对Spring的支持
- [jcl-over-slf4j](https://mvnrepository.com/artifact/org.slf4j/jcl-over-slf4j): 打印Spring框架本身打印的日志

# Spring 配置
```xml
<listener>  
    <listener-class>ch.qos.logback.ext.spring.web.LogbackConfigListener</listener-class>  
</listener>  
<context-param>  
    <param-name>logbackConfigLocation</param-name>  
    <param-value>classpath:logback.xml</param-value>  
</context-param>  
```

Spring Boot直接放在 ` resource/logback.xml `即可, 会自动配置加载。


# logback.xml
直接复制粘贴进去即可, 一些基本常识请看官方文档或下面的参考资料。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false">
    <!-- 上下文名称 -->
    <property name="log.context.name" value="MyApp" />
    <!-- log编码 -->
    <property name="log.charset" value="UTF-8" />
    <!-- log文件最大历史 -->
    <property name="log.history.max" value="30" />
    <!-- log文件输出路径, 相对路径LOG在Tomcat 8.5\bin\LOG下, 绝对路径/LOG在D:\LOG下 -->
    <!-- 推荐绝对路径 -->
    <property name="log.path" value="LOG" />

    <!-- Log4j: [S][%d{yyyyMMdd HH:mm:ss}][%-5p][%C:%L] - %m%n -->
    <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
    <property name="log.pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n" />
    <property name="log.pattern.short" value="%date{yyyyMMdd HH:mm:ss.SSS}-%msg%n" />


    <!-- 设置上下文名称 -->
    <contextName>${log.context.name}</contextName>

    <!-- 输出到控制台 -->
    <!-- appender用于输出log日志, name是appender的唯一标识, class指定实现类 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <!-- encoder是编码器, charset指定编码格式 -->
        <encoder charset="${log.charset}">
            <!-- 输出日志的格式, 在上面有提到 -->
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>
    <appender name="STDOUT_SHORT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder charset="${log.charset}">
            <pattern>${log.pattern.short}</pattern>
        </encoder>
    </appender>

    <!-- 输出到文件 -->
    <!-- ERROR级别日志 -->
    <!-- 滚动记录文件，先将日志记录到指定文件，当符合某个条件时，将日志记录到其他文件 RollingFileAppender-->
    <appender name="FILE_ERROR" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 过滤器，只记录ERROR级别的日志 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>ERROR</level>
            <!-- 匹配则处理这个日志, 不经过其他过滤器 -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配则抛弃这个日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--日志输出位置  可相对、和绝对路径 -->
            <fileNamePattern>${log.path}/error/log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <!-- 可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件假设设置每个月滚动，且<maxHistory>是6，
            则只保存最近6个月的文件，删除之前的旧文件。注意，删除旧文件是，那些为了归档而创建的目录也会被删除-->
            <maxHistory>${log.history.max}</maxHistory>
        </rollingPolicy>
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>

    <!-- WARN级别日志 appender -->
    <appender name="FILE_WARN" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 过滤器，只记录WARN级别的日志 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>WARN</level>
            <!-- 匹配则处理这个日志, 不经过其他过滤器 -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配则抛弃这个日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--日志输出位置  可相对、和绝对路径 -->
            <fileNamePattern>${log.path}/warn/log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <!-- 可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件假设设置每个月滚动，且<maxHistory>是6，
            则只保存最近6个月的文件，删除之前的旧文件。注意，删除旧文件是，那些为了归档而创建的目录也会被删除-->
            <maxHistory>${log.history.max}</maxHistory>
        </rollingPolicy>
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>

    <!-- INFO级别日志 appender -->
    <appender name="FILE_INFO" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 过滤器，只记录INFO级别的日志 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>INFO</level>
            <!-- 匹配则处理这个日志, 不经过其他过滤器 -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配则抛弃这个日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--日志输出位置  可相对、和绝对路径 -->
            <fileNamePattern>${log.path}/info/log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <!-- 可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件假设设置每个月滚动，且<maxHistory>是6，
            则只保存最近6个月的文件，删除之前的旧文件。注意，删除旧文件是，那些为了归档而创建的目录也会被删除-->
            <maxHistory>${log.history.max}</maxHistory>
        </rollingPolicy>
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>

    <!-- DEBUG级别日志 appender -->
    <appender name="FILE_DEBUG" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 过滤器，只记录DEBUG级别的日志 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>DEBUG</level>
            <!-- 匹配则处理这个日志, 不经过其他过滤器 -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配则抛弃这个日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--日志输出位置  可相对、和绝对路径 -->
            <fileNamePattern>${log.path}/debug/log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <!-- 可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件假设设置每个月滚动，且<maxHistory>是6，
            则只保存最近6个月的文件，删除之前的旧文件。注意，删除旧文件是，那些为了归档而创建的目录也会被删除-->
            <maxHistory>${log.history.max}</maxHistory>
        </rollingPolicy>
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>

    <!-- TRACE级别日志 appender -->
    <appender name="FILE_TRACE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!-- 过滤器，只记录TRACE级别的日志 -->
        <filter class="ch.qos.logback.classic.filter.LevelFilter">
            <level>TRACE</level>
            <!-- 匹配则处理这个日志, 不经过其他过滤器 -->
            <onMatch>ACCEPT</onMatch>
            <!-- 不匹配则抛弃这个日志 -->
            <onMismatch>DENY</onMismatch>
        </filter>
        <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <!--日志输出位置  可相对、和绝对路径 -->
            <fileNamePattern>${log.path}/trace/log.%d{yyyy-MM-dd}.log</fileNamePattern>
            <!-- 可选节点，控制保留的归档文件的最大数量，超出数量就删除旧文件假设设置每个月滚动，且<maxHistory>是6，
            则只保存最近6个月的文件，删除之前的旧文件。注意，删除旧文件是，那些为了归档而创建的目录也会被删除-->
            <maxHistory>${log.history.max}</maxHistory>
        </rollingPolicy>
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>


    <!-- 项目日志级别 -->
    <logger name="com.apache.ibatis" level="TRACE"/>
    <logger name="java.sql.Connection" level="DEBUG"/>
    <logger name="java.sql.Statement" level="DEBUG"/>
    <logger name="java.sql.PreparedStatement" level="DEBUG"/>
    <logger name="com.ahao.project" level="INFO"/>

    <!-- root级别 INFO -->
    <root level="INFO">
        <!-- 控制台输出 -->
        <appender-ref ref="STDOUT" />
        <!-- 文件输出 -->
        <appender-ref ref="FILE_ERROR" />
        <appender-ref ref="FILE_INFO" />
        <appender-ref ref="FILE_WARN" />
        <appender-ref ref="FILE_DEBUG" />
        <appender-ref ref="FILE_TRACE" />
    </root>
</configuration>
```

# 参考资料
- [logback 中文手册下载](http://justcode.ikeepstudying.com/wp-content/uploads/2017/04/logback-中文手册.pdf)
- [logback 常用配置详解（序）logback 简介](http://aub.iteye.com/blog/1101222)
