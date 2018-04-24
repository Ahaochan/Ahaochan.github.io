---
title: Hibernate简单使用
url: Hibernate_simple_use
tags:
  - Hibernate
categories:
  - Java Web
date: 2017-02-08 14:25:00
---
# 前言
使用IDEA+Maven进行搭建Hibernate5
<!-- more -->

# 步骤
## 导入
在pom.mxl中加入maven项目
```xml
<dependencies>
    <dependency>
        <groupId>org.hibernate</groupId>
        <artifactId>hibernate-search-orm</artifactId>
        <version>5.5.5.Final</version>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>6.0.5</version>
    </dependency>
<dependencies>
```

## 创建配置文件
在`/src/main/resources/hibernate.cfg.xml`中配置
```xml
<?xml version='1.0' encoding='utf-8'?>
<!DOCTYPE hibernate-configuration PUBLIC
        "-//Hibernate/Hibernate Configuration DTD//EN"
        "http://www.hibernate.org/dtd/hibernate-configuration-3.0.dtd">
<hibernate-configuration>
    <session-factory>
        <!--访问数据库的url地址，带参数防止编译错误-->
        <property name="connection.url">jdbc:mysql://localhost:3306/test?serverTimezone=GMT&useUnicode=true&characterEncoding=utf8</property>
        <property name="connection.driver_class">com.mysql.jdbc.Driver</property><!--数据库的JDBC驱动-->
        <property name="connection.username">root</property><!--连接数据库的用户名-->
        <property name="connection.password">root</property><!--连接数据库的用户密码-->
        <property name="dialect">org.hibernate.dialect.MySQLDialect</property><!--指定使用mysql数据库的方言-->
        
        <property name="show_sql">true</property><!--在控制台输出sql语句-->
        <property name="format_sql">true</property><!--在控制台格式化sql语句-->
        <property name="hbm2ddl.auto">create</property><!--生成表结构的策略-->
        <mapping resource="students.hbm.xml"/>
        <mapping class="com.ahao.javaeeDemo.Students"/>
    </session-factory>
</hibernate-configuration>
```

## 创建实体
```java
//Students.java
public class Student{
    private int sid;
    private String sname;
    //构造器、getter和setter
}
```

```xml
<!--students.hbm.xml-->
<?xml version='1.0' encoding='utf-8'?>
<!DOCTYPE hibernate-mapping PUBLIC
        "-//Hibernate/Hibernate Mapping DTD 3.0//EN"
        "http://www.hibernate.org/dtd/hibernate-mapping-3.0.dtd">
<hibernate-mapping>
    <class name="com.ahao.javaeeDemo.Students" table="students">
        <id name="sid" type="int">
            <column name="sid"/>
            <generator class="increment"/>
        </id>
        <property name="sname" type="java.lang.String">
            <column name="sname"/>
        </property>
    </class>
</hibernate-mapping>  
```

## 编写测试代码
```java
public class MainTest {
    private static ServiceRegistry serviceRegistry;
    private static SessionFactory sessionFactory;
    private static Session session;
    private static Transaction transaction;
    @BeforeClass
    public static void initClass(){
        //创建服务注册对象
        serviceRegistry = new StandardServiceRegistryBuilder()
                .configure("hibernate.cfg.xml").build();
        //创建会话工厂对象
        sessionFactory = new MetadataSources(serviceRegistry).buildMetadata().buildSessionFactory();
        //创建会话对象
        session = sessionFactory.openSession();
        //开启事务
        transaction = session.beginTransaction();
    }

    @Test
    public void testSave(){
        Students s = new Students();
        s.setSname("zhangsan");
        s.setBirthday(new java.sql.Date(System.currentTimeMillis()));
        session.save(s);
    }

    @AfterClass
    public static void destoryClass(){
        //提交事务
        transaction.commit();
        //关闭会话
        session.close();
        //关闭会话工厂
        sessionFactory.close();
    }
}
```

# 操作
## 增
使用`save()`
```java
public class MainTest {
    //省略初始化代码
    @Test
    public void testSave(){
        Students s = new Students();
        s.setSname("zhangsan");
        s.setBirthday(new java.sql.Date(System.currentTimeMillis()));
        session.save(s);
    }
    //省略销毁代码
}
```

## 改
使用`update()`
```java
public class MainTest {
    //省略初始化代码
    @Test
    public void testUpdate(){
        int sid = 1;
        Students s = session.get(Students.class, sid);
        s.setSname("Cat");
        session.update(s);
//        session.saveOrUpdate(s);
    }
    //省略销毁代码
}
```

## 删
使用`delete()`
```java
public class MainTest {
    //省略初始化代码
    @Test
    public void testDelete(){
        int sid = 1;
        Students s = session.get(Students.class, sid);
        session.delete(s);
    }
    //省略销毁代码
}
```

## 查
### 查询单个记录
使用`get()`或`load()`
```java
public class MainTest {
    //省略初始化代码
    @Test
    public void testRead(){
        int sid = 1;
        Students s1 = session.get(Students.class, sid);//发送sql语句，获取Students对象
        System.out.println(s1.toString());//打印输出
        Students s2 = session.load(Students.class, sid);//不发送sql语句，获取一个代理对象
        System.out.println(s2.toString());//使用的时候才发送sql语句，获取Students对象
    }    //省略销毁代码
}
```
