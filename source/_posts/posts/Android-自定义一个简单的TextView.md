---
title: 自定义一个简单的TextView
url: custom_a_simple_TextView
tags:
  - 自定义View
categories:
  - Android
date: 2016-06-24 08:58:31
---

# 定义、使用属性 
首先在`res/values/attrs.xml`文件夹（没有的话自己创建一个）中设置好自定义的属性。
注意，因为`Toolbar`中已经有了`titleTextColor`的属性，如果我们进行声明，则会编译不通过。
所以这里进行了引用，也就是不写format。
<!-- more -->
属性有：

|     值    | 含义   | 值        | 含义     |
|:----------|:-------|:----------|:---------|
| string    | 字符串 | color     | 颜色     |
| demension | 尺寸   | integer   | 整型     |
| enum      | 枚举   | reference | 引用     |
| float     | 浮点   | boolean   | 布尔     |
| fraction  | 百分数 | flag      | 位或运算 |

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <declare-styleable name="CustomTitleView">
        <attr name="titleText" format="string"/>
        <attr name="titleTextSize" format="dimension"/>
        <attr name="titleTextColor"/>
    </declare-styleable>
</resources>
```

## 在代码中获取属性值
自定义了属性之后，当然是在构造方法中获取属性值。
```java
public class CustomTitleView extends View implements View.OnClickListener{
    private String titleText;
    private int titleTextColor;
    private int titleTextSize;
    private Rect rect;
    private Paint paint;
    public CustomTitleView(Context context) {this(context, null);}//调用自身构造方法
    public CustomTitleView(Context context, AttributeSet attrs) {this(context, attrs, 0);}//调用自身构造方法
    public CustomTitleView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        //获取所有的属性
        TypedArray ta = context.obtainStyledAttributes(attrs, R.styleable.CustomTitleView, defStyleAttr, 0);
        int n = ta.getIndexCount();
        for(int i = 0; i < n; i++){
            int attr = ta.getIndex(i);
            switch(attr){
                case R.styleable.CustomTitleView_titleText:
                    titleText = ta.getString(attr);
                    break;
                case R.styleable.CustomTitleView_titleTextColor:
                    titleTextColor = ta.getColor(attr, Color.BLACK);
                    break;
                case R.styleable.CustomTitleView_titleTextSize:
                    //这里将获取的数值单位转换为sp单位
                    titleTextSize = ta.getDimensionPixelSize(attr, (int) TypedValue.applyDimension(
                            TypedValue.COMPLEX_UNIT_SP, 15, getResources().getDisplayMetrics()));
                    break;
            }
        }
        ta.recycle();
        //设置画笔
        paint = new Paint();
        paint.setTextSize(titleTextSize);
        //Rect是文字所在的矩形，用于测量View的大小
        rect = new Rect();
        paint.getTextBounds(titleText, 0, titleText.length(), rect);
    }
}
```

## 重写onMeasure方法
重写onMeasure方法，否则的话不支持wrap_content
```java
@Override
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    //这里是必须的,当titleText改变时,rect也必须改变,否则不会对titleText适配
    paint.setTextSize(titleTextSize);
    paint.getTextBounds(titleText, 0, titleText.length(), rect);
    int widthMode = MeasureSpec.getMode(widthMeasureSpec);//获取测量模式
    int widthSize = MeasureSpec.getSize(widthMeasureSpec);//获取测量大小
    int width;
    if(widthMode == MeasureSpec.EXACTLY){//如果是固定100dp或match_parent
        width = widthSize;
    } else {如果是warp_content
        width = getPaddingLeft()+rect.width()+getPaddingRight();//注意要加上padding
    }
    int heightMode = MeasureSpec.getMode(heightMeasureSpec);//同width
    int heightSize = MeasureSpec.getSize(heightMeasureSpec);
    int height;
    if(heightMode == MeasureSpec.EXACTLY){
        height = heightSize;
    } else {
        height = getPaddingTop()+rect.height()+getPaddingBottom();
    }
    setMeasuredDimension(width, height);//最后设置参数,super里面也是调用这个方法进行设置
}
```

## 进行绘制
```java
@Override
protected void onDraw(Canvas canvas) {
    paint.setColor(Color.YELLOW);
    canvas.drawRect(0, 0, getMeasuredWidth(), getMeasuredHeight(), paint);//绘制背景
    paint.setColor(titleTextColor);
    canvas.drawText(titleText, getWidth()/2-rect.width()/2, getHeight()/2+rect.height()/2, paint);//绘制文字
    //为什么width是减,height是加,要看API文档
}
```

