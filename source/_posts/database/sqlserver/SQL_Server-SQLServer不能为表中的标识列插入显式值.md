---
title: SQLServer不能为表中的标识列插入显式值
url: Cannot_insert_explicit_value_for_identity_column
tags:
  - SQL Server
categories:
  - SQL Server
date: 2018-05-31 18:18:00
---

# 前言
今天遇到个问题，要把线上生产环境的某张数据表的数据导出到本地的测试环境，但是导出后的`SQL`文件执行时出现了错误。
```text
[SQL] INSERT INTO [test_user] ([id], [name]) VALUES (100, '测试用户')
[Err] 23000 - [SQL Server]当 IDENTITY_INSERT 设置为 OFF 时，不能为表 'test_user' 中的标识列插入显式值。
```

<!-- more -->

# 解决方案
设置`identity_insert`为`ON`，执行完毕再设置为`OFF`即可。
设置语法为`SET IDENTITY_INSERT [ database.[ owner.] ] { table } { ON | OFF } `
```sql
set identity_insert ClassInfo ON;
INSERT INTO [m_opendata] ([id], [name]) VALUES (100, '测试标题');
set identity_insert ClassInfo OFF;
```

# 参考资料
- [当 IDENTITY_INSERT 设置为 OFF 时，不能为表中的标识列插入显式值](https://www.cnblogs.com/xgcblog/archive/2011/08/10/2133974.html)
