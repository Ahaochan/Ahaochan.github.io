---
title: 使用ASF为Steam挂卡
url: Using_ASF_for_Steam_Idling_Card
tags:
  - ASF
categories:
  - 编程杂谈
date: 2020-03-08 17:49:00
---

# 前言
`ASF`不只是一个挂卡工具, 更像是一个命令行模式下的一个`Steam`客户端.
自己用的话就在`Win`上操作即可, 多人最好还是丢服务器挂.

<!-- more -->

# Quick Start
## 第一步 下载
下载最新的[`ASF`软件](https://github.com/JustArchiNET/ArchiSteamFarm/releases/latest)

## 第二步 建目录
建立易懂的层级目录结构
```text
C:\ASF (放置您所有与 ASF 相关的东西)
    ├── ASF    ( /Core/ArchiSteamFarm.exe 的快捷方式)              ──┐
    ├── config ( /Core/config             的快捷方式)              ──┤
    ├── ...                                                         |
    └── Core (下载解压后的文件都放在这里面)                            |
         ├── ArchiSteamFarm.exe  ───────────────────────────────────┤
         ├── config              ───────────────────────────────────┘
         └── (...)
```
主要就是建立两个快捷方式, 方便使用.

## 第三步 配置
建好目录后, 进入`/config`目录中.

打开以下链接获取自己的`64`位`SteamID`, 将`Ahaochan`换成自己的`Steam`个人资料链接即可.
`https://steamrep.com/search?q=https://steamcommunity.com/id/Ahaochan/`

创建`ASF.json`, 填写自己的`SteamID`, 用于允许执行命令.
```json
{
  "s_SteamOwnerID": "1234567890",
  "IPC": true
}
```

创建`Ahaochan.json`, 填写账号密码.
```json
{
  "SteamLogin": "Steam账户名",
  "SteamPassword": "Steam密码",
  "Enabled": true,
  "CustomGamePlayedWhileFarming": "Idling cards" 
}
```

## 第四步
打开`ASF`即可愉快的进行挂卡了, 如果有两步验证, 则每次都要输入两部验证密码.

# 两步验证解决方案
如果开了两步验证, 每次登陆都要打开手机翻密码再输入, 太麻烦了.

如果你在`Android`上安装了`Steam`官方的验证器(**这是前提**
复制`Android`手机的`/data/data/com.valvesoftware.android.steam.community`目录到`PC`上.

1. 打开`shared_prefs/steam.uuid.xml`, 记录下里面的`uuid`.
1. 复制`files/Steamguard-${SteamID}`到电脑`C:\ASF\config`目录下, 并更名为`Ahaochan.maFile`.
1. 打开`ASF`, 要求输入`uuid`时, 就输入(我没输入就成功了

# 为ASF开启代理
> Right now ASF uses web proxy only for http and https requests, 
> which do not include internal Steam network communication done within ASF's internal Steam client.
> 
> https://github.com/JustArchiNET/ArchiSteamFarm/wiki/Configuration#webproxy

简单的说, 就是不支持`socks5`代理. 那我也不研究了.

# 参考资料
- [官方文档](https://github.com/JustArchiNET/ArchiSteamFarm/wiki/Setting-up-zh-CN)