---
title: Struts2接收参数
url: Struts2_how_to_access_parameters
tags:
  - Struts2
categories:
  - Java Web
date: 2017-01-08 19:13:54
---

# 使用Action的属性接收参数
```html
<!--表单loginJSP.jsp-->
<form action="myAction" method="post">
    <input type="text" name="username"/>
    <input type="password" name="password" />
    <input type="submit" value="提交" />
</form>
```
<!-- more -->
```java
public class MyAction extends ActionSupport{
    private String username;
    private String password;
    public String execute() throws Exception{
        System.out.println(getUsername()+":"+getPassword());
        return SUCCESS;
    }
    //getter和setter方法，重要！Struts2是通过反射完成的！
}
```

# 使用Domain Model接收参数
```html
<!--表单loginJSP.jsp-->
<form action="myAction" method="post">
    <input type="text" name="user.username"/><!--指定对象名-->
    <input type="password" name="user.password" /><!--指定对象名-->
    <input type="submit" value="提交" />
</form>
```
```java
public class User{
    private String username;
    private String password;
    //getter和setter方法，重要！Struts2是通过反射完成的！
}
public class MyAction extends ActionSupport{
    private User user;
    public String execute() throws Exception{
        System.out.println(user.getUsername()+":"+user.getPassword());
        return SUCCESS;
    }
    //getter和setter方法，重要！Struts2是通过反射完成的！
}
```

# 实现ModelDriven接口接收参数
```html
<!--表单loginJSP.jsp-->
<form action="myAction" method="post">
    <input type="text" name="username"/><!--不用指定对象名-->
    <input type="password" name="password" /><!--不用指定对象名-->
    <input type="submit" value="提交" />
</form>
```
```java
public class User{
    private String username;
    private String password;
    //getter和setter方法，重要！Struts2是通过反射完成的！
}
public class MyAction extends ActionSupport implements ModelDriven<User>{
    private User user = new User();
    public String execute() throws Exception{
        System.out.println(user.getUsername()+":"+user.getPassword());
        return SUCCESS;
    }
    //去掉getter和setter方法，需自己new User
    public User getModel(){
        return user;
    }
}
```

