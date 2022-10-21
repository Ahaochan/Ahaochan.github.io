---
title: 为什么jQuery选择器只返回一个元素?
url: why_jQuery_selector_return_only_one_element
tags:
  - jQuery
categories:
  - JavaScript
date: 2017-07-18 11:31:08
---

# 前言
稍有常识的人都知道, 如果我们使用形如`$('p')`、`$('.myclass')`之类的选择器，会返回一个数组。
但今天在[必应](https://www.bing.com)中进行控制台js调试时, 却发现不管怎么用, 都只返回`第一个`元素。

<!-- more -->
# Chrome的坑
[Why does jQuery class selector only return one element?](https://stackoverflow.com/questions/44769950/why-does-jquery-class-selector-only-return-one-element)提到
该网页根本没有引入jQuery。在F12控制台中, `$`其实是`debugger`调试器的快捷方式`document.querySelector()`。
如果想要获取所有元素的话, 使用`$$(.myclass)`即可。

# 检查页面是否引入jQuery
使用`console.log($)`调试。
如果引入了jQuery, 则输出
```js
function (a,b){return new n.fn.init(a,b)}
```
如果没有引入jQuery, 则输出
```
function $(selector, [startNode]) { [Command Line API] }
```


# 参考资料
- [Why does jQuery class selector only return one element?](https://stackoverflow.com/questions/44769950/why-does-jquery-class-selector-only-return-one-element)提到
- [google developers](https://developers.google.com/web/tools/chrome-devtools/console/expressions)
