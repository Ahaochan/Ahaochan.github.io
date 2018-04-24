---
title: SQL Server分页
url: paging_query_of_SQL_Server
tags:
  - SQL Server
categories:
  - SQL Server
date: 2018-02-03 17:59:34
---
# 环境
基于`Mybatis`的[动态SQL](http://www.mybatis.org/mybatis-3/zh/dynamic-sql.html)。
使用[fastjson](https://github.com/alibaba/fastjson)格式化输出数据。

<!-- more -->

```java
@Repository
public interface StudentDao {
    List<Map<String, Object>> getStudent(@Param("sex") String sex,
                              @Param("page") int page, @Param("pageSize") int pageSize);
}

public class MyTest {
    private StudentDao dao;
    public void test() {
        // 查找性别为男, 分页大小为10, 的第2页数据
        List<Map<String, Object>> data = dao.getStudent("男", 2, 10);
        System.out.println(JSONObject.toJSONString(data));
    }
}
```
# SQL Server 2005
在2005之后, 使用`ROW_NUMBER()`函数标记记录的**行号**, 然后再使用`where`进行筛选。
```sql
<select id="getStudent" resultType="Map">
    <bind name="skip" value="(page-1)*pageSize"/>
    <bind name="record" value="page*pageSize"/>
    SELECT  *
    FROM (
        SELECT TOP 100 PERCENT tmp.*, 
            ROW_NUMBER() OVER (ORDER BY tmp.birthday desc) AS row_num
        FROM (
            SELECT DISTINCT s.id, s.name, CONVERT (VARCHAR(10), s.birthday, 120) AS birthday
            FROM student s
            WHERE s.sex = ${sex}
            ORDER BY s.birthday
        ) tmp
        ORDER BY row_num
    ) tmp
    <![CDATA[WHERE row_num > ${skip} and row_num <= ${record}]]>
</select>
```

# SQL Server 2012
在2012之后, 使用[OFFSET FETCH 子句](https://technet.microsoft.com/zh-cn/library/gg699618.aspx)进行分页处理。
```sql
    <select id="getStudent" resultType="Map">
        <bind name="skip" value="(page-1)*pageSize"/>
        SELECT DISTINCT s.id, s.name, CONVERT (VARCHAR(10), s.birthday, 120) AS birthday
        FROM student s
        WHERE s.sex = ${sex}
        ORDER BY s.birthday
        OFFSET ${skip} ROWS FETCH NEXT ${pageSize} ROWS ONLY;
    </select>
```