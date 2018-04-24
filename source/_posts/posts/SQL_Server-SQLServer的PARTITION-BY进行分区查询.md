---
title: SQLServer的PARTITION_BY进行分区查询
url: use_PARTITION_BY_to_query
tags:
  - SQL Server
categories:
  - SQL Server
date: 2018-04-18 11:19:10
---
# 前言
假设有一个用户表`admin(id, name, sex)`, 现在有个需求。
是按照性别`sex`进行分区, 然后排序。

<!-- more -->

比如有以下数据
```
id          name       sex(1男2女)
1          admin1          1
2          admin2          1
3          admin3          2
4          admin4          2
5          admin5          2
```

要求查询性别`sex`进行分区, 然后排序。
```
id          name       sex(1男2女)   row_num
1          admin1          1            1
2          admin2          1            2
3          admin3          2            1
4          admin4          2            2
5          admin5          2            3
```

# 使用ROW_NUMBER进行排序
首先获取行数, `SQLServer`提供了`ROW_NUMBER`函数。
```sql
select tmp.*, ROW_NUMBER() over(order by tmp.id asc) as row_num
from ( select id, name, sex from admin ) tmp
order by row_num asc
```
```
id          name       sex(1男2女)   row_num
1          admin1          1            1
2          admin2          1            2
3          admin3          2            3
4          admin4          2            4
5          admin5          2            5
```
但是需求是, 根据`sex`分区排序, 所以添加一个`partition by`关键字。

# 使用PARTITION  BY进行分区
```sql
select tmp.*, ROW_NUMBER() over(partition by sex order by tmp.id asc) as row_num
from ( select id, name, sex from admin ) tmp
order by sex asc, row_num asc
```
```
id          name       sex(1男2女)   row_num
1          admin1          1            1
2          admin2          1            2
3          admin3          2            1
4          admin4          2            2
5          admin5          2            3
```
完成, 此外还可以用来做分区求和等功能。

# 参考资料
- [sum over partition by 的用法](https://blog.csdn.net/wawmg/article/details/40840093)