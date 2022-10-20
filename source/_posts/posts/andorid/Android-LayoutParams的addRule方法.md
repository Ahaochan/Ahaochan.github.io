---
title: LayoutParams的addRule方法
url: addRule_method_of_LayoutParams
tags: 
  - 自定义View
categories:
  - Android
date: 2016-06-21 09:32:19
---

自定义`ViewGroup`中，需要用`LayoutParams`对子`View`进行布局
```java
mLeftParams = new LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.MATCH_PARENT);
mLeftParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT, TRUE);
mLeftParams.addRule(RelativeLayout.RIGHT_OF, R.id.leftView);
```
<!-- more -->

等价于
```xml
android:layout_alignParentLeft="true"
android:layout_toRightOf="@id/leftView"
```
