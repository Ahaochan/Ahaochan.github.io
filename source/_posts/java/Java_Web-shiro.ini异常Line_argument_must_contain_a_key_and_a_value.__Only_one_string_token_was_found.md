---
title: shiro.ini异常Line argument must contain a key and a value.  Only one string token was found.
url: Line_argument_must_contain_a_key_and_a_value._Only_one_string_token_was_found.
tags:
  - Shiro
categories:
  - Java Web
date: 2017-09-07 23:56:53
---
# 前言
在读取[shiro.ini](https://shiro.apache.org/)的时候, 抛出了如下异常
```ini
[users]
user1=password1
user2=password2
;抛出Line argument must contain a key and a value.  Only one string token was found.
```
不科学啊, 我这里都是有键值对的。怎么会说我没有完整的键值对呢?
<!-- more -->

# 解决方案
在[这篇博客](http://learningtogrowup.iteye.com/blog/2232917)找到了解决方案。
原来我的 ` shiro.ini ` 是 ` UTF-8 ` 编码的, windows会自动给 ` UTF-8 ` 编码加上 ` BOM ` 。
所以使用windows默认笔记本编辑的小伙伴就有福啦~, 被坑了。
用 ` Notepad++ ` 打开, 点击 ` 编码->转为UTF-8无BOM编码格式 ` 即可。

# 为什么改成 无BOM编码 就可以呢?
以下是引用或整合的一些信息。
- ANSI:
  1. ANSI编码表示英文字符时用一个字节，表示中文用两个或四个字节。
  2. ANSI有很多个分支, 比较熟悉的有GB2312、GBK、GB18030、Big5, 这些使用多个字节表示一个字符的编码方式称为ANSI编码。
  3. 简体中文Windows是GBK编码。
   
- UTF-8 无BOM 和 UTF-8
  1. 这里的BOM不是javascript的Browser Object Model浏览器对象模型。而是Byte Order Mark字节顺序标记
  2. BOM会在文件的开头加入U+FEFF, 相当于一个【看不见的长度为0的空白字符】, 用于区分UTF-8和ASCII编码
  3. windows会自动给UTF-8编码加上BOM。
  4. UTF-8本身是没有字节序的问题的（因为它是以单个字节为最小单位）
  
# 参考资料
- [java.lang.IllegalArgumentException: Line argument must contain a key and a value](http://learningtogrowup.iteye.com/blog/2232917)
- [百度百科-ANSI](https://baike.baidu.com/item/ANSI)
- [维基百科-字节顺序标记](https://zh.wikipedia.org/wiki/字节顺序标记)
- [「带 BOM 的 UTF-8」和「无 BOM 的 UTF-8」有什么区别？网页代码一般使用哪个？](https://www.zhihu.com/question/20167122)
- [编码歪传——番外篇](http://jimliu.net/2015/03/07/something-about-encoding-extra/)
