---
title: CSS背景
url: css_how_to_set_background
tags:
  - CSS
categories:
  - CSS
date: 2017-03-01 10:26:50
---
# 设置纯色背景
```html
<style type="text/css">
    body {
        background-color:gray;
    }
</style>
```
<!-- more -->

# 设置图片背景
如果同时设置纯色背景和图片背景，则纯色背景在图片背景之下。并且图片背景会平铺整个屏幕。
- `background-repeat`属性可以设置平铺方式，`repeat-x`、`repeat-y`、`no-repeat`。
- `background-position`属性可以设置图片背景的位置。`top`、`bottom`等。
- `background-attachment`属性可以设置图片是否随文档滚动。`fixed`、`scroll`。
```html
<style type="text/css">
    body {
        background-image:url(http://cn.bing.com/sa/simg/CN_Logo_Gray.png);
        background-repeat:no-repeat;
        background-position:center;
        background-attachment:fixed;
    }
</style>
```
