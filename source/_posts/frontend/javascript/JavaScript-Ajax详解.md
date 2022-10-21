---
title: Ajax详解
url: Ajax_simple_use
tags:
  - Ajax
categories:
  - JavaScript
date: 2017-03-14 10:14:09
---


# 前言
`AJAX`即`Asynchronous Javascript And XML（异步JavaScript和XML）`，是指一种创建交互式网页应用的网页开发技术。
`AJAX` = 异步 `JavaScript`和`XML`（标准通用标记语言的子集）。
`AJAX` 是一种用于创建快速动态网页的技术。
通过在后台与服务器进行少量数据交换，`AJAX` 可以使网页实现异步更新。这意味着可以在不重新加载整个网页的情况下，对网页的某部分进行更新。
传统的网页（不使用 `AJAX`）如果需要更新内容，必须重载整个网页页面。

<!-- more -->

# 获取XMLHttpRequest对象
```js
function getXMLHttpRequest(){
    var xhr;
    try{    
        xhr = new XMLHttpRequest();//firfox, Opera 8.0+, Safari
    } catch(e) {
        try{
            xhr = new ActiveXObject('Msxml2.XMLHTTP');
        } catch(e){
            try{
                xhr = new ActiveXObject('Microsoft.XMLHTTP');
            } catch(e){}
        }
    }
    return xhr;
}
```

# 发送数据
```js
var xhr = getXMLHttpRequest();
xhr.open('post', 'http://localhost:8080/test', true);//true是异步提交
xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');//post提交表单必须
xhr.send('username=张三&sex=男');
```

# 接收数据
```js
xhr.onreadystatechange = function(){
    if(xhr.readyState===4 && request.status===200){
        document.getElementById('id').innerHTML = xhr.responseText;
    }
}
```

# jQuery实现AJAX
```js
$(document).ready(function(){
    $('#id').click(function(){
        $.ajax({
            type: 'POST',
            contentType : 'application/json',
            async: true,
            timeout : 100000, 
            url: 'http://localhost:8080/test',
            dataType: 'json',
            data:{
                name:'张三',
                sex:'男'
            },
            beforeSend: function () {
                alert('加载中');
            },
            success: function (data) {
                var json = eval(data);
                alert(json);
            },
            error: function (xhr) {
               alert('失败'+xhr.status);//传入XMLHttpRequest对象
            },
            done : function(e) {
                console.log('DONE');
            }
        });
   });
});
```
