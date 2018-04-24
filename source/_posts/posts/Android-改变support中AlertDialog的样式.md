---
title: 改变support中AlertDialog的样式
url: change_the_style_of_AlertDialog
tags:
  - AlertDialog
categories:
  - Android
date: 2016-08-24 21:56:06
---

# 前言
> 原文:http://blog.isming.me/2015/08/31/modify-alert-style/

`android`最近的`support`库提供了`AlertDialog`，可以让我们在低于`5.0`的系统使用到跟`5.0`系统一样的`Material Design`风格的对话框。
<!-- more -->
{% qnimg 改变support中AlertDialog的样式_01.jpg %}


# 步骤
## 自定义一个Style
在`values/styles.xml`中创建一个`Style`
```xml
<style name="MyAlertDialogStyle" parent="Theme.AppCompat.Light.Dialog.Alert">
    <!-- Used for the buttons -->
    <item name="colorAccent">#FFC107</item>
    <!-- Used for the title and text -->
    <item name="android:textColorPrimary">#FFFFFF</item>
    <!-- Used for the background -->
    <item name="android:background">#4CAF50</item>
</style>
```

## 在创建对话框时使用
```java
AlertDialog.Builder builder = new AlertDialog.Builder(this, R.style.MyAlertDialogStyle);
builder.setTitle("AppCompatDialog");
builder.setMessage("Lorem ipsum dolor...");
builder.setPositiveButton("OK", null);
builder.setNegativeButton("Cancel", null);
builder.show();
```

## 全局使用style（可选）
这样的方法是每个地方使用的时候，都要在构造函数传我们的这个`Dialog`的`Theme`，我们也可以全局的定义对话框的样式。
```xml
<style name="MyTheme" parent="Base.Theme.AppCompat.Light">
    <item name="alertDialogTheme">@style/MyAlertDialogStyle</item>
    <item name="colorAccent">@color/accent</item>
</style>
```

在我们的`AndroidManifest.xml`文件中声明`application`或者`activity`的时候设置`theme`为`MyTheme`即可.
不过需要注意的一点是，我们的`Activity`需要继承自`AppCompatActivity`。
