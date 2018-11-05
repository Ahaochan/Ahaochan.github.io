---
title: Android命名规范和编码规范
url: Android_naming_conventions_and_coding_specifications
tags:
 - 编码规范
categories:
  - Android
date: 2016-06-23 09:11:07
---

# 前言
本文适用范围：已参加项目开发的人

写这篇文章的目的是为方便地对代码进行管理，让整个团队的代码规范化。这里的部分规定可能和你在其他地方看到的不一样，但还是请遵守这些规则。
>编码规范是泯灭程序猿个性的一项制度，但对于整个团队而言，却是一件利器
>-《App 研发录》

<!-- more -->

# 统一代码格式
首先请参照这篇文章设置 `Android Studio` 的 `Code Style`：
[设置 Code Style](http://blog.qiji.tech/archives/5153)
细心的同学可能会发现代码风格跟 `Google` 推荐的不一致，但请记住，我们是一个团队。

## 项目结构
{% asset_img Android命名规范和编码规范_01.jpg %}
 
## 命名规范
### 控件 Id 命名方式
命名模式：`View` 缩写_逻辑名称
例如一个登陆按钮 `Button`：`id` 为 `btn_login`，私有成员变量 `mBtnLogin`

| View         | @Id      | ava variable（private）| 
|:-------------|:---------|:-----------------------| 
| Button       | btn_     | mBtnLogin              |
| TextView     | txt_     | mTxtLogin              |
| ImageView    | img_     | mImageLogin            |
| EditText     | edt_     | mEdtContent            |
| Spinner      | spinner_ | mSpinnerNation         |
| TabLayout    | tab_     | mTabLayout             |
| LinearLayout | linear_  | mLinearLayout          |

### Layout 相关

| Component        | Class Name           | Layout Name                | 
|:-----------------|:---------------------|:---------------------------| 
| Activity         | UserProfileActivity  | activity_user_profile.xml  | 
| Fragment         | SignUpFragment       | fragment_sign_up.xml       | 
| Dialog           | ChangePasswordDialog | dialog_change_password.xml | 
| AdapterView item | -                    | list_item_archive.xml      | 

### Color 相关
通常我们不直接使用数字来定义一些属性值，而是先将它定义在所对应的文件里，然后去引用它。
- 推荐从 `Material Design` 中 `Color` 中选取颜色(后详)
- 尽量以 “颜色名称_程度” 来命名
- 必要时也可用颜色功能来命名

在[Material color palette](https://material.google.com/style/color.html#color-color-palette) 的网页中，可以看到官方设计文档的调色板，尽量从文档中选取颜色，来命名和使用。
命名采用全小写，下划线分割的形式。
```xml
<!-- color -->
 <color name="grey_xlight"># F5F5F5</color>
 <color name="grey_light"># E0E0E0</color>
 <color name="grey"># 9E9E9E</color>
 <color name="grey_dark"># 616161</color>
 <color name="grey_xdark"># 424242</color>
 
 <color name="title_normal"># FBE9E7</color>
 <color name="bg_pop># FF6D00</color>
 
<!-- material color -->
 <color name="material_red_500"># F44336</color>
 <color name="material_purple_100"># E1BEE7</color>
 <color name="material_green_800"># 2E7D32</color>
```
注意 `Material color` 的命名方式

### Dimen 相关
- 尽量以 “逻辑名称_程度” 来命名
- 必要时也可用 “逻辑名称_功能” 来命名
```xml
<!-- text size -->
 <dimen name="text_size_xxsmall">12sp</dimen>
 <dimen name="text_size_xsmall">14sp</dimen>
 <dimen name="text_size_small">16sp</dimen>
 <dimen name="text_size_medium">18sp</dimen>
 <dimen name="text_size_large">20sp</dimen>
 <dimen name="text_size_xlarge">22sp</dimen>
 
 <dimen name="text_size_title">18sp</dimen>
 
<!-- typical spacing between two views, margin or padding -->
 <dimen name="spacing_tiny">4dp</dimen>
 <dimen name="spacing_small">10dp</dimen>
 <dimen name="spacing_medium">14dp</dimen>
 <dimen name="spacing_large">24dp</dimen>
 <dimen name="spacing_huge">40dp</dimen> 
<!-- typical sizes of views -->
 <dimen name="button_height_small">32dp</dimen>
 <dimen name="button_height_medium">40dp</dimen>
 <dimen name="button_height_large">60dp</dimen>
```
### String 相关
String 命名的前缀应该能够清楚地表达它的功能职责，若是某个模块的字符串，可以以这个模块的名字为前缀然后再加上它的含义，如，`registratione_mail_hint`，`registration_name_hint`。
```xml
<string name="app_name">app名</string>
<string name="registration_email_hint">请输入邮箱地址</string>
<string name="registration_name_hint">请输入用户名</string>
```
如果一个Sting不属于任何模块，这也就意味着它是通用的，应该遵循以下规范：

| type     | detail                              | 
|:---------|:------------------------------------| 
| error_   | 错误提示                            | 
| success_ | 正确提示                            | 
| msg_     | 一般信息提示                        | 
| title_   | 标题提示，如，Dialog 标题           | 
| action_  | 动作提示，如，“保存”，“取消”，“创建”| 
| direct_  | 页面跳转提示                        | 

其他通用字符串尽量以：类别_功能 或 含义 来命名

### Drawable 相关
当没有多种类型的图片时，图片统一放在 drawable-xxhdpi 的文件夹下

| Asset Type   | Prefix        | Example                  | 
|:-------------|:--------------|:-------------------------| 
| Action bar   | ab_           | ab_stacked.9.png         | 
| Button       | btn_          | btn_send_pressed.9.png   | 
| Dialog       | dialog_       | dialog_top.9.png         | 
| Divider      | divider_      | divider_horizontal.9.png | 
| Icon         | ic_           | ic_star.png              | 
| Menu         | menu_         | menu_submenu_bg.9.png    | 
| Notification | notification_ | notification_bg.9.png    | 
| Tabs         | tab_          | tab_pressed.9.png        | 

## Android 编码规范
### XML 文件规范
**属性**
当你写好 layout 文件后，按 `Ctrl + alt + L` 格式化后，手动排版为下面这样的格式：
- 每行两个属性
- `android:id` 作为第一个属性
- 如果存在 `style` 属性，则紧随作为第二行首个属性
- 如果不存在 `style` 属性，则 `android:layout_xxx` 紧随作为第二行首个属性
- 当布局中的一个元素不再包含子元素时，在最后一个属性右边使用自闭合标签`/>`
```xml
<LinearLayout
 xmlns:android="http://schemas.android.com/apk/res/android"
 android:layout_width="match_parent" android:layout_height="match_parent"
 android:orientation="vertical">
 
 <TextView android:id="@+id/txt_name"
 style="@style/FancyText" android:layout_width="match_parent"
 android:layout_height="wrap_content" android:layout_alignParentRight="true"/>
</LinearLayout>
```
 **使用 Tools**
布局预览应使用 `tools:`相关属性，避免 `android:text` 等硬编码的出现
```xml
<TextView
 android:layout_width="wrap_content" android:layout_height="wrap_content"
 tools:text="Home Link"/>
```

## Java 代码规范
### Field
对Field的定义应该放在文件的首位，并且遵守以下规范：
- 被 `private` 修饰的非静态变量，以 `m` 作为前缀
- 被 `private` 修饰的静态变量，以 `s` 作为前缀
- 被 `public` 修饰的非静态变量，以小写首字母做前缀
- 其他变量，以 `m` 作为前缀，采用驼峰命名
- 静态常量命名字母全部大写，单词之间用下划线分隔
```java
public class MyClass {
 public static final int SOME_CONSTANT = 42;
 
 @Bind(R.id.edit_collection_name) EditText mEdtName;
 
 public int publicField;
 private static MyClass sSingleton;
 int mPackagePrivate;
 private int mPrivate;
 protected int mProtected;
}
```

### Entity
对于继承 `Entity` 的 `Model` 类型，按照下图进行编码：
{% asset_img Android命名规范和编码规范_02.png %}
注意变量修饰符和大小写

### 类成员排序
关于这个并没有硬性要求，不过好的排序方式，能够提高可读性和易学性。这里给出一些排序建议：
1. 常量
1. 字段
1. 构造函数
1. 被重写的函数（不区分修饰符类型）
1. 被private修饰的函数
1. 被public修饰的函数
1. 被定义的内部类或者接口
**如果继承了`Android`组件，比如`Activity`或者`Fragment`，重写生命周期函数时，应该按照组件的生命周期进行排序**
示例如下：
```java
public class MainActivity extends Activity {
 private static final String TAG = MainActivity.class.getSimpleName();
 private String mTitle;
 private TextView mTextViewTitle;
 @Override
 public void onCreate() { }
 
 private void setUpView() { }
 
 public void setTitle(String title) {
 mTitle = title;
 }
 
 static class AnInnerClass { }
}
```

### 字符串常量的命名
`Android SDK` 中诸如 `SharedPreferences`，`Bundle` 和 `Intent` 等，都采用 `key-value` 的方式进行赋值，当使用这些组件的时候，key 必须被 `static final` 所修饰，并且命名应该符合以下规范：

| ElementField       | Name Prefix | 
|:-------------------| :-----------| 
| SharedPreferences  | PREF_       | 
| Bundle             | BUNDLE_     | 
| Fragment Arguments | ARGUMENT_   | 
| Intent Extra       | EXTRA_      | 
| Intent Action      | ACTION_     | 

示例如下：
```java
static final String PREF_EMAIL = "PREF_EMAIL";
static final String BUNDLE_AGE = "BUNDLE_AGE";
static final String ARGUMENT_USER_ID = "ARGUMENT_USER_ID";
 
static final String EXTRA_SURNAME = "com.myapp.extras.EXTRA_SURNAME";
static final String ACTION_OPEN_USER = "com.myapp.action.ACTION_OPEN_USER";
```

### Activity 与 Fragment 打开方式
当通过 `Intent` 或者`Bundle`向`Activity`与`Fragment`传值时，应该遵循上面提到的`key-value`规范，公开一个被 `public static` 修饰的方法，方法的参数应该包含所有打开这个 `Activity` 或者 `Fragment` 的信息，示例如下：

- 通过 `.startActivity()` 函数，开启指定 `Activity`：
```java
public static void startActivity(AppCompatActivity startingActivity, User user) {
 Intent intent = new Intent(startingActivity, ThisActivity.class);
 intent.putParcelableExtra(EXTRA_USER, user);
 startingActivity.startActivity(intent);
}
```
- 通过 `.newInstance()` 函数，加载指定 `Fragment`：
```java
public static UserFragment newInstance(User user) {
 UserFragment fragment = new UserFragment;
 Bundle args = new Bundle();
 args.putParcelable(ARGUMENT_USER, user);
 fragment.setArguments(args)
 return fragment;
}
```
# 结语
如果您所寻找的命名不在上述规范中，可以暂时使用自己的方式来命名，但也要有一定格式并在自己的程序中统一。
通常我们会把更大的类别放在前，更细致的放在后。
欢迎大家提出问题，互相探讨，共同维护出一份更好的更清晰的开发规范。

# 参考资料
- [[Android]命名规范和编码规范](http://blog.qiji.tech/archives/10395)
- [Android编码规范](https://github.com/RxSmart/Link-Android-Guideline/blob/master/Android-Guideline.md)
- [Android Development Guideline](https://github.com/nekocode/nekoblog/blob/master/AndroidDevGuideline.md#property-%E5%AE%9A%E4%B9%89%E4%B8%8E%E5%91%BD%E5%90%8D%E8%A7%84%E8%8C%83)
- [Android 命名规范 （提高代码可以读性）](http://blog.csdn.net/vipzjyno1/article/details/23542617)
