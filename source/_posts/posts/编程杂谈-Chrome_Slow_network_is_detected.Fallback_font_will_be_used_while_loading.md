---
title: Chrome Slow network is detected.Fallback font will be used while loading
url: Chrome_Slow_network_is_detected.Fallback_font_will_be_used_while_loading
date: 2017-11-12 00:39:04
tags:
  - Chrome
categories:
  - 编程杂谈
---


# 前言
升级`Chrome`后, 在`F12控制台`调试的时候, 经常会出现一堆代码。看起来也不是错误。
```
Slow network is detected. Fallback font will be used while loading: http://xxxxxxxx.woff
```

<!-- more -->

# 意义
从字面意思上理解。
```
检测到缓慢的网络请求。当加载http://xxxxxxx.woff时，回调字体将会被使用。
```
就是当网络字体没加载完毕的时候, 页面会出现空白界面, 这对用户体验很不友好。Chrome正在用本地字体替换网页字体(使用`Css`的`@ font-face`规则加载）。

这是一个叫做[@font-face](https://developer.mozilla.org/zh-CN/docs/Web/CSS/@font-face)的[CSS](https://developer.mozilla.org/zh-CN/docs/CSS "CSS")  [@规则](https://developer.mozilla.org/zh-CN/docs/CSS/At-rule "At-rule"), 它允许网页开发者为其网页指定在线字体, 避免对本地字库的依赖。

简单的说, 这是一个Chrome的`bug`, 只要加载网络字体, 就会提示这个信息。
但是这个信息对**Web调试**来说是噪音信息, 无用的信息。

# 解决方案
关闭这个提示。眼不见心不烦。
在地址栏输入`chrome://flags/#enable-webfonts-intervention-v2`, 选择**Disable**即可。
目前版本 61.0.3163.100, 尚未修复这个bug。

# 参考资料
- [why-does-this-slow-network-detected-log-appear-in-chrome](https://stackoverflow.com/questions/40143098)