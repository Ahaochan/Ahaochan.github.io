---
title: MySQL常用语句
url: common_MySQL_command
tags:
  - MySQL
categories:
  - MySQL
date: 2016-12-20 08:15:25
---

# 简介
本文记录常用MySQL语句

<!-- more -->

# 用户权限
```sql
# 创建用户
create user user_name@ip_address identified by 'password'; # 用户通过指定ip地址登录 
create user user_name@'%'        identified by 'password'; # 用户通过任意ip地址登录 

# 删除用户
drop user user1@localhost; # 删除用户user1

# 用户授权
grant create,alter,drop,insert,update,delete,select on mydb.* to user1@localhost; # 分配mydb所有表的指定权限给user1
grant all on mydb.* to user2@localhost; # 分配mydb数据库所有表的所有权限给user2

# 撤销权限
revoke create on mydb.* from user1@localhost; # 撤销user1对mydb所有表的create权限 

# 查看权限
show grants for user1@localhost; # 查看user1的权限 
```

# 数据库
```sql
# 创建数据库
create database [if not exists] db_name [charset=utf8];

# 删除数据库
drop database [if exists] db_name;

# 修改数据库编码
alter database db_name character set utf8
```

# 表
```sql
# 常用建表
create table [模式名.]表名
(
    /* 可以有多个列定义 */
    /* 列名 数据类型 [列级约束] */
    columnName1 datatype [default expr]
)

# 子查询建表
create table [模式名.]表名
as
subquery # 如 select * from 表

# 修改表结构
## 表改名
alter table 表名 rename to 新表名

## 添加列
## 新增列不可指定非空约束，除非有默认约束
alter table 表名
add
(
    /* 可以有多个列定义 */
    /* 列名 数据类型 [列级约束] */
    columnName1 datatype [default expr]
)

## 修改列
## modify一次只能修改一列
alter table 表名 modify 列名 [新列名] 数据类型 [default expr] [first|after 列名]

## 删除列
alter table 表名 drop 列名

# 删除表, 表数据、约束、索引也被删除
drop table 表名

# 清空数据，保留表结构
truncate 表名
```

# 索引
索引是存放在`模式`中的一个数据库对象，在数据字典中独立存放，属于某个表，作用是加速对表的查询。

**创建的两种方式**
1. 自动：当在表上定义主键约束、唯一约束、外键约束时，会自动创建
1. 手动：通过`create index index_name on table_name(column[,column]...)`语句创建

**删除的两种方式**
1. 自动：数据表被删除时，该表的索引被删除
1. 手动：通过`drop index index_name on table_name`语句删除


# 插入更新删除
```sql
# 插入
insert into table_name [ ( column [, column...] ) ]
values ( value [, value...]);

# 使用子查询插入数据，要求插入数据列和数据类型匹配
insert into table_name [ ( column [, column...] ) ]
subquery

# 更新
update table_name
set column1 = value1 [ , column2 = value2 ]...
[where condition];

# 删除
delete from table_name [where condition];
```

# 查询
**单表查询**
```sql
# 查找不重复姓名的学生信息
select distinct sname from stu;

# not取反
select * from sname where not sid=2; # 查找sid不等于2的学生信息

# between...and之间
select * from stu where sid between 2 and 4; # 查找学号在[2,4]区间中的学生信息

# in集合
select * from stu where sid in (2, 3, 4); # 查找学号在(2, 3, 4)集合中的学生信息

# like模糊查询
select * from stu where sname like '张_';  # 查找姓名为两个字开头为张的学生信息 
select * from stu where sname like '张%';  # 查找姓名为张开头的学生信息 
select * from stu where sname like '张\%'; # 查找姓名为张%的学生信息，转义字符，标准SQL中没有转义字符 
select * from stu where sname like '张\%' escape '\';   #'# 标准SQL使用escape声明转义字符

# limit限制查询数量
select * froom stu limit 0, 5; # 查询stu表中从第0行开始的5条记录 

# 外连接查询
select s.*,t.* from stu s left  outer join teacher t on s.tid=t.tid; # 左外连接，左表为基础，右表数据可为null 
select s.*,t.* from stu s right outer join teacher t on s.tid=t.tid; # 右外连接，右表为基础，左表数据可为null 
select s.*,t.* from stu s full  outer join teacher t on s.tid=t.tid; # 全外连接，MySQL不支持 
```
# 约束
不得使用外键与级联, 一切外键概念必须在应用层解决。
外键与级联更新适用于单机低并发, 不适合分布式、高并发集群;
级联更新是强阻塞, 存在数据库更新风暴的风险; 
外键影响数据库的插入速度。
```sql
# not null约束
# 非空约束，确保指定列不为空，只能作为列级约束。
create table stu ( sid int not null );   /* 建表时指定非空约束   */
alter table stu modify sid int not null; /* 修改表时指定非空约束 */
alter table stu modify sid int null;     /* 修改表时取消非空约束 */

# unique约束
# 唯一约束，确保指定列或多列组合不允许出现重复值，可作为表级约束和列级约束。
# 多列唯一约束只能用表级约束语法。
# 创建唯一约束时，`MySQL`会对应创建唯一索引，默认与列名相同。
create table stu ( sid int unique ); /* 建表时指定列级唯一约束 */
create table stu (
    sid int,
    /* 使用表级约束语法建立唯一约束 */
    unique (sid),
    /* 使用表级约束语法建立唯一约束并指定约束名 */
    /* constraint uk_1 unique (sid), */
)

alter table stu add unique(sid);       /* 修改表结构增加唯一约束 */
alter table stu modify sid int unique; /* 修改表结构增加唯一约束 */

alter table stu drop index 约束名;     /* 修改表结构删除唯一约束 */


# primary key约束
# 主键约束=非空约束+唯一约束，唯一标识一条记录，可作为表级约束和列级约束。
# 多列主键约束只能用表级约束语法。
# 可以为主键约束指定约束名，但没有用，最后`MySQL`都改为`PRIMARY`。
# 还可以设置为自增长`auto_increment`
create table stu ( sid int primary key auto_increment ); /* 建表时指定列级主键约束 */
create table stu (
    sid int,
    /* 使用表级约束语法建立主键约束 */
    primary key ( sid ),
    /* 使用表级约束语法建立主键约束并指定约束名，对MySQL无效，最后都为PRIMARY */
    /* constraint pk_1 primary key ( sid ) */
)
alter table stu add primary key(sid);       /* 修改表结构增加主键约束 */
alter table stu modify sid int primary key; /* 修改表结构增加主键约束 */

alter table stu drop primary key; /* 修改表结构删除主键约束 */


# foreign key约束
# 外键确保了两个表之间的参照完整性。MySQL只支持表级约束
# on delete cascade ：级联删除，删除所有表的相关的记录
# on delete set null：置空删除，将所有表的相关记录的对应字段置null
create table stu (
    sid int unsigned primary key auto_increment,
    /* 列级约束，MySQL支持，但不生效 */
    /* tid int reference teacher(tid) # stu.tid参照teacher.tid */
    tid int,
    /* 使用表级约束建立外键约束，默认为 表名_ibfk_n，n是从1开始的整数 */
    foreign key (tid) references teacher(tid) on delete set null
    /* 使用表级约束建立外键约束并指定约束名stu_tea_fk */
    /* constraint stu_tea_fk foreign key (tid) references teacher(tid) */
)
/* 修改表结构增加外键约束 */
alter table stu add foreign key (tid) references teacher(tid); 

/* 删除外键约束 */
alter table drop foreign key 约束名; 

# check约束
`MySQL`无效
create table stu(
    sid int,
    age int,
    check(age>0)
)
```

# 函数
**字符函数**

| 名称                                      | 描述                                                                              |
|:------------------------------------------|:----------------------------------------------------------------------------------|
| concat(var... args)                       | 将所有字符串连接成一个字符串                                                      |
| concat_ws(var delimiter, var... args)     | 将所有字符串连接成一个字符串，子串之间用delimiter分割                             |
| format(var num, var decimal)              | 将数字格式化，四舍五入保留decimal位小数                                           |
| lower(var str)                            | 将所有字符转化为小写                                                              |
| upper(var str)                            | 将所有字符转化为大写                                                              |
| left(var str, var left)                   | 取字符串前left个字符                                                              |
| right(var str, var right)                 | 取字符串后right个字符                                                             |
| length(var str)                           | 计算字符串的长度                                                                  |
| ltrim(var str)                            | 删除字符串前导空格                                                                |
| rtrim(var str)                            | 删除字符串后续空格                                                                |
| trim(var str)                             | 删除字符串前导和后续空格，不能删除中间空格                                        | 
| substring(var str, var start, var length) | 截取字符串从start个字符开始长度为length的字符<br/>start负值为倒数，length默认全部 |
| replace(var str, var old, var new)        | 将字符串中的old字符串替换为new字符串                                              |

**数值运算函数**

| 名称                           | 描述                                                |
|:-------------------------------|:----------------------------------------------------|
| ceil(var num)                  | 向上取整，2.6得3，2.1得3                            |
| div                            | 整数除法，4/3==1，select 4 div 3;                   |
| floor()                        | 向下取整，2.6得2，2.1得2                            |
| mod                            | 取余数，5%3==2，select 5 mod 3;                     |
| power(var base, var exponent)  | 幂运算，2^3==8                                      |
| round(var num, var decimal)    | 四舍五入保留decimal位小数，默认保留整数             |
| truncate(var num, var decimal) | 不四舍五入，直接截断保留decimal位小数，负数往前截断 |

**日期时间函数**

|名称                                      | 描述                                                                               |
|:-----------------------------------------|:-----------------------------------------------------------------------------------|
| now()                                    | 当前的日期和时间，2016-12-20 17:08:31                                              |
| curdate()                                | 当前日期，2016-12-20                                                               |
| curtime()                                | 当前时间，17:08:31                                                                 |
| date_add(var now, interval var datetime) | 日期增减(正负)datetime单位时间，select date_add('2016-12-20',interval 3 day)       |
| datediff(var now, var diff)              | 计算now-diff的时间差，以天为单位                                                   |
| date_format(var now, var format)         | 日期格式转换为format格式<br/>select date_format(now(),'%Y年%m月%d日%H时%i分%s秒'); |

**数据库信息函数**

| 名称             | 描述               |
|:-----------------|:-------------------|
| connection_id()  | 连接ID             |
| database()       | 当前数据库名称     |
| last_insert_id() | 最后插入的记录的ID |
| user()           | 当前用户和地址     |
| version()        | 版本号             |

**加密函数**

| 名称              | 描述             |
|:------------------|:-----------------|
| md5(var msg)      | 信息摘要算法加密 |
| password(var msg) | 密码算法加密     |

**自定义函数**
```sql
# 删除函数
drop function 函数名;

# 创建无参函数
create function now_cn() returns varchar(30)
return date_format(now(), '%Y年%m月%d日 %H时%i分%s秒');

# 创建有参函数
create function avg(num1 int, num2 int) returns float(10,2)
return (num1+num2)/2;

# 创建复合结构函数体的函数
# 首先以`//`为结尾，替换;
# 再在`begin`和`end`之间编写函数体
delimiter //
create function adduser(user_name varchar(30)) returns int
begin
insert into user(username) values(user_name);
return last_insert_id();
end//
```

# 集合运算
```sql
# union并运算
# 查找名字为张三的学生和年龄大于10的学生的并集
select * from stu where sname='张三' union select * from stu where age>10;

# minus减运算
# 查找年龄大于15但不大于20的学生的集合
select * from stu where age>15 minus select * from stu where age>20 
select * from stu where age>15 and age not in (select age from stu where age>20);

# intersect交运算
# MySQL不支持，可用多表连接查询实现
```

# 视图
视图可以看成是一个依赖一个或多个表的只读表
```sql
# 创建
create or replace view view_name
as
subquery
with check option /* 指定不允许修改该视图的数据 */

# 删除
drop view view_name
```

# 事务
- 原子性（`Atomicity`）：是应用的最小执行单位，不可再分。
- 一致性（`Consistency`）：事务执行结果使数据库从一个一致性状态变为另一个一致性状态，通过原子性实现。
- 隔离性（`Isolation`）：各个事务相互独立互不干扰。
- 持续性（`Durability`）：事务一旦提交，所有更改都记录到永久存储器中。
```sql
begin;                 # 临时开启事务 
# start transaction;   # 临时开启事务 

insert into stu(sname) values("stu1");
insert into stu(sname) values("stu2");
# savepoint a;         # 设置事务中间点 
insert into stu(sname) values("stu3");

select * from stu;   # 三条插入数据显示
rollback;            # 回滚事务 
# rollback to a;     # 回滚到之前声明的事务中间点a 
# commit;            # 或者显式提交事务 

select * from stu;   # 三条插入数据没有插入，回滚事务 
```

# 存储过程(开发不建议使用)
存储过程是SQL语句和控制语句的预编译集合，减少了语法分析和编译的过程，提高执行效率。
存储过程难以调试和扩展，更没有移植性。

参数类型：
- `IN`：表示该参数的值必须在调用存储过程时指定
- `OUT`：表示该参数的值可以被存储过程改变，并且可以返回
- `INOUT`：表示该参数的调用时指定，并且可以被改变和返回

```sql
# 删除存储过程
drop procedure 存储过程名;
drop procedure if exists 存储过程名;

# 创建无参存储过程
create procedure pd_get_version()
select version();

# 创建有参存储过程
delimiter //
create procedure pd_adduser(IN user_name varchar(20), OUT all_nums int)
begin
insert into user(username) values(user_name);
select count(*) from user into all_nums;
end//

delimiter ;
# 使用存储过程
call 存储过程名(变量...);
call pd_adduser('Tom', @nums);
select @nums;
```
