---
title: JSP的Java Bean学习总结
url: The_Java_Bean_of_JSP
tags:
  - JSP
categories:
  - Java Web
date: 2016-11-30 14:18:53
---

# 使用
预先创建`Person`类
```java
public class Person(){
    string name;
    int age;
    //get方法、set方法、构造方法
}
```
<!-- more -->

## 普通方式使用
并在`JSP`中使用，就像`Java`程序一样
```html
<@page import="包名.Person"><%--先导包--%>
<html><head><%--省略--%></head>
<body>
   <%
        Person p1 = new Person("小明",12);
        out.println("姓名:"+p1.getName()+"，年龄:"+p1.getAge());
   %>
</body></html>
```

## 通过JSP动作标签使用
使用`<jsp:useBean>`声明，`<jsp:setProperty>`设置属性，使用`<jsp:getProperty>`获取属性
并且不用`<@page import="">`导包

首先新建个`submit.jsp`页面，写一个`form`表单
```html
<html><head><%--省略--%></head>
<body>
    <form name="submitForm" action="doSubmit.jsp" method="post">
        <input type="text" name="name"/><br/>
        <input type="text" name="age"/><br/>
        <input type="submit" value="提交"/>
    </form>
</body>
</html>
```
然后在`doSubmit.jsp`页面中获取`form`中传递的数据
```html
<html><head><%--省略--%></head>
<body>
    <jsp:useBean id="p2" class="包名.Person" scope="作用范围" /><%--相当于Person p2 = new Person();--%>
    <%--scope默认值是page，可选page、request、session、application--%>

    <jsp:setProperty name="p2" property="*" /><%--第一种方法--%>
    <%--通配符*会自动将form中的name和JavaBean中的属性自动配对--%>
    <jsp:getProperty name="p2" property="name" /><%--相当于p2.getName()--%>
    <jsp:getProperty name="p2" property="age" /><%--相当于p2.getAge()--%>

    <jsp:setProperty name="p2" property="name" /><%--第二种方法--%>
    <jsp:setProperty name="p2" property="age" /><%--将form中的name和JavaBean中的属性自动配对--%>
    <jsp:getProperty name="p2" property="name" /><%--相当于p2.getName()--%>
    <jsp:getProperty name="p2" property="age" /><%--相当于p2.getAge()--%>

    <jsp:setProperty name="p2" property="name" value="小红" /><%--第三种方法--%>
    <jsp:setProperty name="p2" property="age" value="10" /><%--手动设置属性--%>
    <jsp:getProperty name="p2" property="name" /><%--相当于p2.getName()--%>
    <jsp:getProperty name="p2" property="age" /><%--相当于p2.getAge()--%>

    <jsp:setProperty name="p2" property="name" param="name" /><%--第四种方法--%>
    <jsp:setProperty name="p2" property="age" param="age"/><%--通过request获取传递参数--%>
    <jsp:getProperty name="p2" property="name" /><%--相当于p2.getName()--%>
    <jsp:getProperty name="p2" property="age" /><%--相当于p2.getAge()--%>
</body></html>
```

# 总结
## 使用普通方式和Java程序一样。
## 使用jsp:setProperty标签
1. 运用通配符`*`实现完全匹配，表单`form`的`name`属性名、`JavaBean`的属性名要完全一致。
1. 运用通配符`*`实现部分匹配，表单`form`的`name`属性名、`JavaBean`的属性名、`jsp:setProperty`的`property`属性值要完全一致。
1. 手动设置，和表单`form`无关，和普通方式使用情景一样。
1. 从`request`中获取，param的属性值只要和`request`的属性值一致即可，不用和`JavaBean`的属性值保持一致，无论`get`、`post`都可以。
