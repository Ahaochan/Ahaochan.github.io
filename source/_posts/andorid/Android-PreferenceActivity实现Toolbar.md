---
title: PreferenceActivity实现Toolbar
url: How_to_set_Toolbar_with_PreferenceActivity
tags:
  - Activity
  - Fragment
categories:
  - Android
date: 2016-08-04 22:38:56
---
# 前言
尝试使用`PreferenceActivity`时，发现从有`Toolbar`的上一个`Activity`进入了没有`Toolbar`的`Activity`，感觉太丑了。但是`google`居然没有推出`AppCompatPreferenceActivity`，没办法只好自己写。
<!-- more -->

# PreferenceActivity+ToolBar(限Android 5.0以上)
**思路**
模仿`AppCompatActivity`，对`PreferenceActivity`进行改造

**实现**
继承PreferenceActivity重写onCreate方法添加如下代码:
```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    getDelegate().installViewFactory();
    getDelegate().onCreate(savedInstanceState);
    super.onCreate(savedInstanceState);
    /** 初始化StatusBar,交由子类实现 */
    setStatusBar();
    /** 获取DecorView下的ContentView*/
    ViewGroup contentViews = (ViewGroup) findViewById(android.R.id.content);
    /** 获取ContentView的子View */
    View content = contentView.getChildAt(0);
    /** 加载自定义布局文件,获取id交由子类实现 */
    LinearLayout toolbarLayout = (LinearLayout) LayoutInflater.from(this).inflate(getActLayoutId(), null);
    /** 移除根布局所有子view */
    contentView.removeAllViews();

    /** 注意这里一要将前面移除的子View添加到我们自定义布局文件中，否则PreferenceActivity中的Header将不会显示 */
    toolbarLayout.addView(content);
    /** 将包含Toolbar的自定义布局添加到根布局中 */
    contentView.addView(toolbarLayout);

    /** 设置Toolbar,获取Toolbar的Id的方法交由子类实现 */
    mToolbar = (Toolbar) toolbarLayout.findViewById(getActToolbarId());
    /** 初始化Toolbar,交由子类实现 */
    initToolbar(getToolbar());  }
```

# AppCompatActivity+PreferenceFragment+ToolBar(适用于Android 5.0以下)
## 思路
在`Activity`中设置`Toolbar`，使用事务替换`Fragment`的方法。

## 实现
和普通的使用`Fragment`方法一样，这里不赘述。

