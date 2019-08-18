---
title: 使用copy事件添加版权信息
url: Add_copyright_information_using_the_copy_event
tags:
  - JavaScript
categories:
  - JavaScript
date: 2019-08-18 14:41:09
---

#  前言
最近在慕课网遇到个比较降低用户体验的事情。其实在知乎、掘金也有碰到, 以及其他小网站也会碰到。
就是他们会拦截`copy`事件, 然后加上自己的`copyright`。
问题就在于, 我复制代码去执行, 还得手动去删除`copyright`, 太麻烦了。

<!-- more -->

# 添加版权信息
网上搜了下, 果然有代码, 遂复制一份。略微修改, 加了点注释
```js
(function () {
    function addCopyright() {
        var body_element = document.getElementsByTagName('body')[0];

        // 3. 获取 selection https://developer.mozilla.org/zh-CN/docs/Web/API/Selection
        var selection = "";
        if (window.getSelection) { // DOM,FF,Webkit,Chrome,IE10
            selection = window.getSelection();
            // alert("文字复制成功！若有文字残缺请用右键复制\n转载请注明出处：" + document.location.href);
        } else if (document.getSelection) { // IE10
            selection = document.getSelection();
            // alert("文字复制成功！若有文字残缺请用右键复制\n转载请注明出处：" + document.location.href);
        } else if (document.selection) { // IE6+10-
            selection = document.selection.createRange().text;
            // alert("文字复制成功！若有文字残缺请用右键复制\n转载请注明出处：" + document.location.href);
        } else {
            selection = "";
            // alert("浏览器兼容问题导致复制失败！");
        }

        // 4. 自定义版权信息
        var pagelink = "<br /><br /> 转载请注明来源: <a href='" + document.location.href + "'>" + document.location.href + "</a>";

        // 5. 插入版权信息
        var copy_text = selection + pagelink;

        // 6. 新建一个div, 插入 复制内容+版权信息
        var new_div = document.createElement('div');
        new_div.style.left = '-99999px';
        new_div.style.position = 'absolute';
        body_element.appendChild(new_div);
        new_div.innerHTML = copy_text;

        // 7. 选择新div中的内容
        selection.selectAllChildren(new_div);

        // 8. 删除div
        window.setTimeout(function () {
            body_element.removeChild(new_div);
        }, 0);
        
        // 9. 浏览器复制选中的内容
    }

    // 1. 获得所有元素
    var all = document.getElementsByTagName("*");

    // 2. 为所有元素添加copy事件
    for (var i = 0, len = all.length; i < len; i++) {
        var element = all[i];
        element['oncopy'] = addCopyright;
    }
})();
```

# Hack方案
明显这是可以通过[GreaseMonkey](https://greasyfork.org/zh-CN)解决的事情。
思路就是修改`copy`事件为空即可。
```js
(function () {
    // 1. 获得所有元素
    var all = document.getElementsByTagName("*");

    // 2. 为所有元素添加copy事件
    for (var i = 0, len = all.length; i < len; i++) {
        var element = all[i];
        element['oncopy'] = '';
    }
})();
```
写完后才发现早有人实现了。[网页限制解除(改)](https://greasyfork.org/zh-CN/scripts/28497-remove-web-limits-modified)


# 参考资料
- [JavaScript实现文章复制加版权信息](http://wangbaiyuan.cn/javascript-implementation-article-copy-plus-copyright-information.html)