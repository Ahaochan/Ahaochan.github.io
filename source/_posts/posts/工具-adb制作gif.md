---
title: adb制作gif
url: how_to_use_adb_to_create_gif
tags:
  - 工具
categories:
  - 工具
date: 2016-08-01 20:24:11
---

# 演示
有时候我们需要录制Android手机的屏幕，比如写了一个Demo应用，需要发布到博客和微博上。
如下是我录制转GIF的效果图
<!-- more -->
![](adb制作gif_01.gif)
 
# 正常录制
```shell
adb devices
adb -s 驱动编号 shell screenrecord /sdcard/test.mp4
adb -s 驱动编号 pull /sdcard/test.mp4 C:\Users\Avalon\Desktop
```
视频保存目录可以自己指定，如上面的/sdcard/test.mp4，
命令执行后会一直录制180s，按下ctrl+c可以提前结束录制

# 截图
```shell
adb -s 驱动编号 shell /system/bin/screencap -p /sdcard/screenshot.png
adb -s 驱动编号 pull /sdcard/screenshot.png C:\Users\Avalon\Desktop
```


# 转GIF文件
在`Windows`下有个不错的软件[Free Video to GIF Converter](http://www.video-gif-converter.com/index.html) 可以把`mp4`转换成`GIF`。
转换时还可以删除不需要的帧，这点真得很不错。
`Mac`上可以使用[gifrocket](http://www.gifrocket.com/) 进行转换。
还有一些在线的[转换工具](http://ezgif.com/video-to-gif) 可以使用，但是都会打上水印。

# 其他设置
- 设定视频分辨率
`adb shell screenrecord --size 848x480 /sdcard/test.mp4`
- 设定视频比特率
`adb shell screenrecord --bit-rate 2000000 /sdcard/test.mp4`
