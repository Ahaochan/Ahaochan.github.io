---
title: Canvas中rotate,translate,save和restore
url: rotate,translate,save_and_restore_of_Canvas
tags:
  - 自定义View
categories:
  - Android
date: 2016-06-21 09:34:13
---
# rotate()
rotate()是对坐标系的旋转，而不是对屏幕的旋转。
<!-- more -->
```java
@Override
protected void onDraw(Canvas canvas) {
    canvas.drawRect(100, 100, 150, 150, mPrePaint);//画出蓝色矩形
    canvas.rotate(30);//顺时针旋转30度
    canvas.drawRect(200, 200, 250, 250, mLastPaint);//画出黄色矩形
    super.onDraw(canvas);//画出文字
}
```
效果如下：
{% asset_img Canvas中rotate,translate,save和restore_01.png %}

很明显，在坐标系旋转前，画出的蓝色矩形并没有跟着坐标系的旋转而旋转，
而在坐标系旋转后，画出的黄色矩形和文字旋转了30度。
`rotate()`有两个重载方法：
- rotate(float degrees);
- rotate(float degrees, float px, float py);
明显第一个参数`degrees`是坐标系旋转的角度，正数为顺时针旋转，负数为逆时针旋转。
`px`和`py`表示的是，以`(px,py)`为旋转中心，进行`degrees`度的旋转。
如果使用第一个重载方法，则旋转中心`(px,py)`为`(0,0)`。


# translate()
`translate()`是对坐标系的平移。
```java
@Override
protected void onDraw(Canvas canvas) {
    canvas.drawRect(100, 100, 150, 150, mPrePaint);//画出蓝色矩形
    canvas.rotate(30);//顺时针旋转30°
    super.onDraw(canvas);//画出文字
    canvas.drawRect(200, 200, 250, 250, mLastPaint);//画出黄色矩形
    canvas.translate(500, 0);//往x轴正方向平移500单位长度
    super.onDraw(canvas);//画出文字
    canvas.drawRect(200, 200, 250, 250, mLastPaint);//画出黄色矩形
}
```
效果如下：
{% asset_img Canvas中rotate,translate,save和restore_02.jpg %}

 
从上述例子可以看出，`canvas`绘图，实际上是以坐标系为基准进行绘图的。
所有的图形都是由在坐标系原点的基础上进行计算并绘制。

那么，如果我们进行了很多次`rotate()`和`translate()`操作后，想回退到某一次操作后的坐标轴位置，应该怎么做呢？

`Canvas`中有两个方法`save()`和`restore()`，一个是存储，一个是回退。
## save()
无
## restore()
无
