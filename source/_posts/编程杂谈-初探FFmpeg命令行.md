---
title: 初探FFmpeg命令行
url: learn_FFmpeg_command_tool
tags:
  - FFmpeg
categories:
  - 编程杂谈
date: 2018-04-18 11:24:11
---
# 前言
微博上很火的`sorry`表情包程序, 看到有`Java`程序, 于是扒了下来看[源码](https://github.com/xtyxtyx/sorry)。
看是怎么实现的, 原来是生成`ass`字幕文件, 然后用`FFmpeg`命令加入视频。

<!-- more -->

# 介绍
`FFmpeg`是用于录制、转换和流化音频和视频的完整解决方案。
[官网地址](https://www.ffmpeg.org/)、[GitHub地址](https://github.com/FFmpeg/FFmpeg)

**安装教程**
- [官网安装教程](https://www.ffmpeg.org/download.html)
- [如何在CentOS上安装FFmpeg](https://www.vultr.com/docs/how-to-install-ffmpeg-on-centos)

# ffmpeg -h帮助
在命令行输入`ffmpeg -h`可以看到帮助命令。
这里只显示常用的帮助命令。
```sh
用法: ffmpeg [options] [[infile options] -i infile]... {[outfile options] outfile}...

获取帮助:
    -h      -- 打印基本帮助命令
    -h long -- 打印更多帮助命令
    -h full -- 打印所有帮助命令 (包括所有格式和编解码器特定的选项, 很长)
    有关选项的详细说明, 请参阅man ffmpeg.

打印帮助 / 信息 / 功能:
-L                  显示license许可证
-version            显示版本
-formats            显示可用的格式
-codecs             显示可用的编码器、解码器

全局选项（影响整个程序而不是仅仅一个文件:
-v loglevel         设置日志输出等级
-report             generate a report
-y                  覆盖输出文件
-n                  不覆盖输出文件

每个文件的主要选项:
-f fmt              指定输出格式
-t duration         录制或转码音频/视频的“持续时间”, 以秒为单位
-to time_stop       录制或转码音频/视频的“截止时间”, 以秒为单位
-ss time_off        录制或转码音频/视频的“开始时间”, 以秒为单位, 也支持[-]hh:mm:ss[.xxx]的时间格式

视频选项:
-vframes number     设置要输出的视频帧的数量
-r rate             设置帧率(Hz值，分数或缩写)
-s size             设置帧分辨率(如1280x720)
-aspect aspect      设置纵横比 (4:3, 16:9 或 1.3333, 1.7777)
-vn                 禁用视频, 用于只输出音频文件
-vf filter_graph    设置视频过滤器
-ab bitrate         指定音频比特率(单位kbit/s), 如-b:a 320
-b bitrate          指定视频比特率(单位kbit/s), 如-b:v 64

音频选项:
-ar rate            设置音频采样率(以Hz为单位)
-an                 禁用音频, 用于只输出视频

字幕选项:
-sn                 禁用字幕
```
# FFmpeg过滤器
`ffmpeg`目录下, 有个文件夹叫`libavfilter`, 它可以单独编译为一个库。用于音视频过滤。 
相当于一个特效之类的东西。
[官方文档](https://ffmpeg.org/ffmpeg-filters.html)


# 使用示例
1. 显示媒体文件详细信息
```sh
ffmpeg -i input.mp4
```
2. 将视频文件转换为不同的格式
```sh
ffmpeg -i input.mp4 output.avi
```
3. 将视频文件转换为音频文件
```sh
ffmpeg -i input.mp4 -vn -ar 44100 -ac 2 -ab 320 -f mp3 output.mp3 
```
4. 更改视频文件的分辨率
```sh
ffmpeg -i input.mp4 -s 1280x720 -c:a copy output.mp4 
ffmpeg -i input.mp4 -filter:v scale=640:480 -c:a copy output.mp4
```
5. 压缩
```sh
# 压缩视频文件
ffmpeg -i input.mp4 -vf scale=1280:-1 -c:v libx264 -preset veryslow -crf 24 output.mp4 
# 压缩音频文件
ffmpeg -i input.mp3 -ab 128 output.mp3 
```
6. 删除音频、视频
```sh
# 删除视频
ffmpeg -i input.mp4 -vn output.mp3
# 删除音频
ffmpeg -i input.mp4 -an output.mp4
```
7. 截取图片
```sh
# 截取1帧图片保存为image-01.png的格式
ffmpeg -i input.mp4 -r 1 -f image2 image-%2d.png 
```
8. 裁剪视频
```sh
# 从位置(10,20)开始裁剪300×400的部分
ffmpeg -i input.mp4 -filter:v "crop=10:20:300:400" output.mp4 
# 将第10秒开始的50秒视频转为avi格式, 可以用hh.mm.ss格式
ffmpeg -i input.mp4 -ss 10 -t 50 output.avi 
# 将纵横比改为16:9
ffmpeg -i input.mp4 -aspect 16:9 output.mp4 
```
8. 添加字幕到视频文件
```sh
ffmpeg -i input.mp4 -i subtitle.srt -map 0 -map 1 -c copy -c:v libx264 -crf 23 -preset veryfast output.mp4
```
9. 添加字幕并转为gif
```sh
ffmpeg -i input.mp4 -r 6 -vf ass=videoAss.ass,scale=300:-1 -y output.gif
```

# 参考资料
- [在线制作sorry 为所欲为的gif](https://github.com/xtyxtyx/sorry)
- [20 FFmpeg初学者命令](https://www.ostechnix.com/20-ffmpeg-commands-beginners/)
- [FFMPEG使用参数详解](https://blog.csdn.net/axdc_qa_team/article/details/4204358)
- [ffmpeg filter过滤器 基础实例及全面解析](https://blog.csdn.net/newchenxf/article/details/51364105)
