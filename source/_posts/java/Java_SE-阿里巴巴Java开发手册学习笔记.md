---
title: 阿里巴巴Java开发手册学习笔记
url: Alibaba_Java_Development_Handbook
tags:
  - 最佳实践
categories:
  - Java SE
date: 2017-05-30 17:21:18
---

# 下载地址
[【Java编码规范】《阿里巴巴Java开发手册（正式版）》更新（v1.2.0版）——迄今最完善版本](https://yq.aliyun.com/articles/69327)
<!-- more -->

# 编程规约
## 命名风格
1. 【强制】类名使用UpperCamelCase风格，类名使用 UpperCamelCase 风格，必须遵从驼峰形式。但以下情形例外。
但以下情形例外： `DO` /  `BO`  / `DTO` /  `VO` /  `AO`
正例： MarcoPolo /  UserDO /  XmlService /  TcpUdpDeal /  TaPromotion
反例： macroPolo /  UserDo /  XMLService /  TCPUDPDeal /  TAPromotion

1. 【强制】常量命名全部大写，单词间用下划线隔开，力求语义表达完整清楚，不要嫌名字长。
正例：  `MAX_STOCK_COUNT`
反例：  `MAX_COUNT`

1. 【强制】抽象类命名使用 `Abstract` 或 `Base` 开头 ； 异常类命名使用 `Exception` 结尾 ； 测试类命名以它要测试的类的名称开始，以 `Test` 结尾。

1. 【强制】 POJO 类中布尔类型的变量，都不要加 `is` ，否则部分框架解析会引起序列化错误。
反例：定义为基本数据类型 `Boolean isDeleted;` 的属性，它的方法也是 `isDeleted()` ， 
RPC框架在反向解析的时候，“以为”对应的属性名称是 deleted ，导致属性获取不到，进而抛出异常。

1. 【强制】包名统一使用小写，点分隔符之间有且仅有`一个`自然语义的英语单词。包名统一使用单数形式，但是类名如果有复数含义，类名可以使用复数形式。
正例： 应用工具类包名为 `com.alibaba.open.util` 、类名为 `MessageUtils`（ 此规则参考spring 的框架结构 ）

1. 【参考】各层命名规约：
    -  获取`单个`对象的方法用 `get` 做前缀。
    -  获取`多个`对象的方法用 `list` 做前缀。
    -  获取`统计值`的方法用 `count` 做前缀。
    -  `插入`的方法用 `save`（ 推荐 ） 或 `insert` 做前缀。
    -  `删除`的方法用 `remove`（ 推荐 ） 或 `delete` 做前缀。
    -  `修改`的方法用 `update` 做前缀。
    
1. 【参考】领域模型命名规约:
    -  数据对象： xxxDO ， xxx 即为数据表名。
    -  数据传输对象： xxxDTO ， xxx 为业务领域相关的名称。
    -  展示对象： xxxVO ， xxx 一般为网页名称。
    -  POJO 是 DO / DTO / BO / VO 的统称，禁止命名成 xxxPOJO 。
    
## 常量定义
1. 【强制】不允许任何魔法值 （ 即未经定义的常量 ） 直接出现在代码中。
反例：
```java
String key  = " Id # taobao_" +  tradeId;
cache.put(key ,  value);
```

1. 【推荐】不要使用一个常量类维护所有常量，应该按常量功能进行归类，分开维护。
如：缓存相关的常量放在类： `CacheConsts` 下 ； 系统配置相关的常量放在类： `ConfigConsts` 下。
说明：大而全的常量类，非得使用查找功能才能定位到修改的常量，不利于理解和维护。
> 一方库：本工程中的各模块的相互依赖
> 二方库：公司内部的依赖库，一般指公司内部的其他项目发布的jar包
> 三方库：公司之外的开源库， 比如apache、ibm、google等发布的依赖

## 代码格式

1. 【强制】单行字符数限制不超过 `120` 个，超出需要换行，换行时遵循如下原则：
    -  第二行相对第一行缩进 `4 个空格`，从第三行开始，不再继续缩进。
    -  运算符与下文一起换行。
    -  方法调用的`点`符号与下文一起换行。
    -  在多个参数超长，在`逗号`后换行。
    -  在括号前不要换行。
    
1. 【强制】 IDE 的 `text file encoding` 设置为 `UTF-8`; IDE 中文件的`换行符`使用 `Unix `格式，不要使用 windows 格式。

1. 【推荐】没有必要增加若干空格来使某一行的字符与上一行对应位置的字符对齐。

## OOP规约
1. 关于基本数据类型与包装数据类型的使用标准如下：
    -  【强制】所有的 `POJO` 类属性必须使用包装数据类型。
    -  【强制】 `RPC` 方法的返回值和参数必须使用包装数据类型。
    -  【推荐】所有的`局部变量`使用基本数据类型。
说明： POJO 类属性没有初值是提醒使用者在需要使用时，必须自己显式地进行赋值，任何`NPE` 问题，或者入库检查，都由使用者来保证。
正例：数据库的查询结果可能是 `null` ，因为自动拆箱，用基本数据类型接收有 `NPE` 风险。
反例：比如显示成交总额涨跌情况，即正负 `x %`， `x` 为基本数据类型，调用的 `RPC` 服务，
    调用不成功时，返回的是默认值，页面显示：`0%`，这是不合理的，应该显示成中划线-。
    所以包装数据类型的 `null` 值，能够表示额外的信息，如：远程调用失败，异常退出。
    
1. 【强制】定义 `DO / DTO / VO` 等 POJO 类时，不要设定任何属性默认值。
反例： POJO 类的 `gmtCreate` 默认值为 `new Date();`
    但是这个属性在数据提取时并没有置入具体值，在更新其它字段时又附带更新了此字段，导致创建时间被修改成当前时间。

1. 【强制】构造方法里面禁止加入任何业务逻辑，如果有初始化逻辑，请放在 `init` 方法中。

1. 【推荐】 类内方法定义顺序依次是：`公有方法或保护方法` > `私有方法` >  `getter / setter方法`。
说明：公有方法是类的调用者和维护者最关心的方法，首屏展示最好 ； 保护方法虽然只是子类关心，也可能是“模板设计模式”下的核心方法 ；
    而私有方法外部一般不需要特别关心，是一个黑盒实现 ； 
    因为方法信息价值较低，所有 Service 和 DAO 的 getter / setter 方法放在类体最后。
    
## 集合处理
1. 【强制】泛型通配符`<?  extends T >`来接收返回的数据，此写法的泛型集合不能使用 `add` 方法，
而 `<? super T>` 不能使用 `get` 方法，做为接口调用赋值时易出错。
说明：扩展说一下 `PECS(Producer Extends Consumer Super) `
原则：1）频繁往外读取内容的，适合用上界 `Extends` 。2）经常往里插入的，适合用下界 `Super` 。

1. 【推荐】集合初始化时，指定集合初始值大小。
正例： `initialCapacity = (需要存储的元素个数 / 负载因子) + 1`。
注意负载因子（即loaderfactor）默认为 `0.75`， 如果暂时无法确定初始值大小，请设置为 `16`。

## 并行处理
1. 【强制】线程池不允许使用 `Executors` 去创建，而是通过 `ThreadPoolExecutor` 的方式，这样的处理方式让写的同学更加明确线程池的运行规则，规避资源耗尽的风险。
说明： Executors 返回的线程池对象的弊端如下：
    -  `FixedThreadPool` 和 `SingleThreadPool` :允许的`请求队列`长度为 `Integer.MAX_VALUE` ，可能会堆积大量的请求，从而导致 OOM 。
    -  `CachedThreadPool` 和 `ScheduledThreadPool` :允许的`创建线程`数量为 `Integer.MAX_VALUE` ，可能会创建大量的线程，从而导致 OOM 。
    
1. 【强制】 `SimpleDateFormat` 是线程不安全的类，一般不要定义为 `static` 变量，如果定义为`static` ，必须`加锁`，或者使用 `DateUtils` 工具类。
正例：注意线程安全，使用 `DateUtils` 。
亦推荐如下处理：
```java
private static final ThreadLocal<DateFormat> df = new ThreadLocal<DateFormat>() {
    @ Override
    protected DateFormat initialValue() {
        return new SimpleDateFormat("yyyy-MM-dd");
    }
};
```
说明：如果是 JDK 8 的应用，可以使用 `Instant` 代替 `Date` ， `LocalDateTime` 代替 `Calendar` ，
`DateTimeFormatter` 代替 `Simpledateformatter` ，官方给出的解释： simple beautiful strong immutable thread-safe 。

1. 【强制】多线程并行处理定时任务时， `Timer` 运行多个 `TimeTask` 时，
只要其中之一没有捕获抛出的异常，其它任务便会自动终止运行，
使用 `ScheduledExecutorService` 则没有这个问题。

## 其他
1. 【强制】后台输送给页面的变量必须加 `$!{var}` ——中间的感叹号。
说明：如果 `var = null` 或者`不存在`，那么 `${var}` 会直接显示在页面上。

# 异常日志
## 日志规约
1. 【强制】日志文件推荐至少保存 15 天，因为有些异常具备以“周”为频次发生的特点。

1. 【强制】避免重复打印日志，浪费磁盘空间，务必在 `log4j.xml` 中设置 `additivity = false` 。
正例： `<logger name="com.taobao.dubbo.config" additivity="false"> `

# MySQL数据库
## 建表规约
1. 【强制】表达是与否概念的字段，必须使用 `is_xxx` 的方式命名，数据类型是 `unsigned tinyint`（ 1 表示是，0 表示否 ） 。

1. 【强制】主键索引名为 `pk_字段名`；唯一索引名为 `uk_字段名` ； 普通索引名则为 `idx_字段名`。

1. 【强制】小数类型为 `decimal` ，禁止使用 `float` 和 `double` 。
说明： `float` 和 `double` 在存储的时候，存在精度损失的问题，很可能在值的比较时，得到不正确的结果。
如果存储的数据范围超过 `decimal` 的范围，建议将数据拆成整数和小数分开存储。

1. 【强制】表必备三字段： `id` ,  `gmt_create` ,  `gmt_modified`。
说明：其中 `id` 必为主键，类型为 `unsigned bigint` 、单表时自增、步长为 `1`。 `gmt_create` ,`gmt_modified` 的类型均为 `date_time` 类型。

## 索引规约
1. 【强制】 超过三个表禁止 `join` 。需要 `join` 的字段，数据类型必须绝对一致 ； 
多表关联查询时，保证被关联的字段需要有索引。
说明：即使双表 join 也要注意表索引、 SQL 性能。

1. 【强制】在 varchar 字段上建立索引时，必须指定索引长度，没必要对全字段建立索引，根据实际文本区分度决定索引长度即可。
说明：索引的长度与区分度是一对矛盾体，一般对字符串类型数据，长度为 20 的索引，
区分度会高达 90%以上，可以使用 `count(distinct left( 列名, 索引长度 )) / count( * )` 的区分度来确定。

1. 【强制】页面搜索严禁左模糊或者全模糊，如果需要请走搜索引擎来解决。
说明：索引文件具有 B-Tree 的最左前缀匹配特性，如果左边的值未确定，那么无法使用此索引。

1. 【推荐】利用延迟关联或者子查询优化超多分页场景。
说明： MySQL 并不是跳过 offset 行，而是取 offset + N 行，然后返回放弃前 offset 行，返回N 行，
那当 offset 特别大的时候，效率就非常的低下，要么控制返回的总页数，要么对超过特定阈值的页数进行 SQL 改写。
正例：先快速定位需要获取的 id 段，然后再关联：
`SELECT a.* FROM 表 1 a, (select id from 表 1 where 条件 LIMIT 100000,20 ) b where a.id=b.id`

1. 【推荐】建组合索引的时候，区分度最高的在最左边。
正例：如果 `where a =?  and b =?` ， a 列的几乎接近于唯一值，那么只需要单建 `idx_a` 索引即可。
说明：存在非等号和等号混合判断条件时，在建索引时，请把等号条件的列前置。如： `where a >? and b =?`
那么即使 a 的区分度更高，也必须把 b 放在索引的最前列。
 
## SQL语句
1. 【强制】不要使用 `count(列名)` 或 `count(常量)` 来替代 `count(*)` ， `count(*)` 是SQL92定义的标准统计行数的语法，跟数据库无关，跟 NULL 和非 NULL 无关。
说明： `count(*)` 会统计值为 NULL 的行，而 `count(列名)` 不会统计此列为 NULL 值的行。

1. 【强制】当某一列的值全是 `NULL` 时， `count(col)` 的返回结果为 `0`，但 `sum(col)` 的返回结果为NULL ，因此使用 sum() 时需注意 NPE 问题。
正例：可以使用如下方式来避免 sum 的 NPE 问题： `SELECT IF(ISNULL(SUM(g)) ,0, SUM(g)) FROM table;`

1. 【强制】不得使用外键与级联，一切外键概念必须在应用层解决。
说明： （ 概念解释 ） 学生表中的 student_id 是主键，那么成绩表中的 student_id 则为外键。
如果更新学生表中的 student_id ，同时触发成绩表中的 student_id 更新，则为级联更新。
外键与级联更新适用于单机低并发，不适合分布式、高并发集群 ； 级联更新是强阻塞，存在数据库更新风暴的风险；
外键影响数据库的插入速度。

1. 【强制】禁止使用存储过程，存储过程难以调试和扩展，更没有移植性。

1. 【强制】数据订正时，删除和修改记录时，要先 select ，避免出现误删除，确认无误才能执行更新语句。
