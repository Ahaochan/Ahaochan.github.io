---
title: GreenDAO使用心得
url: how_to_use_GreenDAO
tags:
  - 数据库
  - ORM
categories:
  - Android
date: 2016-09-10 17:17:13
---

# 前言
作为一个程序员，基本的`SQL`语句是必须掌握的，但是如果单单使用原生的`SQL`语句，开发效率就太低了.
虽然`Android`有给我们提供一套封装好的`API`，但我觉得并没有提高多少便利，反而增加了学习成本。
我选择的是[greenDAO](https://github.com/greenrobot/greenDAO) .
虽然`github`上[realm-java](https://github.com/realm/realm-java) 的星星比[greenDAO](https://github.com/greenrobot/greenDAO)高一点.
但是[realm-java](https://github.com/realm/realm-java) 有一个弊端，就是`apk`的体积会大上5M左右。

<!-- more -->

下面一图说明`greenDAO`的好处
{% asset_img GreenDAO使用心得_01.png %}

# 简单使用
## 导入
[greenDAO](https://github.com/greenrobot/greenDAO) 已经讲解的很清楚了。
但是还是要说一下
```groovy
//这段代码是放在根build.gradle而不是某个module的build.gradle里的
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'org.greenrobot:greendao-gradle-plugin:3.1.1'
    }
}
```

```groovy
//这段代码是放在android的module的build.gradle里的
apply plugin: 'org.greenrobot.greendao'
dependencies {
    compile 'org.greenrobot:greendao:3.1.1'
}
```

```groovy
//这段代码是放在java library的module的build.gradle里的(下一小节会提到)
dependencies {
    compile fileTree(include: ['*.jar'], dir: 'libs')
    compile 'org.greenrobot:greendao-generator:3.1.0'
}
```


## 创建一个新的Module
首先需要一个`Java Library`，通俗的讲，就是用来创建一系列的实体类（一个类对应一个表）和数据库工具类。
并且导入`compile 'org.greenrobot:greendao-generator:3.1.0'`，上面有提到。
{% asset_img GreenDAO使用心得_02.png %}
{% asset_img GreenDAO使用心得_03.png %}


注意，我们创建的是`Java Library`，是`Java Library`，是`Java Library`。
所以要用`Java`的方式写代码，而不是`Android`的方式。
既然是`Java`的方式，就要写`main`函数。
```java
public class Main {
    private static final int VERSION = 1;//数据库的版本号，用来检测是否升级数据库
    private static final String PACKAGE = "com.ahao.demo.dao";//自动生成代码的包名
    private static final String OUT_DIR = "./app/src/main/java-gen";//自动生成代码的路径
    public static void main(String[] args) throws Exception {
        // 创建了一个用于添加实体（Entity）的模式（Schema）对象。
        Schema schema = new Schema(VERSION, PACKAGE);
        // 添加一个实体(类),一个实体(类)对应一张表
        addNote(schema);
        // 创建存放自动生成代码的目录
        rebuild(OUT_DIR);
        // 自动生成代码
        new DaoGenerator().generateAll(schema, OUT_DIR);
    }

    private static void addNote(Schema schema) {
        // 一个实体（类）就关联到数据库中的一张表，此处表名为「Note」（既类名）
        Entity note = schema.addEntity("Note");
        // 你也可以重新给表命名
        // note.setTableName("NODE");

        // greenDAO 会自动根据实体类的属性值来创建表字段，并赋予默认值
        // 接下来你便可以设置表中的字段：
        note.addIdProperty();//添加一个id主键字段
        note.addStringProperty("text").notNull();//添加一个名为TEXT的String字段
        // 与在 Java 中使用驼峰命名法不同，默认数据库中的命名是使用大写和下划线来分割单词的。
        // 例如,一个名为creationDate的属性,在表中的字段名为CREATION_DATE
        note.addStringProperty("comment");
        note.addDateProperty("date");//添加一个Data字段
    }

    // 确保outdir文件夹存在
    public static void rebuild(String file) {
        File outDir = new File(OUT_DIR);
        outDir.delete();
        outDir.mkdir();
    }
}
```
那么问题来了，生成的代码到哪里去了呢？要如何使用呢？

## 自动生成代码
运行代码
{% asset_img GreenDAO使用心得_04.png %}

如果出现以下信息就是创建成功
{% asset_img GreenDAO使用心得_05.png %}

 切换到`Project Files`视图，可以看到代码已经自动生成了 
{% asset_img GreenDAO使用心得_06.png %}
{% asset_img GreenDAO使用心得_07.png %}


这里[引用](http://my.oschina.net/cheneywangc/blog/196354) 一下
- DaoMaster：一看名字就知道它是Dao中的最大的官了。它保存了sqlitedatebase对象以及操作DAO classes（注意：不是对象）。其提供了一些创建和删除table的静态方法，其内部类OpenHelper和DevOpenHelper实现了SQLiteOpenHelper并创建数据库的框架。
- DaoSession：会话层。操作具体的DAO对象（注意：是对象），比如各种getter方法。
- XXXDao：实际生成的某某DAO类，通常对应具体的java类，比如NoteDao等。其有更多的权限和方法来操作数据库元素。
- XXXEntity：持久的实体对象。通常代表了一个数据库row的标准java properties。


 
