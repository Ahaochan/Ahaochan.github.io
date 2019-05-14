---
title: Shiro用户登陆后会话标识未更新漏洞
url: Shiro_not_update_session_id_after_login
tags:
  - Shiro
categories:
  - Java Web
date: 2019-03-28 22:32:53
---
# 前言
这是我在以前遇到的问题了, 当时做的是政府项目, 对`Web`安全要求比较高.
使用`Shiro`的项目被安全准入检测出**用户登陆后会话标识未更新漏洞**.
意思是登录前的`Session`和登录后的`Session`一样。

<!-- more -->

# 官方修复无望, 自己打补丁
`2010-05-24`提出的[SHIRO-170](https://issues.apache.org/jira/browse/SHIRO-170), 至今`2019-03-27`仍然未解决.
看来修复无望了, 但是勤劳的人民给出了临时性的解决方案.
那就是在登录时, 先销毁`session`, 再`login`.
主要步骤如下:
1. 获取`session`, 保存`session`中的属性`Map`
1. `session.stop()`销毁
1. 进行登录`subject.login(token)`
1. 将之前保存的属性`Map`, 重新注入新的`session`

具体代码可以查看我的个人代码库[LoginController.java#L91-L113](https://github.com/Ahaochan/project/blob/master/ahao-web/src/main/java/com/ahao/rbac/shiro/LoginController.java#L91-L113)

# 参考资料
- [Force New Session ID on Authentication](https://issues.apache.org/jira/browse/SHIRO-170)
- [解决shiro会话标识未更新问题](https://blog.csdn.net/yycdaizi/article/details/45013397)
- [Shiro complaining “There is no session with id xxx” with DefaultSecurityManager](https://stackoverflow.com/a/30672822/6335926)
