---
title: Java常量字符串过长
url: constant_string_is_too_long
tags:
  - IDEA
categories:
  - Java SE
date: 2017-12-06 20:17:24
---

# 前言
在使用 ` fastjson ` 从 ` url ` 下载 ` json ` 解析时候, 出现了语法错误。
要排错, 于是将一堆 ` json ` 数据复制到 ` String `。
结果报编译异常**常量字符串过长**。

<!-- more -->

# 解决方案
使用 ` Eclipse编译器 ` 解决问题。
` IDEA 2017.1.5 ` 的操作流程: 
File -> Settings -> Build,Execution,Deployment -> Compiler -> Java Compiler
点击 ` Use Compiler `, 选择 ` Eclipse `, 点击确定保存即可。
