---
title: Android沉浸式状态栏
url: Android_Using_Immersive_Full-Screen_Mode
tags:
  - Toolbar
categories:
  - Android
date: 2016-09-08 21:34:58
---
# 前言
沉浸式状态栏的实现方式在以前是五花八门。
在这里主要是给出一个我觉得比较完美的实现沉浸式状态栏的方案（兼容最低android4.4）。
<!-- more -->

# 效果图
android 5.0 以上
{% img /images/Android沉浸式状态栏_01.gif %}

android 4.4 API 19
{% img /images/Android沉浸式状态栏_02.gif %}

以上都是原生安卓系统的效果，具体到国内的各种各样改过的系统可能会有细微差别，我测试小米和华为的机器效果基本一样。

# 实现
## 修改主题属性
在values-v19之后的主题属性中添加一条即可,如下
```xml
<item name="android:windowTranslucentStatus">true</item>
```
## 设置fitsSystemWindows属性
如果你想让一个View的图像显示在状态栏下，那么就在View的XML布局文件中添加如下属性
```xml
android:fitsSystemWindows="true"
```
例子：
这里我设置了ToolBar
```xml
<?xml version="1.0" encoding="utf-8"?>
<android.support.design.widget.CoordinatorLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context="com.mjj.statusbar.MainActivity">
    <android.support.design.widget.AppBarLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:theme="@style/AppTheme.AppBarOverlay">
        <android.support.v7.widget.Toolbar
            android:id="@+id/toolbar"
            android:layout_width="match_parent"
            android:layout_height="?attr/actionBarSize"
            android:background="?attr/colorPrimary"
            android:fitsSystemWindows="true"
            app:popupTheme="@style/AppTheme.PopupOverlay" />
    </android.support.design.widget.AppBarLayout>
</android.support.design.widget.CoordinatorLayout>
```
注意：如果你在同一个布局中添加了多个这个属性，那么一般只有最外层View的这个属性生效

## 调整View高度
上面两步都是统一的，这一步就比较有针对性了，对不同布局和API版本都会有所微调，主要是顶部View的高度。
如果你像我一样基本使用原生控件，那么一般情况下是调整ToolBar(ActionBar)的高度。你需要给Toolbar加上系统状态栏的高度，因为如果你设置了前面两步，那么ToolBar会上移到状态栏下面,如图
{% img /images/Android沉浸式状态栏_03.png %}


我比较喜欢的处理方式是在java代码中改变高度,注意需要判断安卓版本，样例如下：
（具体获取状态栏高度的代码可以到后面的参考资料中看，也可以在我的Demo中看源码）
```java
mToolbar = (Toolbar) findViewById(R.id.toolbar);
        
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
{
    mToolbar.getLayoutParams().height = getAppBarHeight();
    mToolbar.setPadding(mToolbar.getPaddingLeft(),
            getStatusBarHeight(),
            mToolbar.getPaddingRight(),
            mToolbar.getPaddingBottom());
}
setSupportActionBar(mToolbar);
```

当然了，也有一些同学喜欢在XML中定义，那么就需要写一些分离区分版本的XML文件。目前的话安卓手机端除6.0的系统状态栏是24dp,其它都是25dp。

# 参考资料
- [API 19 设置状态栏](http://blog.mosil.biz/2014/01/android-transparent-kitkat/)
- [获取状态栏的高度](http://stackoverflow.com/questions/3407256/height-of-status-bar-in-android)
