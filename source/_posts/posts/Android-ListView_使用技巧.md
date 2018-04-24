---
title: ListView 使用技巧
url: ListView_skills
tags:
  - ListView
categories:
  - Android
date: 2016-07-27 21:59:44
---

# ListView常用优化技巧
## 使用ViewHolder提高效率
创建一个ViewHolder内部类
<!-- more -->
```java
class ViewHolder{
    TextView titleView;
}
```
在`getView()`方法里面复用
```java
LayoutInflater mInflater;
public View getView(int position, View convertView, ViewGroup parent){
    ViewHolder holder = null;
    if(convertView == null){//当前子View没有被初始化过
        holder = new ViewHolder();
        convertView = mInflater.inflate(R.id.list_item, null);//通过LayoutInflater实例化布局
        holder.titleView = (TextView) convertView.findViewById(R.id.title_view);
        convertView.setTag(holder);//缓存布局
    } else {
        holder = (ViewHolder) convertView.getTag();//通过tag找到缓存的布局
    }
    holder.titleView.setText("title");
    return convertView;
}
```

## 设置item分割线
```xml
android:divider = "@android:color/darker_gray"<!--设置分割线资源-->
android:dividerHeight = "10dp"<!--设置分割线高度-->
<!--android:divider = "null"--><!--分割线为空-->
```

## 隐藏ListVIew滚动条
```xml
android:scrollbars="none"<!--隐藏ListVIew滚动条-->
```

## 取消item点击效果
在Android 5.X上是一个波纹效果，在Android 5.X之下版本是一个改变背景颜色的效果。
可以通过listSelector取消点击效果
```xml
andoird:listSelector="# 00000000"
andoird:listSelector="@android:color/transparent"//设置选择时背景为透明色，也可使用自定义的颜色效果
```

## 设置显示到第几项
```java
listView.setSelection(n);//设置Listview具体显示在第几项，默认是0
 listView.smoothScrollByOffset(35);//偏移量
 listView.smoothScrollToPosition(35);//位置
 listView.smoothScrollBy(35,1000);//距离，时间
```

## 动态修改ListView数据
```java
data.add("new");
adapter.notifyDataSetChanged();
```

## 遍历所有item
```java
for(int i = 0; i < listView.getChildCount(); i++){
    View child = listView.getChildAt(i);
}
```

## 处理空ListView
当数据源为空时，提示无数据
```java
listView.setEmptyView(emptyView);
```

## 滑动监听
### 使用OnTouchListener
```java
listView.setOnTouchListener(new OnTouchListener(){
    public boolean onTouch(View v, MotionEvent e){
        swicth(e.getAction()){
            case MotionEvent.ACTION_DOWN:    //按下时操作
                break;
            case MotionEvent.ACTION_MOVE:    //移动时操作
                break;
            case MotionEvent.ACTION_UP    ://抬起时操作
                break;
        }
        return false;
    }
});
```
### 使用OnScrollListener
```java
listView.setOnScrollListener(new OnScrollListener(){
    public void onScrollStateChanged(AbsListView view, int scrollState){    //当滑动状态改变时回调
        swicth(scrollState){
            case OnScrollListener.SCROLL_STATE_IDLE:    //滑动停止时操作
                break;
            case OnScrollListener.SCROLL_STATE_TOUCH_SCROLL:    //正在滚动
                break;
            case OnScrollListener.SCROLL_STATE_FLING:    //手指用力滑动时操作
                break;
        }
    }
    public void onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount){
        //滚动时调用
    }
});
```

# ListView常用拓展
## 弹性ListView
可以通过增加HeaderView或者使用ScrollView嵌套使用
这里通过修改源码实现。
`overScrollBy()`是一个控制滑动到边缘的处理方法，只要修改maxOverScrollY值即可。
为了适配多分辨率，建议使用DisplayMetrics 获得屏幕尺寸进行计算
```java
protected boolean overScrollBy(int deltaX, int deltaY, int scrollX, int scrollY,
                                   int scrollRangeX, int scrollRangeY,
                                   int maxOverScrollX, int maxOverScrollY, boolean isTouchEvent) {
        return super.overScrollBy(deltaX, deltaY, scrollX, scrollY,
                scrollRangeX, scrollRangeY,
                maxOverScrollX, mMaxOverScrollY, isTouchEvent);
    }
```
