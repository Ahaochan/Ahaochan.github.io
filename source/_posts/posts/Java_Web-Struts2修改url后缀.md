---
title: Struts2修改url后缀
url: Struts2_how_to_custom_url_suffix
tags:
  - Struts2
categories:
  - Java Web
date: 2017-01-08 19:15:43
---
# 前言
使用struts2的url一般为`http://localhost:8080/test.action`
有时候需要改为`http://localhost:8080/test.html`
<!-- more -->

# 在struts.xml中配置
```xml
<struts>
    <constant name="struts.action.extension" value="html">
</struts>
```

# 在struts.properties中配置
```
struts.action.extension=action,do,struts2,
```

# 在web.xml的filter中配置
```xml
<filter>
    <filter-name>struts2</filter-name>
    <filter-class>org.apache.struts2.dispatcher.ng.filter.StrutsPrepareAndExecuteFilter</filter-class>
    <init-param>
        <param-name>struts.action.extension</param-name>
        <param-value>action,do,struts2,</param-name>
   </init-param>
</filter>

```
