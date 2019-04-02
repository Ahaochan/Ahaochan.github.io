---
title: Java导出Excel出现emoji乱码
url: Java_export_Excel_appears_emoji_garbled
tags:
  - Java SE
categories:
  - Java SE
date: 2019-04-02 11:24:22
---
# 前言
做后端开发经常需要导出`Excel`, 一般有两种选择`POI`、`JXLS`和`easyexcel`.
其实底层都是使用`POI`来做的.

<!-- more -->

# 三种框架分析
1. `Apache`名下的`POI`
   - 优点: 微软全家桶基本都可以做, 什么`Word`、`Excel`、`PPT`.
   - 缺点: 所有格式都要通过代码完成, 代码又长又臭.
1. `JXLS`专门用来操作`Excel`, 使用`JXLS`模板语法可以书写`Excel`模板, 底层使用`org.jxls.transform.poi.PoiTransformer`和`POI`做对接.
   - 优点: 使用`JXLS`模板语法, 可以将格式和代码解耦, 快速开发, 代码精简.
   - 缺点: 需要额外的学习成本学习`JXLS`模板语法(学什么不是学
1. `easyexcel`是阿里基于`POI`开发的`Excel`解析工具.
   - 优点: 据[`README`](https://github.com/alibaba/easyexcel/blob/master/README.md)说, 解决`POI`内存溢出问题.
   - 缺点: 没用过不评价

# emoji乱码代码单元测试
复现下测试环境, 依赖`pom.xml`
```xml
<dependencies>
    <!-- https://mvnrepository.com/artifact/org.apache.poi/poi -->
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi</artifactId>
        <version>3.17</version>
    </dependency>
     <!-- https://mvnrepository.com/artifact/org.apache.poi/poi-ooxml -->
    <dependency>
        <groupId>org.apache.poi</groupId>
        <artifactId>poi-ooxml</artifactId>
        <version>3.17</version>
    </dependency>
    
    <!-- poi-ooxml 依赖 poi-ooxml-schemas, 依赖 xmlbeans 2.6.0 -->
    <!-- https://mvnrepository.com/artifact/org.apache.xmlbeans/xmlbeans -->
    <!-- <dependency>
        <groupId>org.apache.xmlbeans</groupId>
        <artifactId>xmlbeans</artifactId>
        <version>2.6.0</version>
    </dependency> -->
</dependencies>
```
生成`Excel`的代码.
```java
public class Main {
    // 𤆕🔝biu～	better me人🌝
    public static final String UNICODE = "\uD850\uDD95\uD83D\uDD1Dbiu～\t\uE110better me\uE110人\uD83C\uDF1D";

    public static void main(String[] args) {
        createXLSX("C:/test.xlsx");
        createXLS("C:/test.xls");
    }

    public static void createXLSX(String filename) {
        try(XSSFWorkbook workbook = new XSSFWorkbook();
            FileOutputStream fos =new FileOutputStream(filename)) {

            XSSFSheet sheet = workbook.createSheet("TestSheet");
            XSSFRow row = sheet.createRow(0);
            XSSFCell cell1 = row.createCell(0);
            cell1.setCellValue(UNICODE);

            workbook.write(fos);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    public static void createXLS(String filename) {
        try(HSSFWorkbook workbook = new HSSFWorkbook();
            FileOutputStream fos =new FileOutputStream(filename)) {

            HSSFSheet sheet = workbook.createSheet("TestSheet");
            HSSFRow row = sheet.createRow(0);
            HSSFCell cell1 = row.createCell(0);
            cell1.setCellValue(UNICODE);

            workbook.write(fos);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```
运行完毕, 可以看到`xls`能正常输出`𤆕🔝biu～	better me人🌝`, 而`xlsx`只能输出`????biu～	better me人??`.
`emoji`表情不能输出.

# 解决方案(简单版)
解决方案有两种.
1. 升级`POI`为`4.0.0`以上.
2. 替换`xmlbeans`为`3.0.0`以上.

本质都是替换`xmlbeans`.

# 问题原因
为什么`xls`没问题, `xlsx`有问题?
因为`xls`的`HSSFRichTextString`使用了`UnicodeString`进行编码, 内联字符串, 没有重用字符串.
而`xlsx`为了解决内存问题, 将相同字符串先写入`sharedStrings.xml`, 重用字符串. 

我们可以将一个`xlsx`改为`zip`解压, 在里面可以找到一个`sharedStrings.xml`文件, 里面就存储着我们的字符串.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<sst count="1" uniqueCount="1" xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <si><t>????biu～	better me人??</t></si>
</sst>
```
那很明显就是写入`xml`的时候出了问题.

[Write 16 bits character to .xlsx file using Apache POI in Java](https://stackoverflow.com/a/38039869)提到了`org.apache.xmlbeans.impl.store.Saver`的`isBadChar`方法.
[点击查看源码`L1559`](https://github.com/apache/xmlbeans/blob/2.6.0/src/store/org/apache/xmlbeans/impl/store/Saver.java#L1559-L1567)
```java
abstract class Saver {
    private boolean isBadChar(char ch) {
        return ! (
            (ch >= 0x20 && ch <= 0xD7FF ) ||
            (ch >= 0xE000 && ch <= 0xFFFD) ||
            (ch >= 0x10000 && ch <= 0x10FFFF) ||
            (ch == 0x9) || (ch == 0xA) || (ch == 0xD)
            );
    }
}
```
以`🌝`这个字符为例, 它的`Unicode`编码为`\uD83C\uDF1D`, 一个`char`是存不下的, 要用两个`char`.
那么第一个`char`传入`isBadChar`, 得到`true`. 第二个`char`传入也得到`true`.
那么我们看下哪里有调用到这个`isBadChar`方法.
[点击查看源码`L2310`](https://github.com/apache/xmlbeans/blob/2.6.0/src/store/org/apache/xmlbeans/impl/store/Saver.java#L2310)
```java
abstract class Saver {
    private void entitizeAndWriteCommentText(int bufLimit) {
        // 省略部分代码
        for (int i = 0; i < bufLimit; i++) {
            char ch = _buf[ i ];
            if (isBadChar(ch))
                _buf[i] = '?';
            // 省略部分代码
        }
    }
}
```
有很多地方都有调用, 但是基本都是一个逻辑, 如果是`true`, 则替换为`?`, 所以我们才在`sharedStrings.xml`看到一堆`??`.
那这就是`xmlbeans`这个库的问题了, 不是我们代码的锅(甩锅大成功!

# xmlbeans 3.0.0 解决方案
再看看`xmlbeans 3.0.0`怎么解决的.
[点击查看源码`L286`](https://github.com/apache/xmlbeans/blob/3.0.0/src/store/org/apache/xmlbeans/impl/store/Saver.java#L286-L287)
```java
abstract class Saver {
    private boolean isBadChar(char ch) {
        return ! (
            Character.isHighSurrogate(ch) ||
            Character.isLowSurrogate(ch) ||
            (ch >= 0x20 && ch <= 0xD7FF ) ||
            (ch >= 0xE000 && ch <= 0xFFFD) ||
            (ch >= 0x10000 && ch <= 0x10FFFF) ||
            (ch == 0x9) || (ch == 0xA) || (ch == 0xD)
            );
    }
}
```
以`🌝`这个字符为例, 它的`Unicode`编码为`\uD83C\uDF1D`, 一个`char`是存不下的, 要用两个`char`.
那么第一个`char`传入`isBadChar`, 得到`false`. 第二个`char`传入也得到`false`.
所以也就不会被替换成`?`, `bug` 解决.

# 参考资料
- [Writing Unicode plane 1 characters with Apache POI](https://stackoverflow.com/a/51852614)
- [Write 16 bits character to .xlsx file using Apache POI in Java](https://stackoverflow.com/a/38039869)
- [Java导出Excel](https://www.yanghuandy.cn/2018/08/15/Java%E5%AF%BC%E5%87%BAExcel/)