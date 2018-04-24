---
title: IDEA的基本配置
url: IDEA_common_setting
tags:
  - IDEA
categories:
  - 工具
date: 2017-09-05 22:59:29
---

# 版本选择

选择: [2017.3](https://www.jetbrains.com/idea/download/previous.html)
激活: [http://idea.liyang.io/](http://idea.liyang.io/)

<!-- more -->

# 字体颜色设置
1. 设置主题: File -> Settings -> Appearence&Behavior -> Appearence, 选择 ` Darcula `暗色背景
2. 设置代码字体: File -> Settings -> Editor -> Font, 设置 ` font ` 为 ` Consolas ` ,  ` Size ` 为 ` 16 `。
3. 设置控制台字体: File -> Settings -> Editor -> Color Scheme -> Console Font, 设置 ` font ` 为 ` Consolas ` ,  ` Size ` 为 ` 14 `。

# 配置Git
在 File -> Settings -> Version Control -> Git -> Path to Git executable 添加 `Git路径\bin\git.exe`。

# 中文输入法配置
` 2017.2 `不支持中文输入法候选框的显示。
1. 找到IDEA在本地安装路径(先把IDEA关闭)
2. 在IDEA安装路径中把jre64文件删除,或者重命名(万一不行可以再改回来…)
3. 找到本地java安装路径,把jre文件夹复制一份.(java安装路径里有jdk和jre的文件夹)
4. 把复制的jre文件夹粘贴在刚才修改jre64位置,重命名为jre64(这样IDEA启动就能找到它)
5. 在java安装路径中找到jdk文件-再找到lib文件-找到tools.jar文件,复制一份
6. 把jar包粘贴到已经重命名过的jre64/lib下
7. 打开IDEA,写一段代码,然后写一段中文注释试试,问题解决~
  
# maven设置
在 ` IntelliJ IDEA ` 文件夹下新建文件夹 ` mvnlib `,
打开 ` IntelliJ IDEA\plugins\maven\lib\maven2\conf\settings.xml ` (maven3同理) , 添加如下xml, 注意层级结构
```xml
<settings>
    <!-- maven的下载路径, 默认下载在C盘用户目录下 -->
    <localRepository>mvnlib的目录</localRepository>
    
    <!-- 阿里云的maven镜像仓库 -->
    <mirrors>
        <mirror>
            <id>alimaven</id>
            <name>aliyun maven</name>
            <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
            <mirrorOf>central</mirrorOf>        
        </mirror>
    </mirrors>
</settings>
```
# 插件
- [热部署jrebel](https://plugins.jetbrains.com/plugin/4441-jrebel-for-intellij): 用Twitter或者Facebook登录[获取注册码](https://my.jrebel.com/account/how-to-activate)即可。
- [findbugs](https://plugins.jetbrains.com/plugin/3847-findbugs-idea): 找到隐藏比较深的bug
- [Grep Console](https://plugins.jetbrains.com/plugin/7125-grep-console): 输出彩色日志
- [ECTranslation](https://github.com/Skykai521/ECTranslation): 翻译插件
- [BashSupport](https://github.com/jansorg/BashSupport): 执行shell

- [MyBatis插件](https://plugins.jetbrains.com/plugin/7293-mybatis-plugin): 照着说明复制粘贴即可破解, [github地址](https://github.com/myoss/profile)(失效)

# Live Template
- Windows: 用户目录/.IntelliJ IDEA/config/templates
- Linux: ~IntelliJ IDEA/config/templates
- macOS: ~/Library/Preferences/IntelliJ IDEA/templates
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
- [IntelliJ IDEA 2017.2.5 中文输入后,输入框文字不随指针显示问题](http://blog.csdn.net/weixin_39641494/article/details/78435941)