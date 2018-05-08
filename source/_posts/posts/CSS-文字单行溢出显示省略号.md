---
title: 文字单行溢出显示省略号
url: Text_single_line_overflow_display_ellipses
tags:
  - CSS
categories:
  - CSS
date: 2018-05-08 14:26:00
---
# 前言
搜索候选框需要单行显示, 超出长度的部分用省略号表示。

<!-- more -->

# 简单粗暴的方式
直接使用`substring`截取字符串, 然后加上省略号。
但是这种方式不支持响应式。
```js
var title = '1234567890';
if (title.length > 23) {
    title = title.substring(0, 23) + '...';
}

// substr和substring的区别
alert("abc".substr(1,2));    // 从第2个字符(0为起始)之后长度为2的子字符串, returns "bc"
alert("abc".substring(1,2)); // 从第2个字符(0为起始)开始, 第3个字符之前的子字符串, returns "b"
```

# CSS3的解决方案(支持IE8)
添加以下样式即可
```css
.ellipses {
    overflow: hidden;        /* 当内容溢出元素框时, 超出部分隐藏 */
    white-space: nowrap;     /* 文本不会换行，文本会在在同一行上继续，直到遇到 <br> 标签为止 */
    text-overflow: ellipsis; /* 规定当文本溢出包含元素时, 用省略号表示超出部分 */
}
```