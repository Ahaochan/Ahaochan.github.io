---
title: Mybatis文件位置引发的mappedStatements为空
url: Mybatis_mapper_xml_location_causes_mappedStatements_is_empty
tags: 
  - Mybatis
categories:
  - Java Web
date: 2018-03-19 22:11:21
---
# 前言
在不使用`Spring`进行初始化`Bean`, 单纯的使用`Mybatis`的时候, 遇到`xml`读取不到的问题。

<!-- more -->

# 准备环境
{% qnimg Mybatis文件位置引发的mappedStatements为空_01.png %}
```xml
<!--pom.xml -->
<dependencies>
    <!--==============================日志============================-->
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
        <version>1.7.25</version>
    </dependency>
    <dependency>
        <groupId>ch.qos.logback</groupId>
        <artifactId>logback-classic</artifactId>
        <version>1.2.3</version>
    </dependency>
    <!--==============================日志============================-->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>3.4.6</version>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>5.1.45</version>
    </dependency>
</dependencies>
```

```sql
-- MySQL数据库
create database test;
use test;
create table user(
    id int primary key auto_increment,
    name varchar(50)
);
insert into user(name) values ('A'), ('B'), ('C');
```

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- mybatis-config.xml -->
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>

    <settings>
        <setting name="logImpl" value="SLF4J"/>
    </settings>
    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC">
            <!-- 配置数据库 -->
            </transactionManager>
            <dataSource type="UNPOOLED">
                <property name="driver" value="com.mysql.jdbc.Driver"/>
                <property name="url" value="jdbc:mysql://localhost:3306/test"/>
                <property name="username" value="root"/>
                <property name="password" value="root"/>
            </dataSource>
        </environment>
    </environments>

    <mappers>
        <!-- 注册mapper的三种方式 -->
        <package name="com.ahao.demo.mapper"/>
        <!--<mapper resource="UserMapper.xml"/>-->
        <!--<mapper class="com.ahao.demo.mapper.UserMapper"/>-->
    </mappers>
</configuration>
```
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!-- UserMapper.xml -->
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"  "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<!-- namespace命名空间,作用就是对sql进行分类化管理,理解sql隔离 注意:使用mapper代理方法开发,namespace有特殊重要的作用,namespace等于mapper接口地址 -->
<mapper namespace="com.ahao.demo.mapper.UserMapper">
    <select id="selectAll" resultType="Map">
        select * from user
    </select>
</mapper>
```
```java
package com.ahao.demo.mapper;
import java.util.*;
public interface UserMapper {
    List<Map<String, String>> selectAll();
}
```
```java
package com.ahao.test;

import com.ahao.demo.mapper.UserMapper;
import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.junit.BeforeClass;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.io.Reader;
import java.util.List;

public class MyTest {
    private static final Logger logger = LoggerFactory.getLogger(MyTest.class);

    private static SqlSessionFactory sqlSessionFactory;

    // 1. 从 mybatis-config.xml 初始化 sqlSessionFactory
    @BeforeClass
    public static void init() throws IOException {
        Reader reader = Resources.getResourceAsReader("mybatis-config.xml");
        sqlSessionFactory = new SqlSessionFactoryBuilder().build(reader);
        reader.close();
    }

    @Test
    public void testSelectAll(){
        // 2. 读取并显示
        try(SqlSession sqlSession = sqlSessionFactory.openSession()) {
            UserMapper userMapper = sqlSession.getMapper(UserMapper.class);
            System.out.println(userMapper);
            List user = userMapper.selectAll();
            System.out.println(user);
        }
    }
}
```

# 分析
运行过后抛出一个异常, `statement `没有找到。
```
org.apache.ibatis.binding.BindingException: Invalid bound statement (not found): com.ahao.demo.mapper.UserMapper.selectAll
```

通过`debug`看到`sqlSessionFactory`对象中的`Configuration`内有两个属性，`mapperRegistry`和`mappedStatements`看起来是存储`mapper`类和对应的`Statements`的两个属性。
{% qnimg Mybatis文件位置引发的mappedStatements为空_02.png %}
{% qnimg Mybatis文件位置引发的mappedStatements为空_03.png %}
`mapperRegistry`注册成功了, 但是`mappedStatements`为空, 也就是`Class`加载成功了, `xml`加载失败。

`xml`自动扫描配置是包扫描, 那么切换成别的可行吗?
```xml
<mappers>
    <!-- Invalid bound statement (not found) -->
    <package name="com.ahao.demo.mapper"/>
    <!-- 加载成功 -->
    <mapper resource="UserMapper.xml"/>
    <!-- Invalid bound statement (not found) -->
    <mapper class="com.ahao.demo.mapper.UserMapper"/>
</mappers>
```
可以看到只有直接指定`xml`才能加载成功。
**那就是通过`Class`自动去寻找对应`xml`的时候发生了异常。**
翻阅了[官方文档](http://www.mybatis.org/mybatis-3/zh/configuration.html#mappers), 并没有相关资料。

# 解决方案
然后检查`target`文件夹的时候, 发现`UserMapper.xml`和`UserMapper.class`没有在同一个文件夹内, 于是将`target`下的`UserMapper.xml`拖到`UserMapper.class`同级目录
。调试发现`mappedStatements`有数据。成功了, 推测应该是通过包名转文件路径进行扫描的。
{% qnimg Mybatis文件位置引发的mappedStatements为空_04.png %}

经过测试, 有两种解决方案
1. 手动移动`target`文件夹内的`mapper.xml`到对应的`mapper.class`**相同文件夹**`/WEB-INF/class/com/ahao/demo/mapper`下。
2. 将`mapper.xml`放在`resource`文件夹内, 对应的文件**目录结构**`/resource/com/ahao/demo/mapper`下。

# 总结
`Mybatis`太坑, 没有个`file not found`提示。在`IDEA`下, 就算一开始将`mapper.xml`文件放在`src/java`文件夹下, 编译后也不会将`xml`放到`target`的相同目录下。
不过有`Spring`就不用担心了, `Spring`可以指定扫描`xml`文件位置。实际开发一般都是和`Spring`整合的吧。
