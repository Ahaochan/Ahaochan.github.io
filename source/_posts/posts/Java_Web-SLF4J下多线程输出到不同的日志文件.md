---
title: 使用SLF4J在多线程下输出到不同的日志文件
url: Use_SLF4J_to_output_to_different_log_files_under_multi_threading
tags:
  - SLF4J
  - Logback
  - Log4j
categories:
  - Java Web
date: 2018-10-16 20:06:00
---

# 前言
最近做了个数据传输的模块, 用到了线程池多线程, 要求将市平台的文章导入到公司的项目中进行管理, 每个栏目都有对应的文章, 但是打印日志时出现了日志混乱的问题。
```text
栏目A传输文章1: 开始
栏目B传输文章2: 开始
栏目B传输文章2: 成功
栏目C传输文章3: 开始
栏目A传输文章1: 成功
栏目C传输文章3: 失败
```

<!-- more -->

# 思路
每个线程输出到不同的日志文件下, 这个功能应该是可以做到的, 只要在初始化`Logger`时指定对应的文件名就可以了。

# Logback 的实现(版本号1.1.11)
除了`Logback`的基础模块, 需要追加引用[`logback-access`](https://mvnrepository.com/artifact/ch.qos.logback/logback-access)模块。

`slf4j`提供了`Mapped Diagnostic Context (MDC)`这个工具, 来设置自定义变量。
```java
MDC.put("logName", "LogFile1");
logger.debug("Test" + System.currentTimeMillis());
MDC.remove("logName");
```
在代码中这样使用, 即可在配置文件中取到`value`。
`Logback`提供了`SiftingAppender`来进行日志记录, 并且可以读取`MDC`的值到日志路径的变量中。
下面代码是从我之前写的`Logback`日志配置中复制并加以微调的。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!-- 使用 MDC 的 appender -->
    <appender name="FILE_CUSTOM" class="ch.qos.logback.classic.sift.SiftingAppender">
        <!-- discriminator 的默认实现类 ch.qos.logback.classic.sift.MDCBasedDiscriminator -->
        <discriminator>
            <key>logName</key>
            <defaultValue>MyFile</defaultValue>
        </discriminator>
        <sift>
            <!-- 标准的文件输出 Appender, 文件名根据 MDC 动态生成  -->
            <appender name="FILE-${logName}" class="ch.qos.logback.core.rolling.RollingFileAppender">
                <file>自定义文件路径/${logName}.log</file>
                <!-- 最常用的滚动策略，它根据时间来制定滚动策略.既负责滚动也负责出发滚动 -->
                <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                    <!--日志输出位置  可相对、和绝对路径 -->
                    <fileNamePattern>自定义文件路径/%d{yyyy-MM-dd}/${logName}.log</fileNamePattern>
                </rollingPolicy>
                <encoder charset="UTF-8">
                    <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
                </encoder>
            </appender>
        </sift>
    </appender>

    <!-- root级别 INFO -->
    <root level="INFO">
        <!-- 文件输出 -->
        <appender-ref ref="FILE_CUSTOM" />
    </root>
</configuration>
```

# log4j的实现(版本号1.2.16)
`log4j`没有`SiftingAppender`, 并且也不能读取`MDC`到日志路径的变量中(但是可以读取到日志格式中)。

用编程的方式为每个对象示例初始化`Logger`, 然后为其添加`Appender`。
```java
public class MyTask {
    public org.apache.log4j.Logger getLogger(int id){
        org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger("日志"+id);
        logger.setLevel(Level.DEBUG);

        // 注意要判断是否已存在Appender, 否则会重复创建
        String appenderName = "log"+id+"Appender";
        if(logger.getAppender(appenderName) == null) {
            RollingFileAppender appender = new RollingFileAppender();
            appender.setName(appenderName);
            appender.setFile("D:\\mylog\\"+id+".log");
            appender.setLayout(new PatternLayout("[S][%d{yyyyMMdd HH:mm:ss}][%-5p][%C:%L] - %m%n"));
            appender.setMaxFileSize("10240KB");
            appender.setMaxBackupIndex(10);
            appender.activateOptions();
            logger.addAppender(appender);
        }
        return logger;
    }
}
```


# 参考资料
- [logback-different-log-file-for-each-thread](https://www.mkyong.com/logging/logback-different-log-file-for-each-thread)