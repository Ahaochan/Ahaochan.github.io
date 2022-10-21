---
title: Ajax提交之快速获取表单值
url: get_form_values_when_use_AJAX_submit
tags:
  - Ajax
categories:
  - JavaScript
date: 2018-05-28 16:16:00
---

# 前言
表单请求经常需要进行表单验证, 然后再进行请求, 再对页面进行后处理, 比如弹出个对话框提示请求成功。
普通的`form`提交是不能满足需求的, 要通过`AJAX`来处理。

<!-- more -->

# 使用jQuery的submit函数
`jQuery`提供了`submit`函数, 来接管提交事件, 

```js
$('#form-userInfo').submit(function (event) {
    // 1. 拦截默认的提交方式
    event.preventDefault();

    // 2. 获取表单值
    var username = $('input[name="username"]').val();
    
    // 3. ajax请求
    $.ajax({
        url: '/login', // url where to submit the request
        type : 'POST', // type of action POST || GET
        dataType : 'json', // data type
        data : { username: username }, // post data || get data
        success : function(result) {
            // 3.1. 请求成功
            console.log(result);
        },
        error: function(xhr, resp, text) {
            // 3.2. 请求失败
            console.log(xhr, resp, text);
        }
    })
});
```

# serializeArray 序列化参数
获取参数的方式有很多种, 上面使用的是最简单的方法, 通过获取元素来获取值。
但是如果有很多个参数, 比如用户名、密码、性别、城市、手机号、身份证号等等。
每个都要去手动获取元素再来获取值, 就太麻烦了。

`jQuery`提供了`serialize`和`serializeArray`两个方法去序列化参数, 关于这两个方法的不同, 可以查阅参考资料和`jQuery`文档。
这里使用`serializeArray`, 主要是第二步获取参数的方式不同。

```js
$('#form-userInfo').submit(function (event) {
    // 1. 拦截默认的提交方式
    event.preventDefault();

    // 2. 获取表单值, 看这里!!!!
    var data = {};
    $(this).serializeArray().map(function(x){data[x.name] = x.value;});
    console.log(data);
    
    // 3. ajax请求
    $.ajax({
        url: '/login', // url where to submit the request
        type : 'POST', // type of action POST || GET
        dataType : 'json', // data type
        data : { username: username }, // post data || get data
        success : function(result) {
            // 3.1. 请求成功
            console.log(result);
        },
        error: function(xhr, resp, text) {
            // 3.2. 请求失败
            console.log(xhr, resp, text);
        }
    })
});
```

# 参考资料
- [Convert form data to JavaScript object with jQuery](https://stackoverflow.com/a/17784656/6335926)
- [What's the difference between .serialize() and .serializeArray()?](https://stackoverflow.com/questions/10430502)