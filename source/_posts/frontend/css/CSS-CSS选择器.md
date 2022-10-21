---
title: CSS选择器
url: css_selector
tags:
  - CSS
categories:
  - CSS
date: 2017-02-20 10:29:44
---


# 基本选择器
## 标签元素选择器
```css
div {
    background-color:red;
    color:white;
}
```
<!-- more -->

## class类选择器
以`.`开头
```css
div.test1{ // 满足class为test1，且标签为div的形式，div可省略
    background-color:red;
    color:white;
}
// <div class="test1">测试</div>
```

## ID选择器
以`#`开头
```css
div#test2 { // 满足id为test2，且标签为div的形式，div可省略
    background-color:red;
    color:white;
}
// <div id="test2">测试</div>
```
# 扩展选择器
## 属性选择器
格式`元素名[属性名]{样式}`
给拥有某个属性的元素标签设置特定样式
```css
a[href][title] {color:red;}
a[href="http://www.w3school.com.cn/about_us.asp"] {color: red;}
```

## 关联选择器
在标签嵌套时使用，比如特定`div`标签中的`p`标签
```css
div p { /* 用空格隔开 */
    background-color:red;
    color:white;
}
/* <div><p>测试</p></div> */
```

## 组合选择器
把不同标签设置相同的样式
```css
div,p { /* 用,隔开 */
    background-color:red;
    color:white;
}
/* <div>测试</div><p>测试</p> */
```

## 伪元素选择器
[伪类选择器](http://www.w3school.com.cn/css/css_pseudo_classes.asp)
