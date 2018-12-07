---
title: Tomcat部署web项目的方法
url: The_ways_of_deploy_Web_project_with_Tomcat
tags:
  - Tomcat
categories:
  - Java Web
date: 2017-08-30 21:32:08
---

# 内部应用
直接把war包复制粘贴到`Tomcat 8.5/webapps`目录下, 然后执行`Tomcat 8.5/bin/startup.bat`即可。

<!-- more -->

# 外部应用
- docBase: 项目文件夹实际的位置, 子目录为`WEB-INF`、`META-INF`的一个目录。
- path: 虚拟路径, 浏览器访问本项目的路径, 上面例子为`http://本机地址:端口/hello`

## 配置conf/server.xml(官方不推荐)
打开`Tomcat 8.5/conf/server.xml`, 在`<Host>`标签插入`<Context>`标签。
```xml
<Service name="Catalina">
    <Engine name="Catalina" defaultHost="localhost">
        <Host name="localhost"  appBase="webapps"
                unpackWARs="true" autoDeploy="true">
            <!-- <Context path="url路径名"　docBase="实际项目在磁盘中地址" /> -->
            <Context path="/hello" docBase="war包解压路径" reloadable="true" privileged="true"/>
        </Host>
    </Engine>
</Service>
```

## 配置conf/context.xml
打开`conf/context.xml`可以看到里面已经配置了一个`Context`.
如果一个`Tomcat`只配置一个`Web`应用程序, 则可以直接修改这里的代码.
```xml
<Context>
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <WatchedResource>${catalina.base}/conf/web.xml</WatchedResource>
</Context>
```
改为
```xml
<Context path="/hello" docBase="war包解压路径" reloadable="true" privileged="true">
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <WatchedResource>${catalina.base}/conf/web.xml</WatchedResource>
</Context>
```

## 配置conf/enginename/hostname/test.xml(推荐)
其实就是将`conf/server.xml`翻译一下。

打开`Tomcat 8.5/conf/Catalina/localhost`, 没有则自己创建目录, 新建一个`test.xml`文件。
这里的`Catalina`对应上面的`Engine`名, `localhost`对应上面的`Host`名.
访问路径为`http://localhost:8080/test`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Context path="/" docBase="war包解压路径" reloadable="true" privileged="true"/>
```

# 参考资料
- [tomcat部署web项目的3种方法](http://blog.csdn.net/wjx85840948/article/details/6749964)
