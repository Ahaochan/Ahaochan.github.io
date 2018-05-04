---
title: jQuery的clone陷阱
url: Missing_semicolon_causes_IIFE_not_working
tags:
  - JavaScript
categories:
  - JavaScript
date: 2018-05-04 23:54:00
---
# 正文
先来看这两段代码, 执行之后可以看到控制台爆出**`log.(...) is not a function`的错误异常信息。
```js
window.onerror = undefined;
// 1. 执行错误
$(function () {
    console.log(" 测试1")
    (function () { alert("测试哈哈哈"); })();
});

// 2. 正确执行
$(function () {
    console.log(" 测试1");
    (function () { alert("测试哈哈哈"); })();
});
```

万物皆对象, 函数也是对象。
所以函数也可以返回函数, 做到`fun(arg1)(arg2)(arg3)`这种奇葩的语法。

我们再把第一种缺少分号的函数换个写法, 这两种写法是等价的。
```
$(function () {
    // 1. 原代码
    console.log(" 测试1")
    (function () { alert("测试哈哈哈"); })();
    
    // 2. 换种写法, 类似于`fun(arg1)(arg2)(arg3)`
    console.log(" 测试1")(function () { alert("测试哈哈哈"); })();
});
```
我们预想的执行方式截然不同。`console.log()`和匿名函数变成了一条语句。
即使是使用了`'use strict';`也不会在写代码的时候报错。
所以不要太过于依赖没有分号。

# 结合window.onerror造成更大杀伤力
第一行我加上了`window.onerror = undefined;`。
因为项目上使用了[开普云](https://www.kaipuyun.cn/)的一个`js`脚本。
```html
<script type="text/javascript" charset="utf-8" id="kpyfx_js_id_10000077" src="//fxsjcj.kaipuyun.cn/count/10000077/10000077.js"></script>
```
这个`js`没有详细去看, 因为压缩混淆过了。
但是我知道的是, 它拦截了异常报错信息, 导致控制台无法正常提示错误, 拖住我好久(生气
```js
window.onerror = function(url, error, line, column) {
    _$xerrorcode = "msg[" + url + "]#line[" + line + "]#column[" + column + "]";
    return true;
  };
```
所以我在第一行加上了`window.onerror = undefined;`(或者`null`)。
因为我在浏览器控制台输入`window.onerror`, 返回的是`null`。