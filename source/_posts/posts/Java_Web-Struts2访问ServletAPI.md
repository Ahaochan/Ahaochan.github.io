---
title: Struts2访问ServletAPI
url: Struts2_how_to_aware_ServletAPI
tags:
  - Struts2
categories:
  - Java Web
date: 2017-01-08 19:17:46
---

# 前言
Servlet API就是HttpServletRequest(Request)、HttpSession(Session)、ServletContext(Application)
<!-- more -->

# 通过ActionContext类访问
```java
ActionContext ctx = ActionContext.getContext();//单例模式
//访问application
Map<String, Object> application = ctx.getApplication();//Map对象模拟ServletContext实例
application.put("key", value);
Object value = application.get("key");
ctx.setApplication(map);//传入一个新的Map
//访问Session
Map<String, Object> session= ctx.getSession();//Map对象模拟ServletContext实例
application.put("key", value);
Object value = application.get("key");
ctx.setSession(map);//传入一个新的Map
//访问Request
ctx.put("key", value);//类似调用request.putAttribute("key", value)
Object value = ctx.get("key");//类似调用request.getAttribute("key")
Map<String, Object> request = ctx.getParameters();//类似调用request.getParameterMap()
```

# 实现XxxAware接口
1. `ServletContextAware` ：直接访问`ServletContext(application)`  实例
1. `ServletRequestAware` ：直接访问`HttpServletRequest(request)`  实例
1. `ServletResponseAware`：直接访问`HttpServletResponse(response)`实例

# 通过ServletActionContext类访问
```java
PageContext pageContext      = ServletActionContext.getPageContext();
HttpServletRequest request   = ServletActionContext.getRequest();
HttpServletResponse response = ServletActionContext.getResponse();
ServletContext application   = ServletActionContext.getServletContext();
```
