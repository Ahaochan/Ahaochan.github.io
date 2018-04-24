---
title: getWidth()、getHeight()方法返回的值为0
url: getWidth()、getHeight()_method_alway_return_zero
tags:
  - 自定义View
categories:
  - Android
date: 2016-06-25 08:56:12
---
# 前言
在自定义`View`的构造方法中使用`getWidth()`和`getHeight()`返回值为0，
因为过早的使用了这些方法，也就是说在这个`view`被加入到`rootview`之前你就调用了这些方法，返回的值自然为0。
<!-- more -->

# 解决方法：
## 自定义View实现OnGlobalLayoutListener接口，并重写onGlobalLayout方法
```java
@Override
protected void onAttachedToWindow() {
    super.onAttachedToWindow();
    getViewTreeObserver().addOnGlobalLayoutListener(this);
    //在自定义View添加到窗体上时,添加onGlobalLayoutListener
}

@Override
protected void onDetachedFromWindow() {
    super.onDetachedFromWindow();
    getViewTreeObserver().removeOnGlobalLayoutListener(this);
    //在自定义View从窗体移除时,移除onGlobalLayoutListener
}

@Override
public void onGlobalLayout() {
    //重写onGlobalLayoutListener中的onGlobalLayout方法
    Log.i(TAG, "onGlobalLayout");
    if(!mCreated){//设置只执行一次
        mCreated = true
    //这里getWidth(),getHeight()不为0
    }
}
```
