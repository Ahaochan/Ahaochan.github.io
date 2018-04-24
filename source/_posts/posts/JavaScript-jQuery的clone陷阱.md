---
title: jQuery的clone陷阱
url: Cloning_trap_of_jQuery
tags:
  - jQuery
categories:
  - JavaScript
date: 2018-03-19 21:48:46
---
# 前言
`clone()` 方法生成被选元素的副本，包含子节点、文本和属性。
这里的属性, 包括了 `id`。当`clone`了`id`后, 获取`id`将会获取第一个匹配`id`的元素。造成不可预期的后果。
<!-- more -->

# 例子
[Demo地址](https://jsfiddle.net/ju8npczb/8/)
```html
<div>
  <button id="btn">复制时间到第一个div中</button>
  <div class="div-clone">
  
  </div>
  <hr/>
  <div class="div-source">
     <p id="time"></p>  
  </div>
</div>
<script src="https://cdn.bootcss.com/jquery/3.3.1/jquery.min.js"></script>
<script>
$('#btn').click(function(){
  // 1. 更新 div-source 中的时间
  var $time = $('#time');
  $time.html('时间:'+new Date());
  
  // 2. clone 到 div-clone 中
  var $clone = $time.clone();
  $('.div-clone').html($clone);
});
</script>
```
# 分析
这是一个简单的页面, 每点击一次**按钮**, 就会更新`div-source`的时间, 再复制到`div-clone`中。
当第一次点击时, 页面如下, `div-clone`复制成功。
1. 更新`id`为`time`的元素文本为 **现在的时间**
2. 复制`id`为`time`的元素文本
3. 粘贴到`div-clone`里面
```html
<div>
  <button id="btn">复制时间到第一个div中</button>
  <div class="div-clone">
     <p id="time">时间:Wed Mar 14 2018 14:53:15 GMT+0800 (中国标准时间)</p>
  </div>
  <hr>
  <div class="div-source">
     <p id="time">时间:Wed Mar 14 2018 14:53:15 GMT+0800 (中国标准时间)</p>  
  </div>
</div>
```
问题出在第二次点击时, 只会更新第一个`div`, 不更新第二个`div`
1. 更新`div-clone`下的`id`为`time`的元素文本为 **现在的时间**, 因为现在`id`为`time`的元素有两个。会更新第一个元素，也就是`div-clone`下的`id`为`time`的元素
2. 复制`div-clone`下的`id`为`time`的元素文本
3. 粘贴到`div-clone`里面
4. `div-source`没被操作
```html
<div>
  <button id="btn">复制时间到第一个div中</button>
  <div class="div-clone">
     // 注意这里!!!有两个id为time的元素
     <p id="time">时间:Wed Mar 14 2018 15:01:05 GMT+0800 (中国标准时间)</p>
  </div>
  <hr>
  <div class="div-source"> 
     // 注意这里!!!有两个id为time的元素
     <p id="time">时间:Wed Mar 14 2018 14:53:15 GMT+0800 (中国标准时间)</p>  
  </div>
</div>
<script src="https://cdn.bootcss.com/jquery/3.3.1/jquery.min.js"></script>
<script>
$('#btn').click(function(){
  // 第二次点击, 预期是更新 div-source 的时间, 实际会更新 div-clone 中的时间
  var $time = $('#time');
  $time.html('时间:'+new Date());
  
  var $clone = $time.clone();
  $('.div-clone').html($clone);
});
</script>
```

# 总结
`clone`最好不要复制带有`id`属性的元素, 否则会发生不可预期的错误。

# 参考资料
- [jQuery 文档操作 - clone() 方法](http://www.w3school.com.cn/jquery/manipulation_clone.asp)