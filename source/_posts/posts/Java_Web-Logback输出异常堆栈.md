---
title: Logback输出异常堆栈
url: Logback_how_to_output_exception_stack
tags:
  - Logback
categories:
  - Java Web
date: 2017-09-05 22:53:13
---

# 前言
今天来到公司, 老大和我说SpringBoot的短信项目没有日志输出, 赶紧火急火燎的排错。
<!-- more -->

# 先排查logback.xml
```xml
<!-- root级别 INFO -->
<root level="INFO">
    <!-- 控制台输出 -->
    <appender-ref ref="STDOUT" />
    <!-- 文件输出 -->
    <appender-ref ref="FILE_TRACE" />
    <appender-ref ref="FILE_DEBUG" />
    <appender-ref ref="FILE_INFO" />
    <appender-ref ref="FILE_WARN" />
    <appender-ref ref="FILE_ERROR" />
</root>
```
日志输出级别是 ` INFO `, 按理是没什么问题的, 为了稳妥起见, 改为 `DEBUG`。
```xml
<!-- root级别 DEBUG -->
<root level="DEBUG">
    <!-- 控制台输出 -->
    <appender-ref ref="STDOUT" />
    <!-- 文件输出 -->
    <appender-ref ref="FILE_TRACE" />
    <appender-ref ref="FILE_DEBUG" />
    <appender-ref ref="FILE_INFO" />
    <appender-ref ref="FILE_WARN" />
    <appender-ref ref="FILE_ERROR" />
</root>
```

# 检查application.yml
```yml
# 日志 配置
logging:
  level:
    com.nine.rivers.galaxy: info
    org.springframework: warn
```
发现了这一段, 估计是在摸石头过河阶段加入的, 后来用 ` logback.xml ` 的时候没有删除掉。
有句话说得好, 如果你自己都搞不清楚程序要做什么, 程序自己肯定也会搞糊涂
统一一个日志配置文件, 把 ` application.yml ` 中的这一段删掉。

# 异常日志输出
改完后发现普通的日志输出没有问题, 但是不能输出异常堆栈。
```java
try {
    // do Something
} catch (IllegalAccessException e) {
    e.printStackTrace(); // 注意这里
    logger.error("反射获取参数错误, 请检查field的权限修饰符:" + e.getMessage());
} 
```
在使用 ` System.out.println() ` 输出日志的阶段, 我一直都是使用 ` e.printStackTrace() ` 输出的。
改用 ` log ` 输出日志之后, 没有意识到 ` e.printStackTrace() ` 其实是 ` System.err.println() `, 没有输出到日志。
改为如下代码即可。
```java
try {
    // do Something
} catch (IllegalAccessException e) {
    logger.error("反射获取参数错误, 请检查field的权限修饰符:", e);
} 
```

## 初探源码
` e.printStackTrace() ` 这个方法是在父类 ` Throwable ` 中实现的。
很明显看到 ` System.err ` 的字样。更深入异常的体系结构暂不分析。
```java
// java.lang.Throwable
public class Throwable implements Serializable {
    public void printStackTrace() {
        // 是不是和System.out很像
        // 调用第9行的代码
        printStackTrace(System.err);
    }
    
    public void printStackTrace(PrintStream s) {
        // WrappedPrintStream 是 Throwable 的私有静态内部类, 包装了一个PrintStream对象
        // 调用第15行的代码
        printStackTrace(new WrappedPrintStream(s));
    }
    
    private void printStackTrace(PrintStreamOrWriter s) {
        // Guard against malicious overrides of Throwable.equals by
        // using a Set with identity equality semantics.
        Set<Throwable> dejaVu = Collections.newSetFromMap(new IdentityHashMap<Throwable, Boolean>());
        dejaVu.add(this);

        synchronized (s.lock()) {
            // 打印自身
            s.println(this);
            StackTraceElement[] trace = getOurStackTrace();
            for (StackTraceElement traceElement : trace)
                // 打印当前的异常信息
                s.println("\tat " + traceElement);

            // 打印被抑制（可能是try住的）的所有的异常信息
            for (Throwable se : getSuppressed())
                se.printEnclosedStackTrace(s, trace, SUPPRESSED_CAPTION, "\t", dejaVu);

            // 打印异常的原因
            Throwable ourCause = getCause();
            if (ourCause != null)
                ourCause.printEnclosedStackTrace(s, trace, CAUSE_CAPTION, "", dejaVu);
        }
    }
}
```
