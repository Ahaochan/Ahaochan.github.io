---
title: Android Studio疑难解决
url: Android_Studio_question
tags:
  - 工具
categories:
  - 工具
date: 2016-07-26 20:32:07
---


# 导入第三方类库错误：Could not find com.github.* :{jitpack-release}

在使用[progresshint](https://github.com/techery/progresshint) 的第三方库时，直接在gradle中添加
<!-- more -->
```groovy
repositories {  
  jcenter()  
  maven { url "https://jitpack.io" }  
}  
dependencies {  
  compile 'com.github.techery.progresshint:library-addition:{jitpack-release}'  
}  
```
但是爆出了错误
```shell
Error:Could not find com.github.techery.progresshint:library-addition:{jitpack-release}.  
Required by:  
    wnacg:app:unspecified  
Search in build.gradle files  
```
把**{jitpack-release}**换成**版本号**就可以了
解决代码
```
repositories {  
  jcenter()  
  maven { url "https://jitpack.io" }  
}  
dependencies {  
  compile 'com.github.techery.progresshint:library-addition:0.2.3'  
}  
```

# 找不到v4、v7包
```shell
 Rendering Problems Missing styles. Is the correct theme chosen for this layout?  Use the Theme combo box above the layout to choose a different layout, or fix the theme style references.  The following classes could not be found:  
- android.support.v7.widget.AppCompatSeekBar (Fix Build Path, Create Class)  
- android.support.v7.widget.RecyclerView (Fix Build Path, Create Class)  
 Tip: Try to build the project.  Failed to find style 'textViewStyle' in current theme (62 similar errors not shown)   
```
检查了`gradle`中是否有导入
```groovy
compile 'com.android.support:support-v4:23.4.0'  
compile 'com.android.support:appcompat-v7:23.4.0'  
compile 'com.android.support:design:23.4.0'  
```
仍然找不到`v4`、`v7`包
最后在`SDK Manager`中发现`Android Support Library`的版本号才更新到`23.2.1`
换成`23.2.1`就好了

 
