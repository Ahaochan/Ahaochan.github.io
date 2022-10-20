---
title: Mybatis回写主键的值
url: how_to_get_primary_key_in_Mybatis
tags: 
  - Mybatis
categories:
  - Java Web
date: 2018-03-27 11:05:00
---
# 前言
每种数据库都有自己的主键生成方式，比如`MySQL`支持自增的主键, 在插入数据后自动生成主键, 比如`Oracle`通过序列的方式, 在插入数据之前生成主键, 再写去表中。

<!-- more -->

# 环境准备
```java
public interface UserMapper {
    int insert(User User);
}
public class User {
    Long id;
    String name;
    // 省略构造函数和getter setter方法
}
public class MyTest {
    @Test
    public void testInsert() throws IOException {
        // 1. 初始化 SqlSession
        Reader reader = Resources.getResourceAsReader("mybatis-config.xml");
        SqlSessionFactory factory = new SqlSessionFactoryBuilder().build(reader);
        try(SqlSession sqlSession = factory.openSession()){
            // 2.  获取Mapper
            UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
            User user = new User();
            user.setName("测试用户");
            System.out.println(user);
            int result = userMapper.insert(user);
            Assert.assertEquals(1, result);
            // 3. 判断主键回写成功
            Assert.assertNotNull(user.getId());
            System.out.println(user);
        }
    }
}
```
# 使用JDBC的useGeneratedKeys获取主键值
只支持**插入数据后**生成主键的数据库。如`MySQL`和`SQLServer`。
底层是使用了`JDBC`的`statement.getGeneratedKeys()`。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.ahao.demo.mapper.UserMapper">
    <insert id="insert" useGeneratedKeys="true" keyProperty="id">
        insert sys_user(id, name) values (#{id}, #{name})
    </insert>
</mapper>
```

# 使用selectKey获取主键值
`useGeneratedKeys`局限于主键自增的数据库, 不支持`Oracle`这种先**生成主键**, 再把主键插入数据库中的形式。
`selectKey`两者都支持, 缺点就是比较笨重, 需要写多一点`xml`代码。

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.ahao.demo.mapper.UserMapper">
    <insert id="insert">
        <selectKey keyProperty="id" keyColumn="id" resultType="Long" order="AFTER">
        select LAST_INSERT_ID()
        </selectKey>
        insert sys_user(id, name) values (#{id}, #{name})
    </insert>
</mapper>
```
`keyProperty`指的是实体的`field`名称, `keyColumn`指的是数据表的`column`名称, `resultType`指定返回的`Java`类型。
`order`分为`AFTER`和`BEFORE`, 因为`MySQL`中, 主键是在插入数据之后生成的, 所以选择`AFTER`。`Oracle`则要选`Before`。
需要注意的是, `selectKey`的位置不会影响结果, 最好是根据实际情况来选择放置位置, 比如`MySQL`就放在`SQL`之前, 表示先生成主键后插入数据。

## 各数据库回写主键的SQL
- [MySQL](https://www.mysql.com/cn/)： `SELECT LAST_INSERT_ID()`
- [Sql Server](https://www.microsoft.com/en-us/sql-server/sql-server-2017)：`SELECT SCOPE_IDENTITY()`
- [Oracle](https://www.oracle.com/index.html)：`SELECT SEQ_ID.nextval from dual`
- [Db2](https://www.ibm.com/analytics/us/en/db2/)： `VALUES IDENTITY_VAL_LOCAL()`
- [HSQLDB](http://hsqldb.org/)：`CALL IDENTITY()`

# 不使用实体类获取主键

