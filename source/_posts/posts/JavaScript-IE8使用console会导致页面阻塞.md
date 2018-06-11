---
title: IE8使用console会导致页面阻塞
url: IE8_use_the_console_object_will_cause_the_page_to_be_blocked
tags:
  - IE8
categories:
  - JavaScript
date: 2018-06-11 17:37:00
---

# 前言
在`JS`里经常会使用`console.log()`来调试程序(**这是不对的**), 结果在`IE8`里面发现`AJAX`执行不了, 一开始以为是`IE8`不支持`JSONP`, 后来才知道原来是`console`的锅。

<!-- more -->

# 原因
`console`对象调用`log()`方法打印日志, 这个操作在`IE8`的正式环境是行不通的。
因为在`IE8`中, `console`对象只有在`Dev Toolbar `开发者工具打开的时候才会创建, 如果在正式环境下, `console`对象没有创建, 而`JS`代码去调用了`console.log()`就会抛出找不到`console`对象的错误, 导致后续的代码无法执行。

# 解决方案
最好的解决方案就是不使用`console.log()`调试, 使用浏览器`Dev Toolbar `开发者工具提供的断点进行`debug`。

**但是**
代码开发人员的素质水平参差不齐, 所以还是要兼容`console`。
```js
// 避免出现console错误
(function() {
    var methods = [
        'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
        'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
        'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
        'timeStamp', 'trace', 'warn'
    ];
    var length = methods.length;
    var console = (window.console = window.console || {});

    while (length--) {
        var method = methods[length];

        // method不存在则设置默认方法
        if (!console[method]) {
            console[method] = function () { alert('not support!') };
        }
    }
}());
```

# 参考资料
- [why-does-javascript-only-work-after-opening-developer-tools-in-ie-once](https://stackoverflow.com/a/12315859/6335926)
- [what-happened-to-console-log-in-ie8](https://stackoverflow.com/questions/690251)