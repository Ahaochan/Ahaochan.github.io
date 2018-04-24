---
title: View的onMeasure()
url: onMeasure_method_of_View
tags:
  - 自定义View
categories:
  - Android
date: 2016-06-23 09:28:19
---

# 自定义View首先需要测量View的大小
自定义`View`首先需要测量`View`的大小，在`View`的`onMeasure()`方法中进行。
`View`的大小分为三种类型，测量模式也有三种
- 自适应(`wrap_content`)，对应`at_most`(最大值模式)，代表的是最大可获得的空间
- 固定(100dp)，对应`Exactly`(精确值模式)，代表的是精确的尺寸； 
- 填充父`View`(`match_parent`)，对应`Exactly`(精确值模式)，代表的是精确的尺寸； 
- 还有个`UnSpecified`(未指定模式)，不指定`View`的大小，想多大就多大，用于`scrollView`等类。

<!-- more -->


# 默认情况
`onMeasure()`只支持`Exactly`模式，所以要重写`onMeasure`方法.
`onMeasure`传入的`widthMeasureSpec`和`heightMeasureSpec`不是一般的尺寸数值，而是将模式和尺寸组合在一起的数值。
`MeasureSpec`是一个32位的`int`值，高2位为测量模式，低30位为测量的大小。
查看`View`的`onMeasure()`源码发现，调用了`setMeasuredDimension(int measuredWidth, int measuredHeight)`方法。
那么我们只要将设置好的长宽参数穿进去即可。
```java
@Override
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
//    super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    Log.i("onMeasure","onMeasure");
    setMeasuredDimension(measureWidth(widthMeasureSpec),
                         measureHeight(heightMeasureSpec));
//    measureWidth()和measureHeight()源码基本一致
}
private int measureWidth(int measureSpec) {
    int result;
    int specMode = MeasureSpec.getMode(measureSpec);//获取测量模式
    int specSize = MeasureSpec.getSize(measureSpec);//获取Size
//    Log.i("measureWidth","measureSpec:"+measureSpec);
    Log.i("measureWidth","specSize:"+specSize);
    if(specMode == MeasureSpec.EXACTLY){
        Log.i("measureWidth","specMode:"+"MeasureSpec.EXACTLY");
        result = specSize;//如果是Exactly模式,则直接设置
    } else {
        result = 200;//如果不是Exactly模式,设置最小的Size
        if(specMode == MeasureSpec.AT_MOST){
            Log.i("measureWidth","specMode:"+"MeasureSpec.AT_MOST");
            result = Math.min(result, specSize);
            //这里需要自定义,对子`View`的Size进行测量
        } else if(specMode == MeasureSpec.UNSPECIFIED){
            Log.i("measureWidth","specMode:"+"MeasureSpec.UNSPECIFIED");
        }
    }
    return result;
}
```

# onMeasure()触发了两次？
打印log时出现这个问题，待解决
