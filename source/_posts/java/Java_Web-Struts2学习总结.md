---
title: Struts2学习总结
url: Struts2_summarize
tags:
  - Struts2
categories:
  - Java Web
date: 2017-03-02 19:20:34
---

# Action搜索顺序
```xml
<struts>
    <package name="default" namespace="/test">
        <action name="myAction" />
    </package>
</struts>
```
<!-- more -->
访问`http://localhost:8080/test/aaa/bbb/ccc/myAction`时，先查找`ccc`命名空间的包下有没有`myAction`。没有再找到`bbb`，再找`aaa`。都找不到`myAction`。这时找到`test`命名空间的包下，找到了`myAction`，搜索结束。如果还是没有找到`myAction`，则往默认命名空间下找，找不到抛出。

# result的type属性
```xml
<struts>
    <package name="default" namespace="/test">
        <action name="myAction">
            <result type="dispatcher">/index.jsp</result>
            <result name="error" type="redirect">/index.jsp?username=${username}</result>
        </action>
    </package>
</struts>
```
默认情况下是转发（`dispatcher`）。
- 重定向是`redirect`，可以用`${username}`传递`Action`中的属性，中文记得使用`URLEncoder.encode("中文", "UTF-8")`。
- 重定向`Action`是`redirectAction`，在`result`标签下的`namespace`标签可以指定其他命名空间的`Action`。
- 查看源码是`plainText`，中文要在`result`标签加上`<param name="charSet">UTF-8</param>`
