---
title: git使用
url: how_to_use_GitHub_with_git
tags:
  - 工具
categories:
  - 工具
date: 2016-07-31 20:27:40
---

# 常用上传
1. 初始化`git init`
1. 添加所有文件`git add .`
1. 提交到本地仓库`git commit -m "描述"`
1. 连接github分支`git pull origin master`
1. 连接到github仓库`git remote add origin git@github.com:Ahaochan/项目名.git`
1. 提交到远程仓库`git push -u origin master`

<!-- more -->

# 常用下载
```shell
git clone https://github.com/seven332/EhViewer
cd EhViewer
./gradlew app:assembleDebug
```

# 分支相关
- 新建分支：`git branch 分支名`
- 切换分支：`git checkout 分支名`
- 上传分支：`git push origin 分支名`
- 删除本地分支：`git branch -d 分支名`
- 删除`github`分支(分支名前的冒号代表删除)：`git push origin :分支名`

# Tag相关
- 为过往`commit`添加`tag`
```shell
git log --oneline
git tag -a v1.00 -m "描述" b6195be
```
- 查看tag：`git tag`
- 删除tag：`git tag -d v1.00`
- 删除github Tag：`git push origin :v1.00`
- 提交github仓库：`git push origin v1.00`
