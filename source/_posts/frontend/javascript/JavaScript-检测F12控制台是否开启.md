---
title: 检测F12控制台是否开启
url: Check_whether_the_F12_console_is_turned_on
tags:
  - JavaScript
categories:
  - JavaScript
date: 2018-02-03 14:25:56
---
# 前言
吧友提到了拦截控制台的情况。[别人页面中有个js文件,无法调试.有啥办法解除这个限制.](http://tieba.baidu.com/p/5507907516) 
于是好奇找了下`stackoverflow`, [Find out whether Chrome console is open](https://stackoverflow.com/questions/7798748/find-out-whether-chrome-console-is-open), 但是代码不太懂。
后来dalao告诉我知乎有篇文章: [前端开发中如何在JS文件中检测用户浏览器是否打开了调试面板（F12打开开发者工具）？]( https://www.zhihu.com/question/24188524)

<!-- more -->

# Chrome 适用(截止至63.0.3239.108)

在控制台打开的时候, 打印`html`元素会去取`id`属性的值, 只要覆盖`id`属性的`get`方法, 就可以判断是否开启控制台。

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
</head>
<body>
status: <div id="devtool-status"></div>
</body>
<script src="https://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<script>
var checkStatus;

// 1. 创建一个html元素, 不能使用普通Object, 两者日志处理方式不同
var element = new Image();
//var element = document.createElement('any');
// 2. 重新定义该元素的get方法
Object.defineProperty(element, 'id', {
  get:function() {
    checkStatus='on';
  }
});

// 3. 定时检测控制台是否打开
setInterval(function() {
    checkStatus = 'off';
    // 3.1 不使用log, 使用debug, 避免污染控制台
    console.debug(element);
    document.querySelector('#devtool-status').innerHTML = checkStatus;
}, 1000)
</script>
</html>
```

# Firefox 适用(截止至57.0.4)
打印普通对象的日志会调用该对象的`toString`方法。
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
</head>
<body>
status: <div id="devtool-status"></div>
</body>
<script src="https://cdn.bootcss.com/jquery/3.2.1/jquery.min.js"></script>
<script>
var checkStatus;

var devtools = /./;
devtools.toString = function() {
  checkStatus = 'on';
}

setInterval(function() {
    checkStatus = 'off';
    console.log(devtools);
    document.querySelector('#devtool-status').innerHTML = checkStatus;
}, 1000)
</script>
</html>
```

# 参考资料
- [Find out whether Chrome console is open](https://stackoverflow.com/questions/7798748/find-out-whether-chrome-console-is-open)
- [突破前端反调试--阻止页面不断debugger](https://segmentfault.com/a/1190000012359015)
- [前端开发中如何在JS文件中检测用户浏览器是否打开了调试面板（F12打开开发者工具）？](https://www.zhihu.com/question/24188524)
