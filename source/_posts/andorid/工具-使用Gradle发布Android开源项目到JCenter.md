---
title: 使用Gradle发布Android开源项目到JCenter
url: how_to_use_Gradle_to_publish_project_to_JCenter
tags:
  - 工具
categories:
  - 工具
date: 2016-08-03 20:18:25
---

# 登录
>使用bintray-release发布

使用`github`帐号登录https://bintray.com/ ，
你可以点击`Your Profile`->`Edit`->`API Key`，复制。
<!-- more -->

# AS
在最顶层的`gradle`中添加
```groovy
buildscript {
    repositories {...}
    dependencies {
        classpath 'com.android.tools.build:gradle:2.1.2'
        classpath 'com.novoda:bintray-release:0.3.4'//添加
    }
}
allprojects {
    repositories {...}
    tasks.withType(Javadoc) {//添加
        options{ encoding "UTF-8" charSet 'UTF-8' links "http://docs.oracle.com/javase/7/docs/api"
        }
    }
}
```

在想要上传的`module`添加
```groovy
apply plugin: 'com.android.library'
apply plugin: 'com.novoda.bintray-release'//添加
android {...}
dependencies {...}
publish {
    userOrg = 'ahaochan'
    groupId = 'com.ahaochan'
    artifactId = 'TabLayout'//项目名
    publishVersion = '0.0.2'//版本号
    desc = 'Imitate WeChat6.0 TabLayout'//描述
    website = 'https://github.com/Ahaochan/TabLayout'//github地址
}
```

最后在`AS`底下的`Terminal`中输入
```shell
 gradlew clean build bintrayUpload 
 -PbintrayUser=ahaochan
 -PbintrayKey=之前复制的key
 -PdryRun=false
```
