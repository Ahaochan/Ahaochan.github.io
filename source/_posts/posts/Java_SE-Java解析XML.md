---
title: Java解析XML
url: Java_parsing_XML
tags:
  - XML
categories:
  - Java SE
date: 2016-10-09 22:31:08
---

# 前言
> {% post_link posts/编程杂谈-XML语法详解 %}

定义一个`xml`文档
<!-- more -->

```xml
<?xml version="1.0" encoding="UTF-8"?>
<store>
    <book id="01">第一本书</book>
    <book id="02">第二本书</book>
</store>
```

# 原生解析
## DOM解析
- 优点：容易实现增删改操作
- 缺点：`xml`过大时容易造成内存溢出

[Document API文档](http://tool.oschina.net/uploads/apidocs/jdk-zh/org/w3c/dom/Document.html) 和`js`中的{% post_link Web前端/JavaScript/DOM操作 DOM操作.md %}类似

```java
public static void main(String[] args) throws Exception{
    String filePath = "./src/main/resources/1.xml";

    DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
    DocumentBuilder builder = factory.newDocumentBuilder();
    Document doc = builder.parse(filePath);
    NodeList books = doc.getElementsByTagName("book"); // 根据标签名获取标签
    for (int i = 0; i < books.getLength(); i++) {
        Node book = books.item(i);
        NamedNodeMap attr= book.getAttributes();
        System.out.println(i+"i:"+book.getTextContent()); // 输出book标签的文本内容
        for(int j = 0; j < attr.getLength(); j++){
            System.out.println(j+"j:"+attr.item(j)); // 输出book标签的所有属性值
        }
    }
    // 添加一个标签
    Element newBook = doc.createElement("book");
    newBook.setAttribute("id", books.getLength()+1+""); // 设置属性
    doc.getElementsByTagName("store").item(0).appendChild(newBook); // 添加到内存document中，此时未写入磁盘
    TransformerFactory tffactory = TransformerFactory.newInstance();
    Transformer tf = tffactory.newTransformer(); 
    tf.transform(new DOMSource(doc), new StreamResult(filePath)); // 将document通过流的形式写入磁盘
}
```

## SAX解析
- 优点：不会造成内存溢出，适合查询
- 缺点：不能进行增删改操作

```java
@Test
public void testSAX() throws ParserConfigurationException, SAXException, IOException {
    SAXParserFactory factory = SAXParserFactory.newInstance();
    SAXParser parser = factory.newSAXParser();
    parser.parse(new File(filePath), new DefaultHandler(){
        @Override
        public void startElement(String uri, String localName,String qName,Attributes attributes)
                throws SAXException{
            System.out.print("<"+qName+">"); // 开始标签
        }

        @Override
        public void characters(char[] ch, int start, int length) throws SAXException {
            System.out.print(new String(ch, start, length)); // 标签内容
        }

        @Override
        public void endElement(String uri, String localName, String qName) throws SAXException {
            System.out.println("</"+qName+">"); // 结束标签
        }
    });
}
```

# dom4j解析
## 导入

[maven项目](https://mvnrepository.com/artifact/dom4j/dom4j/1.6.1)

```xml
<dependency>
    <groupId>dom4j</groupId>
    <artifactId>dom4j</artifactId>
    <version>1.6.1</version>
</dependency>
```

## 使用方法

```java
@Test
public void testDOM4J() throws DocumentException, IOException {
    SAXReader reader = new SAXReader();
    Document doc = reader.read(new File(filePath));
    Element root = doc.getRootElement();
    List<Element> books = root.elements("book");
    for(Element book : books){
        List<Element> names = book.elements("name");
        System.out.print("bookID:"+book.attributeValue("id"));
        for(Element name : names){
            System.out.println(name.getText());
        }
    }

    //写入操作
    Element newBook = root.addElement("book");
    newBook.addAttribute("id", books.size()+1+""); // 添加属性
    newBook.addElement("name").setText("第"+(books.size()+1)+"本书"); // 添加元素
    XMLWriter writer = new XMLWriter(new FileOutputStream(new File(filePath)), // 流
            OutputFormat.createPrettyPrint()); // 格式化写入
    writer.write(doc);
    writer.close();
}
```

## 支持xpath

导入[maven项目](https://mvnrepository.com/artifact/jaxen/jaxen/1.1.6)

```xml
<dependency>
    <groupId>jaxen</groupId>
    <artifactId>jaxen</artifactId>
    <version>1.1.6</version>
</dependency>
```

使用

```java
/*
//book 所有book标签
/store/book/name 所有store标签下的book标签下的name标签
/* 所有标签，通配符
/store/book[1]/name[last()] store标签下的第一个book标签下的最后一个name标签
//book[@id] 所有有id属性的book标签
//book[@id='01'] 所有id属性值为01的book标签
*/
@Test
public void testXPath() throws DocumentException {
    SAXReader reader = new SAXReader();
    Document doc = reader.read(new File(filePath));
    XPath xPath = new DefaultXPath("//name");
    List<Element> names = xPath.selectNodes(doc);
    for (Element name : names) {
        System.out.println(name.getTextTrim());
    }
}
```
