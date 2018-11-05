---
title: Hexo多图并排显示
url: Hexo_multiple_images_side_by_side
date: 2017-11-05 12:47:32
tags: 
  - Hexo
categories:
  - Hexo
---

# 前言
Hexo有时候需要进行多图并排显示对比。
fancybox默认一张图占据一行。需要自己修改Css样式。
~~本文默认使用[七牛云插件](https://github.com/gyk001/hexo-qiniu-sync)。~~
测试域名被收回了, 再次感受到国内开发者巨大的政策风险。

<!-- more -->

<style type="text/css">
    .fancybox {
        display: inline-block;
    }
</style>

# 插入Css样式
在`<!-- more -->`之后插入样式, 避免将样式写入`description`。
注意, 因为渲染问题, 请尽量使用回车隔离以下代码块。
```html

<style type="text/css">
    .fancybox {
        display: inline-block;
    }
</style>

{% img /images/最短路径_01.png 200 %}
{% img /images/最短路径_02.png 200 %}
```

{% img /images/最短路径_01.png 200 %}
{% img /images/最短路径_02.png 200 %}