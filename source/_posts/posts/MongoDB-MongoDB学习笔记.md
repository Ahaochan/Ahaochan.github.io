---
title: MongoDB学习笔记
url: MongoDB_simple_use
tags:
  - MongoDB
categories:
  - MongoDB
date: 2018-12-07 15:48:55
---
# 前言
`mongodb`是一个`NoSQL`数据库, 可以分词查询, 可以基于地理位置查询, 记录以`JSON`形式存储.
`mongodb`的数据表又叫做数据集合, 关键字为`collection`.
`mongodb`是不存在`join`这个概念的, 所以一切的关联查询都得通过外部程序来做.

<!-- more -->

# 安装配置(基于v3.4.18)
安装教程: [Install MongoDB Community Edition on Red Hat Enterprise or CentOS Linux](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/)(国内可以用阿里云`yum`镜像).
```sh
# 1. 安装
yum install -y mongodb-org
# 2. 初始化
mkdir -p /opt/mongodb/data/db /opt/mongodb/log
cp /etc/mongod.conf /opt/mongodb/mongod.conf
# 3. 修改配置文件
sed -i 's#/var/log/mongodb/mongod.log#/opt/mongodb/log/mongod.log#g' /opt/mongodb/mongod.conf
sed -i 's#/var/lib/mongo#/opt/mongodb/data/db#g' /opt/mongodb/mongod.conf
sed -i 's#/var/run/mongodb/mongod.pid#/opt/mongodb/mongod.pid#g' /opt/mongodb/mongod.conf
# 4. 查看版本号
mongod --version
# 5. 启动
mongod -f /opt/mongodb/mongod.conf
# 6. 关闭
mongo 127.0.0.1:27071/test
use admin # 使用 admin 数据库
db.shutdownServer()
```

# 用户权限

## auth 用户名密码登录
```sh
# 1. 创建用户
db.createUser({
  user: "ahao",
  pwd: "ahao",
  customData: {msg:"我是一个新用户"},
  roles:[{role:"dbOwner", db:"admin"}]
})
角色类型: read、readWrite、dbAdmin、dbOwner、userAdmin
dbOwner = read + readWrite + dbAdmin

# 2. 开启auth验证, 修改 /opt/mongodb/mongodb.conf
system:
  authorization: enabled
  
# 3. 启动, 查询所有用户
mongod -f /opt/mongodb/mongodb.conf
mongo 127.0.0.1:12345 -u ahao -p ahao
use admin
db.system.users.find()

# 4. 创建角色
db.createRole({
  _id: "唯一id",
  role: "角色名",
  db: "数据库名",
  privileges: [
    { resource:{db:"数据库名", collection:"集合名", actions:[允许执行的操作]}}
  ]
  roles: [继承哪些角色]
})
```

## 集群keyfile
keyfile文件认证

# 数据库
`mongodb`数据库不用新建, 直接`use`, 数据库会在插入记录的时候自动创建数据库及数据集合.
```sh
# 1. 新建数据库(插入记录时自动创建数据库及数据集合)
use test_db
db.test_collection.insert({x:1})

# 2. 显示数据库
show dbs
  admin   0.000GB
  local   0.000GB
  test_db 0.000GB

# 3. 删除数据库
use test_db
db.dropDatabase()
```

# 表collection
同样, 数据表也是在插入时自动创建.
和关系型数据库不同, 不需要提前设置字段.
```sh
# 1. 切换到 test 数据库
use test_db

# 2. 创建数据表(插入记录时自动创建)
show collections # 没有表
db.test_collection.insert({x:1})
show collections
  test_collection

# 3. 删除数据表
> db.test_collection.drop()
```

# 索引
在`v3.0.0`后, [官方文档](https://docs.mongodb.com/manual/reference/method/db.collection.ensureIndex/)提到创建索引的函数`createIndex()`替换掉了`ensureIndex()`. 当然非要使用`ensureIndex()`也是可以的.
创建索引的格式: `db.集合名.createIndex({索引值}, {索引属性})`

| 索引属性 | 语法 | 默认 |
|:-------:|:----:|:----:|
| 名称 | `db.集合名.createIndex({索引值}, {name:"索引名称"})` | `字段名_1`或`字段名_-1` |
| 唯一性 | `db.集合名.createIndex({索引值}, {unique:[true or false]})` | `false` |
| 稀疏性 | `db.集合名.createIndex({索引值}, {sparse:[true or false]})` | `true`, 避免为插入记录不存在的字段创建索引 |
| 是否定时删除 | `db.集合名.createIndex({索引值}, {expireAfterSeconds:秒数})` | 不删除 |

## 没有属性的普通索引

| 索引类型 | 说明 | 创建方法(1为正序, -1为逆序) |
|:------------:|:------:|:------------:|
| `_id`索引 | 自动创建的索引, 作为记录的唯一主键 | `db.test_collection.insert({name:1})` |
| 单键索引 | 为一个字段创建的索引, 字段值为**单个**元素 | `db.test_collection.createIndex({name:1})` |
| 多键索引 | 为一个字段创建的索引, 字段值为**数组**元素 | `db.test_collection.createIndex({class:1})` |
| 复合索引 | 为**多个**字段创建的索引 | `db.test_collection.createIndex({name:1, age:1})` |

```sh
# 使用 test 数据库
use test_db

# 1. 查看索引, 格式: db.数据集合.getIndexes()
db.test_collection.getIndexes()

# 2. _id索引自动创建, 每条插入的数据都会自动生成一个`_id`字段, 作为`key`.
db.test_collection.insert({name:"Tom", age:12, friends:["Sum", "Kim"]})

# 3. 创建索引, 格式: db.数据表.createIndex({索引字段: [1|-1]}), 1为正序, -1为逆序
## 单个元素的单键索引
db.test_collection.createIndex({name:1})
## 多个元素的多键索引
db.test_collection.createIndex({friends:1})
## 多个字段的复合索引
db.test_collection.createIndex({name:1, age:1})

# 4. 删除索引
db.test_collection.dropIndex("索引名")
```

## 过期索引TTL
一定时间后会过期的索引, 存储的值必须是时间类型, 如`new Date()`. 如果是数组, 则取最小的时间. 
一个字段不能同时有过期索引和复合索引. 

当数据过期时, 对应的数据会自动删除. 但是`mongodb`删除任务`60`秒执行一次, 所以过期时间最好不要小于`60`秒.
适用于登录信息、日志信息、缓存等不重要的信息.
创建语法: `db.数据集合.createIndex({时间字段:1}, {expireAfterSeconds:秒数})`
```sh
# 初始化数据
use test_db
db.login_info.insert({name:"Tom", login_time:new Date()})

# 创建索引, 10秒后过期
db.login_info.createIndex({login_time:1}, {expireAfterSeconds:10})

# 等待过期后, 查询不到过期数据
db.login_info.find()
```

## 文本索引
说是文本索引, 其实就是对选择的字段进行分词索引. 所选的字段可以一个, 也可以多个.
一个数据集只有一个文本索引, 且只能是字符串类型的字段. 
查询文本索引时, 不允许使用`hint()`指定索引进行查询.
创建语法: `db.数据集合.createIndex({字段:"text"})`
```sh
# 单个字段的文本索引
db.test_collection.createIndex({name:"text"})
# 多个字段的文本索引
db.test_collection.createIndex({name:"text", address:"text"})
# 所有字段的文本索引
db.test_collection.createIndex({"$**":"text"})
```

查询语法, 多个关键字用空格分隔, 默认为`or`查询.
```sh
语法
db.test_collection.find({
  $text: {
    $search: 搜索字符串, 
    $language: 指定语言(社区版不支持中文),
    $caseSensitive: 是否大小写敏感(默认false),
    $diacriticSensitive: 是否区别发音符号(默认false)
  }
})

# 查询单个关键词, 匹配包含hello或world的文本
db.test_collection.find({$text:{$search:"hello world"}})
# 查询单个关键词, 匹配包含hello world的文本
db.test_collection.find({$text:{$search:"\"hello world\""}})
# 查询多个关键词, 匹配包含hello且不包含world的文本
db.test_collection.find({$text:{$search:"hello -world"}})
# 查询多个关键词, 查询包含ssl certificate 且 包含authority或key或ssl或certificate中任意一个 的文本
db.test_collection.find({$text:{$search:"\"ssl certificate\" authority key"}})
# 文本相似度排序
db.test_collection.find({$text:{$search:"hello"}}, {score:{$meta:"textScore"}}).sort({score:{$meta:"textScore"}})
```

## 2d地理位置索引(平面)
插入语法: `db.数据集合.insert({字段名:[经度(-180,180), 纬度(-90,90)]})`
创建语法: `db.数据集合.createIndex({字段:"2d"},{min:最小值,max:最大值,bits:精度(默认26) })`
```sh
# $near查询距离(10,20)最近的点
db.test_location.find({loc:{$near:[10,20]}})
# $near查询距离(10,20)最近的10个点
db.test_location.find({loc:{$near:[10,20]}}).limit(10)
# $near查询距离(10,20)最大距离为10的点
db.test_location.find({loc:{$near:[10,20], $maxDistance:10}})

# $geoWithin 查询某个形状内的点
# 查询对角坐标为(1,2),(3,4)组成的矩形内的点
db.test_location.find({loc:{$geoWithin:{$box:[[1,2],[3,4]]}}})
# 查询圆心坐标为(1,2), 半径为3的圆内的点
db.test_location.find({loc:{$geoWithin:{$center:[[1,2], 3]}}})
# 查询坐标为(1,2),(1,10),(2,10),(1,5)组成的多边形内的点
db.test_location.find({loc:{$geoWithin:{$polygon:[[1,2], [1,10], [2,10], [1,5]]}}})

# 返回更多数据的查询
db.runCommand({
    geoNear: 集合名,
    near: [x,y],
    minDistance: 最小距离(对2d索引无效, 对2dsphere索引有效),
    maxDistance: 最大距离
    num: 数量
})
```

## 2dsphere地理位置索引(球面)
插入语法: `db.数据集合.insert({字段名:{type:"Point",coordinates:[经度(-180,180), 纬度(-90,90)]}})`
创建语法: `db.数据集合.createIndex({字段:"2dsphere"})`
点用`GeoJSON`的形式表示, 参考[GeoJSON Objects](https://docs.mongodb.com/manual/reference/geojson/)
```sh
# 返回更多数据的查询
db.runCommand({
    geoNear: 集合名,
    near: GeoJSON形式的值,
    minDistance: 最小距离(对2d索引无效, 对2dsphere索引有效),
    maxDistance: 最大距离
    num: 数量
})
```

# 插入更新删除
```sh
# 1. 插入数据, 格式: db.数据表.insert(json);
# 插入单条数据
> db.test_collection.insert({name:"小明", age: 10})
# 插入多条数据
> for(i=1;i<3;i++) db.test_collection.insert({name:"name"+i, age:i})

# 2. 更新数据, 格式: db.数据表.update(查询条件, 修改后的值, 是否不存在则插入, 是否批量更新);
## 会覆盖所有字段, age 字段会删除
> db.test_collection.update({name:"小明"}, {name:"新名字"})
## 只更新 name 字段, age 字段不会更新
> db.test_collection.update({name:"小明"}, {$set{name:"新名字"}})
## 不存在则插入数据
> db.test_collection.update({name:"小红"}, {name:"新小红", age: 11}, true)
## 批量更新
> db.test_collection.update({age:10}, {$set{age: 21}}, false, true)

# 3. 删除数据
> db.test_collection.remove({age:21})
```

# 查询
```sh
# 查询所有数据
db.test_collection.find()
# 查询总数
db.test_collection.find().count()
# 查询第4条到第7条数据, 按name倒序排序
db.test_collection.find().skip(3).limit(4).sort({name: -1})
# 查询一条数据
db.test_collection.findOne({name:"小明"})
# 查询存在某个字段的记录
> db.test_collection.find({x:{$exists:true}})
# 按写入顺序逆序10条记录
> db.test_collection.find().sort({$natural:-1}).limit(10)
```