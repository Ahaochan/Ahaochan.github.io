---
title: 使用JavaScript判断浏览器类型
url: Use_JavaScript_to_determine_browser_type
tags:
  - JavaScript
categories:
  - JavaScript
date: 2018-02-03 14:23:08
---
# 前言
使用`User-Agent`判断浏览器是不可靠的。因为使用控制台可以随意的伪装`User-Agent`。
<!-- more -->

# 代码
使用各浏览器特有的**属性**进行检测
```js
// Opera 8.0+
var isOpera = (!!window.opr && !!opr.addons) || !!window.opera || navigator.userAgent.indexOf(' OPR/') >= 0;

// Firefox 1.0+
var isFirefox = typeof InstallTrigger !== 'undefined';

// Safari 3.0+ "[object HTMLElementConstructor]" 
var isSafari = /constructor/i.test(window.HTMLElement) || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || (typeof safari !== 'undefined' && safari.pushNotification));

// Internet Explorer 6-11
var isIE = /*@cc_on!@*/false || !!document.documentMode;

// Edge 20+
var isEdge = !isIE && !!window.StyleMedia;

// Chrome 1+
var isChrome = !!window.chrome && !!window.chrome.webstore;

// Blink engine detection
var isBlink = (isChrome || isOpera) && !!window.CSS;
```

# 参考资料
- [User-Agent MDN](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/User-Agent)
- [List of User Agent Strings](http://www.useragentstring.com/pages/useragentstring.php)
- [How to detect Safari, Chrome, IE, Firefox and Opera browser?](https://stackoverflow.com/questions/9847580/how-to-detect-safari-chrome-ie-firefox-and-opera-browser)
