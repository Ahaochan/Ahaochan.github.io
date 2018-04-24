---
title: call和apply的区别
url: The_difference_between_call_and_apply
tags:
  - JavaScript
categories:
  - JavaScript
date: 2018-02-03 18:05:47
---

# 两者的异同
` call ` 和 ` apply ` 都是为了改变 ` this ` 而存在的。
两者可以说是完全一致, 唯一的不同就在于接收的参数的**形式**不同。
- call: 接收**多个**参数
- apply: 接收**一个**数组参数

<!-- more -->

```javascript
// 函数功能, 打印 this 和 所有参数
function f(){
    console.log("this:"+this);
    for(var i in arguments){
        console.log("arguments["+i+"]="+arguments[i]);
    }
}

f(1,2,3);
// this:[object Window]
// arguments[0]=1
// arguments[1]=2
// arguments[2]=3

f.call('我是this', 1,2,3); // 接收多个参数
// this:我是this
// arguments[0]=1
// arguments[1]=2
// arguments[2]=3

var arr = [1,2,3];
f.apply('我是this', arr); // 接收一个数组参数
// this:我是this
// arguments[0]=1
// arguments[1]=2
// arguments[2]=3
```
可以粗略的理解为如下Java代码
```java
public void f1(String... strs);
public void f2(String[] strs);
```