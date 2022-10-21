---
title: 如何优雅的使用GitHub的js脚本
url: The_Best_Practices_for_Using_GitHub's_JavaScript
tags:
  - JavaScript
  - GitHub
categories:
  - 编程杂谈
date: 2018-02-03 14:27:28
---
# 前言
`GitHub`上有很多优秀的开源脚本, 但是不能直接使用, 需要下载下来保存在自己的项目中。
如果是使用[JSFiddle](https://jsfiddle.net/)进行演示的话, 只能通过`url`引用(当然如果你不嫌累长篇大段的CV大法另当别论)。
即使是直接引用`raw`也会抛出异常, `GitHub`的`raw`文件的`MIME type(Internet media type)`为`text/plain`。而`<script>`要求为`application/javascript`。
```
Refused to execute script from 'http://raw.githubusercontent.com/user/repo/branch/file.js' because its MIME type ('text/plain') is not executable, and strict MIME type checking is enabled.
```

<!-- more -->

# 解决方案
其实`GitHub`自己就提供了解决方案。
只要将`raw.githubusercontent.com`替换为`rawgit.com`(非生产环境)或`cdn.rawgit.com`即可。
项目生产环境最好使用`cdn`。

比如`http://raw.githubusercontent.com/user/repo/branch/file.js`替换为`http://cdn.rawgit.com/user/repo/tag/file.js`

# 参考资料
- [Link and execute external JavaScript file hosted on GitHub](https://stackoverflow.com/questions/17341122/link-and-execute-external-javascript-file-hosted-on-github)

