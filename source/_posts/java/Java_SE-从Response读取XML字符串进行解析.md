---
title: 从Response读取XML字符串进行解析
url: read_XML_string_from_Response_for_parsing
tags:
  - XML
categories:
  - Java SE
date: 2018-04-18 11:06:13
---
# 前言
调用`WebService`接口返回了`XML`的数据, 需要解析并封装为一个`AjaxDto(status, msg, obj)`对象。
项目中已经依赖了`Apache`的[commons-configuration](https://mvnrepository.com/artifact/commons-configuration/commons-configuration), 所以就直接拿来用了。

<!-- more -->

# 样例
响应体
```xml
<?xml version="1.0" encoding="GBK" ?> 
<response>
    <head>
        <code>integer</code>
        <message>String</message>
    </head>
</response>
```
解析代码
```java
public class XmlParser {
    private static final Logger logger = LoggerFactory.getLogger(XmlParser.class);

    public static void main(String[] args) throws Exception {
        String xml = "<?xml version=\"1.0\" encoding=\"GBK\" ?> \n" +
                "<response>\n" +
                "<head>\n" +
                "<code>integer</code>\n" +
                "<message>String</message>\n" +
                "</head>\n" +
                "</response>\n";
        XmlParser parser = XmlParser.init(xml);
        if(parser == null){
            logger.error("创建失败");
            return;
        }
        System.out.println(parser.getString("head.code"));
    }

    private XMLConfiguration config;

    public static XmlParser init(String xml) {
        // 1. 字符串转为输入流
        try (InputStream in = new ByteArrayInputStream(xml.getBytes());) {
            XmlParser parser = new XmlParser(in);
            return parser;
        } catch (IOException | ConfigurationException e) {
            logger.error("加载xml错误", e);
        }
        return null;
    }

    private XmlParser(InputStream in) throws ConfigurationException {
        // 2. 读取输入流数据
        config = new XMLConfiguration();
        config.load(in);
    }
    // 3. 获取节点数据
    public String getString(String xpath){
        return config.getString(xpath);
    }
}
```

# 坑
注意以下代码
```java
System.out.println(parser.getString("response.head.code"));
System.out.println(parser.getString("head.code"));
```
我第一次使用的时候, 是使用第一行`response.head.code`代码的, 但是获取失败。
改成第二行`head.code`代码就行了。
后来想了下原因, `response`是根节点, 根节点**有且只有**一个。所以也就不需要特意去指定了。