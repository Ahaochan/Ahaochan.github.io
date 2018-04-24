---
title: JDBC简单使用
url: JDBC_simple_use
tags:
  - JDBC
categories:
  - Java SE
date: 2017-02-15 20:09:03
---
# 连接数据库
先[下载jar包](https://dev.mysql.com/downloads/connector/j/) ，或者[导入maven](https://mvnrepository.com/artifact/mysql/mysql-connector-java)
<!-- more -->

```java
public class JDBCTest {
//    private static final String driver = "com.mysql.jdbc.Driver";//已过时
    private static final String driver = "com.mysql.cj.jdbc.Driver";
    private static final String username = "root";
    private static final String password = "root";
    private static final String schema = "test";
    private static final int port = 3306;
    private static final String url = "jdbc:mysql://localhost:"
            + port + "/" + schema+"?serverTimezone=GMT&useUnicode=true&characterEncoding=utf8";
    //最好使用properties文件存储配置信息，或者使用数据库连接池

    private static Connection conn;//建立连接

    @BeforeClass
    public static void initJDBC() throws Exception {
        Class.forName(driver);//加载驱动
        conn = DriverManager.getConnection(url, username, password);//建立数据库连接
    }

    @Test
    public void testRead() {
        try (Statement s = conn.createStatement();
            ResultSet rs = s.executeQuery("SELECT * FROM stu;")//查询数据表返回结果集
        ) {
            ResultSetMetaData rsmd = rs.getMetaData();//获取结果集的元数据
            while (rs.next()) {//如果有下一条记录
                for (int i = 1; i <= rsmd.getColumnCount(); i++) {
                    System.out.print(rs.getString(i)+"\t");//将每列打印输出
                }
                System.out.print("\n");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @AfterClass
    public static void destoryJDBC() throws Exception {
        conn.close();//释放连接
    }
}
```

# 执行SQL语句的Statement
## Statement的基本用法
```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testExecuteUpdate(){
        try(Statement s = conn.createStatement();
        ){
            s.executeUpdate("CREATE TABLE stu(" +
                    "sid INT UNSIGNED PRIMARY KEY AUTO_INCREMENT," +
                    "sname VARCHAR(20)," + "age INT ," + "tid INT )");
            System.out.println("共有"+0+"条记录受影响");//执行DDL语句时返回0
            int records = s.executeUpdate("UPDATE stu SET age=age+1");
            System.out.println("共有"+records+"条记录受影响");//执行DML语句时返回受影响记录数目
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testExecute(){
        try(Statement s = conn.createStatement();
        ){
            boolean hasResultSet = s.execute("SELECT * FROM stu;");//判断有没有结果集
            if(hasResultSet){
                try(ResultSet rs = s.getResultSet()){//获取结果集
                    ResultSetMetaData rsmd = rs.getMetaData();//获取结果集元数据
                    while (rs.next()) {
                        for (int i = 1; i <= rsmd.getColumnCount(); i++) {
                            System.out.print(rs.getString(i)+"\t");
                        }
                        System.out.print("\n");
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }    //省略释放资源代码
}
```

## 预编译的PreparedStatement
`PreparedStatement`是`Statement`的子接口，可以预编译`SQL`语句，效率高，还可以防注入。
```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testPreparedStatement(){
        try(PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO stu(sname, age) VALUES(?,?) ");//预编译SQL语句
        ){
            for(int i = 0; i < 3; i++){
                ps.setString(1,"stu"+i);//填充占位符
                ps.setInt(2, 20+i);//填充占位符
                ps.executeUpdate();//提交
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    //省略释放资源代码
}
```

## 调用存储过程的CallableStatement
{% post_link posts/MySQL-MySQL常用语句 %}

自定义一个加法的存储过程
```sql
delimiter //
create procedure add_num(in a int, in b int, out sum int)
begin
set sum = a + b;
end//
```

```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testCallableStatement() throws Exception{
        try(CallableStatement cs = conn.prepareCall("{CALL add_num(?,?,?)}");){
            int a = 5, b = 3;
            cs.setInt(1, a);
            cs.setInt(2, b);
            cs.registerOutParameter(3, Types.INTEGER);
            cs.execute();
            System.out.println(a+"+"+b+"="+cs.getInt(3));
        }
    }
    //省略释放资源代码
}
```


# 事务
{% post_link 数据库/MySQL/MySQL事务 MySQL事务 %}
```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testTransaction() throws SQLException {
        conn.setAutoCommit(false); // 关闭事务自动提交
        Statement s = conn.createStatement();
        s.executeUpdate("INSERT INTO stu(sname) VALUES ('stu1');");
        s.executeUpdate("INSERT INTO stu(sname) VALUES ('stu2');");
        Savepoint sp = conn.setSavepoint("事务中间点"); // 设置事务中间点
        s.executeUpdate("INSERT INTO stu(sname) VALUES ('stu3');");
        conn.rollback(sp); // 回滚事务
        conn.commit();     // 提交事务
    }
    //省略释放资源代码
}
```

# 数据库连接池
## DBCP数据源
`Tomcat`的连接池使用`DBCP`连接池。
在[maven中导入](https://mvnrepository.com/artifact/commons-dbcp/commons-dbcp/1.4)
```xml
<dependency>
    <groupId>commons-dbcp</groupId>
    <artifactId>commons-dbcp</artifactId>
    <version>1.4</version>
</dependency>
```
从数据库连接池中获取数据库连接
```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testDBCP() throws SQLException {
        //BasicDataSource bds = BasicDataSourceFactory.createDataSource(properties);//另一种创建方式
        BasicDataSource bds = new BasicDataSource();
        bds.setDriverClassName(driver); // 加载驱动
        bds.setUrl(url);                // 设置url
        bds.setUsername(username);      // 设置用户名
        bds.setPassword(password);      // 设置密码
        bds.setInitialSize(5);          //设置连接池的初始连接数
        bds.setMaxActive(20);           //设置连接池最多可有20个活动连接数
        bds.setMinIdle(2);              //设置连接池中最少有2个空闲的连接
        Connection conn = bds.getConnection();
        //执行sql语句
        conn.close();//释放连接，归还连接池
    }
    //省略释放资源代码
}
```

## C3P0数据源
`Hibernate`的连接池使用`C3P0`连接池。
在[maven中导入](https://mvnrepository.com/artifact/c3p0/c3p0/0.9.1.2)
```xml
<dependency>
    <groupId>c3p0</groupId>
    <artifactId>c3p0</artifactId>
    <version>0.9.1.2</version>
</dependency>
```
从数据库连接池中获取数据库连接
```java
public class JDBCTest {
    //省略初始化代码
    @Test
    public void testC3P0() throws PropertyVetoException, SQLException {
        ComboPooledDataSource cpds = new ComboPooledDataSource();
        cpds.setDriverClass(driver); // 加载驱动
        cpds.setJdbcUrl(url);        // 设置url
        cpds.setUser(username);      // 设置用户名
        cpds.setPassword(password);  // 设置密码
        cpds.setMaxPoolSize(40);     //设置连接池的最大连接数
        cpds.setMinPoolSize(2);      //设置连接池的最小连接数
        cpds.setInitialPoolSize(10); //设置连接池的初始连接数
        cpds.setMaxStatements(190);  //设置连接池的缓存Statement的最大数
        Connection conn = cpds.getConnection();
        //执行SQL语句
        conn.close();
    }    //省略释放资源代码
}
```
