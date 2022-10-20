---
title: Activity、Fragment状态缓存和恢复
url: Save_Restore_Activity’s_and_Fragment’s_state
tags:
  - Activity
  - Fragment
categories:
  - Android
date: 2016-08-07 22:30:23
---
# 资料
> [Activity/Fragment状态缓存和恢复的最佳实践](https://inthecheesefactory.com/blog/fragment-state-saving-best-practices/en)
> [译文](http://www.voidcn.com/blog/lwk520136/article/p-6138230.html)

<!-- more -->

# 总结
## Activity
`Activity`中已经自己实现了。
只要重写`onSaveInstanceState()`和`onRestoreInstanceState()`这两个方法即可
```java
protected void onSaveInstanceState(Bundle outState) {
    outState.putString("key", "value");
    super.onSaveInstanceState(outState);
}

protected void onRestoreInstanceState(Bundle savedInstanceState) {
    super.onRestoreInstanceState(savedInstanceState);
    String value = savedInstanceState.getString("key");
    Log.i(TAG, "onRestoreInstanceState: "+value);
}
```

## Fragment
`Fragment`分为两种：
 - 一种是`View`的`Save/Restore`
 - 另一种是`Fragment`自身数据的`Save/Restore`

### View的Save/Restore
和`Activity`一样，在`View`内部实现`onSaveInstanceState()`和`onRestoreInstanceState()`即可。
如果是第三方的View，则写一个子类手动实现`Save/Restore`即可。


### Fragment的Save/Restore
在Fragment内部实现`onSaveInstanceState()`和`onActivityCreated()`即可。
```java
protected void onSaveInstanceState(Bundle outState) {
    outState.putString("key", "value");
    super.onSaveInstanceState(outState);
}

protected void onActivityCreated(Bundle savedInstanceState) {
    super.onActivityCreated(savedInstanceState);
    String value = savedInstanceState.getString("key");
    Log.i(TAG, "onRestoreInstanceState: "+value);
}
```
