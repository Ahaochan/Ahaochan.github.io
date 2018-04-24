---
title: ListActivity源码详解
url: ListActivity_source_code
date: 2016-09-26 16:39:34
tags: 
  - Android源码
categories : 
  - Android
---

# 前言
最近在研究`PreferenceActivity`发现是继承自ListActivity的，打开看了下`ListActivity`的源码，发现也不长，就详细阅读认识一下。
<!-- more -->

# 正文
`ListActivity`简单到只要在`onCreate()`中调用`setListAdapter()`方法就可以实现了。
支持空数据显示。

点进去我们看到前两个`field`很熟悉，就是一个`ListView`+`Adapter`。
很容易就知道这两个`field`就是`ListActivity`的核心，数据存储在`Adapter`中，展示在`ListView`中。
```java
protected ListAdapter mAdapter;
protected ListView mList;
/** 省略部分代码 */
public void setListAdapter(ListAdapter adapter) {
    //加上锁，防止多个线程同时调用这个方法
    synchronized (this) {
        ensureList();//内含setContentView的方法
        mAdapter = adapter;
        mList.setAdapter(adapter);
    }
}
```
在调用了`setListAdapter()`之后，对`Adapter`重新赋值，并重新设置`ListView`的`Adapter`，并且调用了`ensureList()`方法，重新创建布局。
点进`ensureList()`方法。
```java
private void ensureList() {
    if (mList != null) {
        return;
    }
    setContentView(com.android.internal.R.layout.list_content_simple);
}
```
哈！原来每次`setListAdapter()`都会把`Adapter`替换掉，并且重新`setContentView()`，怪不得`ListActivity`不用我们操心布局。
我们再来看看这个布局的内容
```xml
<ListView xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@android:id/list"
    android:layout_width="match_parent" 
    android:layout_height="match_parent"
    android:drawSelectorOnTop="false"
    />
```
也就是说，你可以自己`setContentView()`，只要你的布局有一个`viewId`是`android:id="@android:id/list"`的就行。
看到这你可能会无语，就一个简单的`ListView`就完事了？这么简单我也会啊！
别急，这只是完成了基本的功能而已，还要开放一些接口给子`Activity`调用。
有了`ListView`当然要实现各种事件啊。
```java
public void setSelection(int position) {
     mList.setSelection(position);
}
public int getSelectedItemPosition() {
    return mList.getSelectedItemPosition();
}
public long getSelectedItemId() {
    return mList.getSelectedItemId();
}
```
当然还有点击事件，我们发现有一个点击的监听器`mOnClickListener`。
```java
private AdapterView.OnItemClickListener mOnClickListener = new AdapterView.OnItemClickListener() {
    public void onItemClick(AdapterView<?> parent, View v, int position, long id)    {
        onListItemClick((ListView)parent, v, position, id);
    }
};
protected void onListItemClick(ListView l, View v, int position, long id) {
    //空方法，交由子类实现
}
```
既然有监听器，那又是在哪里设置了这个监听器呢？我们发现有一个`onContentChanged()`方法。
```java
public void onContentChanged() {
    super.onContentChanged();  //Activity中是空方法
    View emptyView = findViewById(com.android.internal.R.id.empty); //空数据时显示
    mList = (ListView)findViewById(com.android.internal.R.id.list); //绑定ListView
    if (mList == null) {
        throw new RuntimeException( "Your content must have a ListView whose id attribute is "
                         + "'android.R.id.list'");
    }
    if (emptyView != null) {
        mList.setEmptyView(emptyView);    //多好啊，recyclerView就没有这个方法
    }
    mList.setOnItemClickListener(mOnClickListener); //设置点击事件
    if (mFinishedStart) {
        // 这个if不知道有什么用意
        setListAdapter(mAdapter);
    }
    mHandler.post(mRequestFocus); //待会解释
    mFinishedStart = true;
}
```
可是翻遍源代码也没发现哪里调用了`onContentChanged()`。
从字面上看，`onContentChanged()`是`Content`改变时的回调接口，等等，`Content`？
我们不是在`ensureList()`中调用了`setContentView()`方法吗？
答案是正确的，在调用了`setContentView()`，会调用`onContentChanged()`。
```java
// Activity的setContentView()调用Window(具体子类是PhoneWindow)的setContentView()方法
// 以下代码出现在PhoneWindow中
@Override  
public void setContentView(int layoutResID) {  
    /** 省略部分代码 */
    mLayoutInflater.inflate(layoutResID, mContentParent);  
    getCallback().onContentChanged();  //注意这里!!!
}
```


再解释下，上面的`mHandler.post(mRequestFocus);`
```java
private Runnable mRequestFocus = new Runnable() {
    public void run() {
        // 用来使ListView获取焦点。
        mList.focusableViewAvailable(mList);
    }
};
protected void onDestroy() {
    // Activity销毁时移除
    mHandler.removeCallbacks(mRequestFocus);
    super.onDestroy();
}
```

至此，`ListActivity`已经认识的差不多了。有什么讲错了希望能有大牛来提点一下。
有兴趣的可以自己用`recyclerView`替换`listView`实现一个`RecyclerActivity`.
