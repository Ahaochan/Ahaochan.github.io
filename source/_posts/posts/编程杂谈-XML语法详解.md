---
title: XML语法详解
url: XML_syntax
tags:
  - XML
categories:
  - 编程杂谈
date: 2017-02-22 22:32:28
---
# 声明
目前`XML`有`1.0`和`1.1`两个版本，但是`1.1`不向下兼容，常用的是`1.0`版本
只能有一个根标签元素
```xml
<?xml version="1.0" encoding="utf-8"?>
<person></person>
```
<!-- more -->

# CDATA区
语法`<![CDATA[内容]]>`，解决频繁转义字符的问题，当成文本内容
```xml
<?xml version="1.0" encoding="utf-8"?>
<person>
    <code><![CDATA[(1<2)&&(2<3)?true:false;]]></code>
</person>
```

# PI指令设置XML样式
语法`<?xml-stylesheet type="text/css" href="test.css"?>`
将`css`样式应用于`XML`文档

# xml约束
限制xml中出现的标签名

## dtd约束
### dtd引入方式
```xml
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE 根元素名 SYSTEM "dtd路径">                <!--第一种，外部引用本地dtd-->
<!DOCTYPE 根元素名 [约束内容]>                      <!--第二种，内部引用dtd-->
<!DOCTYPE 根元素名 PUBLIC "dtd名称" "dtd的url路径"> <!--第三种，外部引用网络dtd-->
```
### dtd语法
先创建一个`DTD`文件`personDTD.dtd`，
1. 元素的语法格式为`<!ELEMENT 元素名 ([子元素名|#PCDATA|EMPTY|ANY])(+|*|?)>`
1. 属性的语法格式为`<!ATTLIST 元素名 属性名 属性类型 约束>`
1. 实体的语法格式为`<!ENTITY 实体名 实体值>`

```xml
<!--定义元素->
<!ELEMENT person (name+, age?)><!--含有子元素的元素，+出现不少于一次，？出现不多于一次，*出现任意多次-->
<!ELEMENT person (name | age)><!--含有子元素的元素，表示只能出现一个nama或者age
<!ELEMENT name (#PCDATA)><!--不含有子元素的元素-->
<!ELEMENT isMan EMPTY><!--不含有内容的元素-->
<!ELEMENT school ANY><!--任意的元素-->

<!--定义属性-->
<!ATTLIST name nameAttr CDATA #REQUIRED  <!--CDATA是字符串，#REQUIRED是必须出现-->
               pid ID #REQUIRED          <!--ID是只能字母和下划线开头-->
               sex CDATA "男"            <!--直接在后面加上字符串，表示默认值-->
>     
<!ATTLIST food like (苹果|香蕉|橘子) #IMPLIED> <!--枚举，#IMPLIED是可有可无-->
<!ATTLIST school CDATA #FIXED "学校">         <!--固定值，#FIXED只能选择固定属性值-->

<!--定义实体-->
<!ENTITY copyright "版权所有不得抄袭"><!--在xml中可用&copyright;引用该实体-->
```

### 示例
```xml
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE person SYSTEM "personDTD.dtd">
<person>
    <name>张三</name>
    <age>20</age>
    <!-- <error>编译出错</error> -->
</person>
```

## schema约束
`schema`是`xml`格式的一个约束文件。
需要先在命名空间引入`http://www.w3.org/2001/XMLSchema`，在`targetNamespace`中定义`schema`的引用地址名，用于在`xml`文件中引入。
和`xml`文件类似，每个子元素都在父元素之中。
```xml
<?xml version="1.0" encoding="utf-8"?>
<schema xmlns="http://www.w3.org/2001/XMLSchema" 
    targetNamespace="http://mySchemaUrl"
    elementFormDefault="qualified">
    <element name="store">
        <complexType><!--表示store元素有子元素-->
            <sequence><!--子元素严格按顺序显示-->

                <element name="book" maxOccurs="unbounded">
                    <complexType>
                        <sequence>
                            <element name="name" type="string" maxOccurs="unbounded"/><!--maxOccurs表示元素出现次数-->
                        </sequence>
                        <attribute name="id" type="int" use="required"/><!--book的属性，必须在最后声明-->
                    </complexType>
                </element>

            </sequence>
        </complexType>
    </element>
</schema>
```
在`xml`中引入时，先引入别名为`xsi`的`http://www.w3.org/2001/XMLSchema-instance`命名空间，
再引入自定义`schema`的引用地址，及`schema`文件名
```xml
<?xml version="1.0" encoding="utf-8"?>
<store xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://mySchemaUrl"
       xsi:schemaLocation="http://mySchemaUrl 1.xsd">

    <book id="01">
        <name>第一本书</name>
    </book>
    <book id="02">
        <name>第二本书</name>
        <name>第三本书</name>
    </book>
</store>
```
