---
title: Genymotion疑难解决
url: Genymotion_questionh
tags:
  - 工具
categories:
  - 工具
date: 2016-07-23 20:35:02
---
`genymotion`安装及使用出现的问题
此处总结`genymotion`出现的问题。
<!-- more -->

# Unable to create Virtual Device

## Connection timeout.
安装好`genymotion`后，新建一个模拟器。去下载的时候报错
`Unable to create Virtual Device: Connection timeout.`

在 `C:\Users\[你的名字]\AppData\Local\Genymobile`目录下找到 `genymotion.log`。

打开日志文件，在最后几行找到出错原因如下：
```text
四月 21 15:38:02 [Genymotion] [Debug] Remote file size: 182005760 ,current local file size: 0 
四月 21 15:38:02 [Genymotion] [Debug] writting to local file with mode OpenMode( "Append|WriteOnly" ) 
四月 21 15:38:02 [Genymotion] [Debug] Downloading file  "http://files2.genymotion.com/dists/4.3/ova/genymotion_vbox86p_4.3_140326_020620.ova" 
四月 21 15:38:02 [Genymotion] [Debug] Start timer 
四月 21 15:38:02 [Genymotion] [Error] Connection Timeout 
四月 21 15:38:02 [Genymotion] [Debug] Received code: 2 : "" 
```
复制`http://files2.genymotion.com/dists/4.3/ova/genymotion_vbox86p_4.3_140326_020620.ova `
到浏览器地址栏，通过浏览器下载这个ova

下载好后`copy` 到`C:\Users\[你的名字]\AppData\Local\Genymobile\Genymotion\ova` 里。
再次启动`genymotion`，下载这个版本的模拟器就不会报错了。

# Unable to start the Virtual Device
## VitualBox cannot start the virtual device
**问题描述**
打开genymotion，启动虚拟设备，出现如下报错
![](Genymotion疑难解决_01.png)

打开VirtualBox直接启动虚拟设备
![](Genymotion疑难解决_02.png)

发现是网络接口问题
![](Genymotion疑难解决_03.png)

**解决方案**
打开网络中心，右键`VirtualBox Host-Only Network #2`，属性，开启`VirtualBox NDIS6 Bridged Networking Driver`。

 
 
# 使用Genymotion调试出现错误INSTALL_FAILED_CPU_ABI_INCOMPATIBLE解决办法

转自：http://blog.csdn.net/wjr2012/article/details/16359113

点击下载Genymotion-ARM-Translation.zip

将你的虚拟器运行起来，将下载好的zip包用鼠标拖到虚拟机窗口中，出现确认对跨框点OK就行。然后重启你的虚拟机。


来源： http://www.cnblogs.com/wliangde/p/3678649.html
