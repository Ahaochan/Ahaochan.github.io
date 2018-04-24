---
title: CSS基础
url: css_foundation
tags:
  - CSS
categories:
  - CSS
date: 2017-02-19 10:35:55
---
# 语法
格式为`属性名:属性值;`
```html
<div style="background-color:red;color:white;">测试</div>
```
<!-- more -->
<div style="background-color:red;color:white;">测试</div>

# 优先级
由上到下，由外到内，优先级由低到高。
`style` > `id选择器` > `class类选择器` > `标签选择器`，优先级由低到高

# 引入方式
```html
<html>
<head>
    <style type="test/css">
        div {
            background-color:red;
            color:white;
        }
    </style>
    <style type="test/css">
        @import url(div.css);<!--外部引用，兼容性差，不使用-->
    </style>
    <link rel="stylesheet" type="text/css" href="div.css"/><!--外部引用-->
</head>
<body>
    <div style="background-color:red;color:white;">测试</div>
</body>
</html>
```

