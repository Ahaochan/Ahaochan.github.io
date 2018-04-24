---
title: IDEA的LiveTempleate自动生成代码
url: IDEA_LiveTempleate_Setting
tags:
  - IDEA
categories:
  - 工具
date: 2017-09-05 23:02:59
---

# 前言
Live Template是IDEA提供的一个自动生成代码的工具, 可以自定义一段小代码, 比如最常见的 ` System.out.println(""); ` ,  当然这已经被内置了, 输入 ` sout `即可输出。

<!-- more -->

# 自定义xml的存储位置
- Windows: 用户目录/.IntelliJ IDEA/config/templates
- Linux: ~IntelliJ IDEA/config/templates
- macOS: ~/Library/Preferences/IntelliJ IDEA/templates

当然这在[官方文档](https://www.jetbrains.com/help/idea/live-templates.html)中有提到

# 自定义Live Template
打开IDEA, 点击工具栏File -> Settings -> Editor -> Live Template, 点击右边的加号+。
输入下面的代码。
```java
private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger($CLASS_NAME$.class);
$END$
```
再点击右边的 ` Edit variables `, 选择 ` Expression ` 为 ` className() `
在代码中输入 ` logg ` 即可生成自动生成上面的代码, ` $CLASS_NAME$ ` 表示当前的类名。

# 自用的Live Template
```xml
<templateSet group="user">
  <template name="logg" value="private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger($CLASS_NAME$.class);&#10;$END$" description="log日志输出器" toReformat="false" toShortenFQNames="true">
    <variable name="CLASS_NAME" expression="className()" defaultValue="" alwaysStopAt="true" />
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="loge" value="logger.error(&quot;$END$&quot;);" description="log日志error级别" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="logw" value="logger.warn(&quot;$END$&quot;);" description="log日志warn级别" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="logi" value="logger.info(&quot;$END$&quot;);" description="log日志info级别" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="logd" value="logger.debug(&quot;$END$&quot;);" description="log日志debug级别" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="can" value="java.util.Scanner in = new java.util.Scanner(System.in);&#10;int n = in.nextInt();&#10;$END$" description="控制台输入" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="pra" value="java.util.Arrays.toString($END$)" description="打印数组" toReformat="false" toShortenFQNames="true">
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
  <template name="prm" value="for(java.util.Map.Entry entry : $VAR$.entrySet()){&#10;    System.out.println(entry.getKey()+&quot; : &quot;+entry.getValue());&#10;}" description="打印Map集合" toReformat="false" toShortenFQNames="true">
    <variable name="VAR" expression="" defaultValue="" alwaysStopAt="true" />
    <context>
      <option name="JAVA_CODE" value="true" />
    </context>
  </template>
</templateSet>
```

# 参考资料
- [官方文档](https://www.jetbrains.com/help/idea/live-templates.html)
