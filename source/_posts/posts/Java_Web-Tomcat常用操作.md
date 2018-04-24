---
title: Tomcat常用操作
url: Tomcat_common_setting
tags:
  - Tomcat
categories:
  - Java Web
date: 2017-02-24 20:03:18
---

# 更改端口号
`Tomcat`默认端口号为`8080`，在`Tomcat`目录的`/conf/server.xml`中配置。
找到如下代码，将`8080`改为想要修改的端口号即可
<!-- more -->
```xml
<Service name="Catalina">
<!--省略无关代码-->
<Connector port="8080" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
<!--省略无关代码-->
</Service>
```

# 外部应用
`Tomcat`默认应用在`webapps`文件夹中，如果在外部编写`javaweb`应用，需要在`/conf/server.xml`编写代码，或者`/conf/Catalina/localhost`中创建`xml`文件。
在地址栏输入对应`url`即可访问。
## 在server.xml中配置
```xml
<Service name="Catalina">
<Engine name="Catalina" defaultHost="localhost">
    <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">
        <!-- <Context path="url路径名"　docBase="实际项目在磁盘中地址" /> -->
        <Context path="helloWorld"　docBase="C:/HelloWorld" />
    </Host>
</Engine>
</Service>
```

## 在catalina/localhost中配置
创建一个以`url`路径名命名的`xml`文件`helloWorld.xml`
```xml
<Context docBase="C:/HelloWorld" />
```

# 映射虚拟主机
浏览器使用`80`端口，如`http://www.test.com`和`http://www.test.com:80`等价。
在`%windir%\system32\drivers\etc\hosts`中添加`127.0.0.1 http://www.test.com`
在`server.xml`中配置新的`host`信息
```xml
<Service name="Catalina">
<Engine name="Catalina" defaultHost="localhost">
    <Host name="www.test.com"  appBase="C:/helloworld"
            unpackWARs="true" autoDeploy="true">
    </Host>
</Engine>
</Service>
```
