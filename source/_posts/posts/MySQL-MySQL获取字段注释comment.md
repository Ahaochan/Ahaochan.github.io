---
title: MySQL获取字段注释comment
url: MySQL_how_to_get_comment_of_table
tags:
  - MySQL
categories:
  - MySQL
date: 2017-05-14 09:16:41
---

# 前言
web开发经常需要用到`<table>`显示数据。而`<th>`经常使用的是硬编码方式写死在代码中。
MySQL支持将添加字段注释，可获取注释信息，用来动态修改`<th>`的标题。
<!-- more -->

# 使用
现在有一张学生表
```sql
create table student(
    sid int comment 'student_id',
    name varchar(20) comment 'student_name'
    tid int comment 'teacher_id'
);
```
需要获取字段注释
```
List<String> comments = studentDao.getComments();
//[student_id, student_name, teacher_id]
```

通过以下sql语句即可完成
```sql
select column_comment
from information_schema.columns
where table_schema = database()
and table_name = 'student';
```
