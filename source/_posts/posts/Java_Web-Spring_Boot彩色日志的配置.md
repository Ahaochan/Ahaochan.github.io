---
title: Spring Boot彩色日志的配置
url: Spring_Boot_color_log_configuration
tags:
  - Spring Boot
categories:
  - Java Web
date: 2017-08-31 21:17:54
---

# 前言
{% img /images/SpringBoot彩色日志的配置_01.png %}

<!-- more -->
Spring Boot提供了彩色日志的功能, 可以达到上面的效果

# logback.xml
在 ` resource ` 文件夹加入 ` logback.xml `, Spring Boot 会自动去加载配置文件。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false">
    <!-- 设置上下文名称 -->
    <contextName>${log.context.name}</contextName>

    <!--定义日志文件的存储地址 勿在 LogBack 的配置中使用相对路径-->
    <property name="LOG_PATH" value="/LOG" />
    <property name="log.context.name" value="MyApp" />
    <property name="log.charset" value="UTF-8" />
    <!-- Log4j: [S][%d{yyyyMMdd HH:mm:ss}][%-5p][%C:%L] - %m%n -->
    <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符-->
    <property name="log.pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n" />
    <property name="log.pattern.short" value="%date{yyyyMMdd HH:mm:ss.SSS}-%msg%n" />
    <!-- 彩色日志格式 -->
    <property name="log.pattern.color" value="${CONSOLE_LOG_PATTERN:-%clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} %clr(${LOG_LEVEL_PATTERN:-%5p}) %clr(${PID:- }){magenta} %clr(---){faint} %clr([%15.15t]){faint} %clr(%-40.40logger{39}){cyan} %clr(:){faint} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}}" />

    <!-- 控制台输出 -->
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder charset="${log.charset}">
            <pattern>${log.pattern}</pattern>
        </encoder>
    </appender>
    <appender name="STDOUT_SHORT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder charset="${log.charset}">
            <pattern>${log.pattern.short}</pattern>
        </encoder>
    </appender>
    <!-- 彩色日志 -->
    <!-- 彩色日志依赖的渲染类 -->
    <conversionRule conversionWord="clr" converterClass="org.springframework.boot.logging.logback.ColorConverter" />
    <conversionRule conversionWord="wex" converterClass="org.springframework.boot.logging.logback.WhitespaceThrowableProxyConverter" />
    <conversionRule conversionWord="wEx" converterClass="org.springframework.boot.logging.logback.ExtendedWhitespaceThrowableProxyConverter" />
    <!-- Console 输出设置 -->
    <appender name="STDOUT_COLOR" class="ch.qos.logback.core.ConsoleAppender">
        <encoder charset="${log.charset}">
            <pattern>${log.pattern.color}</pattern>
        </encoder>
    </appender>

    <!--mybatis log configure-->
    <logger name="com.apache.ibatis" level="TRACE"/>
    <logger name="java.sql.Connection" level="DEBUG"/>
    <logger name="java.sql.Statement" level="DEBUG"/>
    <logger name="java.sql.PreparedStatement" level="DEBUG"/>

    <!-- 日志输出级别 -->
    <root level="INFO">
        <appender-ref ref="STDOUT_COLOR" />
    </root>
</configuration>
```

# 在application.yml启用彩色日志
```yml
spring.output.ansi.enabled: detect
```
` spring.output.ansi.enabled ` 有三个候选项
1. NEVER：禁用ANSI-colored输出（默认项）
2. DETECT：会检查终端是否支持ANSI，是的话就采用彩色输出（推荐项）
3. ALWAYS：总是使用ANSI-colored格式输出，若终端不支持的时候，会有很多干扰信息，不推荐使用

# Tomcat不支持彩色日志
直接运行 ` main ` 函数的话,日志可以彩色输出, 但是在IDEA部署到 ` Tomcat  ` 的时候, IDEA的控制台没有彩色日志, 如果强制打开彩色日志, 则会出现很多干扰信息。

IDEA提供了个曲线救国的插件[Grep Console](https://plugins.jetbrains.com/plugin/7125-grep-console), 安装即可, 在IDEA的控制台渲染彩色日志, 在Tomcat不显示彩色日志。
![QQ拼音截图未命名.png](http://upload-images.jianshu.io/upload_images/6879007-ee8783eca30e0a70.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

如果在Linux上使用, 还有另一种曲线救国的方法。这种就不详细讨论了。
[Linux 日志高亮工具 CCZE](https://github.com/cornet/ccze)

# 有趣的Banner
使用过Spring Boot就会发现每次项目启动时，控制台都会有一个大大的**Spring**的字符画。
Spring Boot也提供了自定义的方法, 在 ` resource/banner.txt ` 写入想显示的字符画, 就可以自动加载并显示出来。
**注意Tomcat不支持彩色日志**
## 佛祖保佑
```
////////////////////////////////////////////////////////////////////
//                          _ooOoo_                               //
//                         o8888888o                              //
//                         88" . "88                              //
//                         (| ^_^ |)                              //
//                         O\  =  /O                              //
//                      ____/`---'\____                           //
//                    .'  \\|     |//  `.                         //
//                   /  \\|||  :  |||//  \                        //
//                  /  _||||| -:- |||||-  \                       //
//                  |   | \\\  -  /// |   |                       //
//                  | \_|  ''\---/''  |   |                       //
//                  \  .-\__  `-`  ___/-. /                       //
//                ___`. .'  /--.--\  `. . ___                     //
//              ."" '<  `.___\_<|>_/___.'  >'"".                  //
//            | | :  `- \`.;`\ _ /`;.`/ - ` : | |                 //
//            \  \ `-.   \_ __\ /__ _/   .-` /  /                 //
//      ========`-.____`-.___\_____/___.-`____.-'========         //
//                           `=---='                              //
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^        //
//            佛祖保佑       永不宕机     永无BUG                  //
////////////////////////////////////////////////////////////////////
```

## jhipster(不支持Tomcat)
```
${AnsiColor.GREEN}      ██╗${AnsiColor.RED} ██╗   ██╗ ████████╗ ███████╗   ██████╗ ████████╗ ████████╗ ███████╗
${AnsiColor.GREEN}      ██║${AnsiColor.RED} ██║   ██║ ╚══██╔══╝ ██╔═══██╗ ██╔════╝ ╚══██╔══╝ ██╔═════╝ ██╔═══██╗
${AnsiColor.GREEN}      ██║${AnsiColor.RED} ████████║    ██║    ███████╔╝ ╚█████╗     ██║    ██████╗   ███████╔╝
${AnsiColor.GREEN}██╗   ██║${AnsiColor.RED} ██╔═══██║    ██║    ██╔════╝   ╚═══██╗    ██║    ██╔═══╝   ██╔══██║
${AnsiColor.GREEN}╚██████╔╝${AnsiColor.RED} ██║   ██║ ████████╗ ██║       ██████╔╝    ██║    ████████╗ ██║  ╚██╗
${AnsiColor.GREEN} ╚═════╝ ${AnsiColor.RED} ╚═╝   ╚═╝ ╚═══════╝ ╚═╝       ╚═════╝     ╚═╝    ╚═══════╝ ╚═╝   ╚═╝
```

## 彩虹猫(不支持Tomcat)
```
${AnsiColor.BRIGHT_BLUE}████████████████████████████████████████████████████████████████████████████████
${AnsiColor.BRIGHT_BLUE}████████████████████████████████████████████████████████████████████████████████
${AnsiColor.RED}██████████████████${AnsiColor.BRIGHT_BLUE}████████████████${AnsiColor.BLACK}██████████████████████████████${AnsiColor.BRIGHT_BLUE}████████████████
${AnsiColor.RED}████████████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████████████████████████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██████████████
${AnsiColor.BRIGHT_RED}████${AnsiColor.RED}██████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.MAGENTA}██████████████████████${AnsiColor.WHITE}██████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████████████
${AnsiColor.BRIGHT_RED}██████████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.MAGENTA}████████████████${AnsiColor.BLACK}████${AnsiColor.MAGENTA}██████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██${AnsiColor.BLACK}████${AnsiColor.BRIGHT_BLUE}██████
${AnsiColor.BRIGHT_RED}██████████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.MAGENTA}██████${AnsiColor.WHITE}██${AnsiColor.BLACK}████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████
${AnsiColor.BRIGHT_YELLOW}██████████████████${AnsiColor.BRIGHT_RED}████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.MAGENTA}██████${AnsiColor.WHITE}██${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████
${AnsiColor.BRIGHT_YELLOW}██████████████████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_YELLOW}██████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}████████${AnsiColor.WHITE}████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████
${AnsiColor.BRIGHT_YELLOW}████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.BLACK}██${AnsiColor.BRIGHT_YELLOW}████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████████████████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████
${AnsiColor.BRIGHT_GREEN}██████████████████${AnsiColor.BRIGHT_YELLOW}██${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.BLACK}████████${AnsiColor.WHITE}██${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████████████████████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██
${AnsiColor.BRIGHT_GREEN}██████████████████████${AnsiColor.WHITE}████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BRIGHT_YELLOW}██${AnsiColor.WHITE}██████████${AnsiColor.BRIGHT_YELLOW}██${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██
${AnsiColor.BRIGHT_GREEN}██████████████████████${AnsiColor.BLACK}████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.BLACK}████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██
${AnsiColor.BLUE}██████████████████${AnsiColor.BRIGHT_GREEN}████████${AnsiColor.BLACK}██████${AnsiColor.WHITE}██${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.MAGENTA}████${AnsiColor.WHITE}████████████████${AnsiColor.MAGENTA}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██
${AnsiColor.BLUE}██████████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}████████████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████
${AnsiColor.BRIGHT_BLUE}██████████████████${AnsiColor.BLUE}████${AnsiColor.BLUE}██████${AnsiColor.BLACK}████${AnsiColor.WHITE}██████${AnsiColor.MAGENTA}██████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████████████████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██████
${AnsiColor.BRIGHT_BLUE}██████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██${AnsiColor.BLACK}████${AnsiColor.WHITE}████████████████████${AnsiColor.BLACK}██████████████████${AnsiColor.BRIGHT_BLUE}████████
${AnsiColor.BRIGHT_BLUE}████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}██████${AnsiColor.BLACK}████████████████████████████████${AnsiColor.WHITE}██${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████████████
${AnsiColor.BRIGHT_BLUE}████████████████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}██${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.BRIGHT_BLUE}████████████${AnsiColor.BLACK}██${AnsiColor.WHITE}████${AnsiColor.BLACK}████${AnsiColor.WHITE}████${AnsiColor.BLACK}██${AnsiColor.BRIGHT_BLUE}████████████
${AnsiColor.BRIGHT_BLUE}████████████████████████${AnsiColor.BLACK}██████${AnsiColor.BRIGHT_BLUE}████${AnsiColor.BLACK}██████${AnsiColor.BRIGHT_BLUE}████████████${AnsiColor.BLACK}██████${AnsiColor.BRIGHT_BLUE}████${AnsiColor.BLACK}██████${AnsiColor.BRIGHT_BLUE}████████████
████████████████████████████████████████████████████████████████████████████████
${AnsiColor.BRIGHT_BLUE}:: Meow :: Running Spring Boot ${spring-boot.version} :: \ö/${AnsiColor.BLACK}
```

# 参考资料
- [Banner 生成器](https://devops.datenkollektiv.de/banner.txt/index.html)
- [jhipster](https://github.com/PierreBesson/generator-jhipster-banner/blob/master/generators/app/templates/_banner.txt)
- [彩虹猫](https://github.com/snicoll-demos/spring-boot-4tw-uni/blob/master/spring-boot-4tw-web/src/main/resources/banner.txt)
