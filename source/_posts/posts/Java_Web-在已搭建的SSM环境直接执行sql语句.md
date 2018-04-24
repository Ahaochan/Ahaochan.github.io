---
title: 在已搭建的SSM环境直接执行sql语句
url: execute_sql_statement_in_SSM_environment
tags:
  - Spring MVC
categories:
  - Java Web
date: 2018-02-03 14:47:32
---
# 前言
这几天遇到个需求, 需要用`Java`代码对数据处理后批量执行一些`SQL`语句, 这种是一次性的需求。
写一个`Mapper.xml`又显得太繁琐。自己写`JDBC`又要重新加载数据库驱动创建数据库连接，更累。

<!-- more -->

# 思路
编写`Class`代码不可取。缺点有二:
1. 修改`Class`需要重启`Tomcat`。
2. 需要把`Class`设置为一个`Controller`。

改为使用`JSP`。以上两个缺点都没了。

# 使用JdbcTemplate
因为是一次性的需求。写一个`Mapper.xml`又显得太繁琐。干脆就直接舍弃获取`Mybatis SqlSession`的方式。
使用`Spring Jdbc`自带的`JdbcTemplate`。

在`Spring`配置文件中添加`JdbcTemplate Bean`。
```xml
<bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
    <constructor-arg name="dataSource" ref="dataSource"/>
</bean>
```

在`JSP`页面获取这个`Bean`
```java
<%@page language="java" contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // 1. 获取上下文
    WebApplicationContext context = WebApplicationContextUtils.getWebApplicationContext(getServletConfig().getServletContext());
    // 2. 获取Bean
    JdbcTemplate template = (JdbcTemplate) context.getBean("jdbcTemplate");
    // 3. 执行sql语句 ( 使用fastjson转化为json格式 ) 
    List list = template.queryForList("select * from mytable");
    out.print("测试:"+ JSONObject.toJSONString(list));
%>
```