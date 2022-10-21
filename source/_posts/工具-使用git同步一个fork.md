---
title: 使用git同步一个fork
url: how_to_update_fork_by_git
date: 2017-10-30 22:20:58
tags:
  - Git
categories:
  - 工具
---

# 前言
搭了个Hexo博客, 然后把NexT主题[fork](https://github.com/Ahaochan/hexo-theme-next)了一下。
本文记录下从被fork的项目更新fork的操作。
<!-- more -->

# 添加一个远程仓库
```sh
 $ git remote add upstream 原始项目地址  # 添加一个名为upstream的远程项目
 $ git remote -v # 查看远程仓库, origin是默认仓库名, 一般是自己的github项目
   origin    https://github.com/YOUR_USERNAME/YOUR_FORK.git (fetch)
   origin    https://github.com/YOUR_USERNAME/YOUR_FORK.git (push)
   upstream  https://github.com/ORIGINAL_OWNER/ORIGINAL_REPOSITORY.git (fetch)
   upstream  https://github.com/ORIGINAL_OWNER/ORIGINAL_REPOSITORY.git (push)
```

# 从原始项目同步
```sh
 $ git fetch upstream  # 下载原始项目upstream的所有变动
 $ git checkout master # 确保切换到本地master分支
 $ git merge upstream/master # 合并upstream仓库的master分支到当前分支
```

# 解决冲突
一般可以自动解决冲突问题。
但是复杂的冲突就需要手动解决。

**直接编辑文件**
手动打开冲突的文件, 冲突的部分是`bbbbbbb`和`ccccccc`, 也就是特殊符号之间的字符串。
```
aaaaaaa
<<<<<<< HEAD
bbbbbbb
=======
ccccccc
>>>>>>> ddddddd
eeeeeee
```

**图形界面**
```sh
 $ git mergetool # 用预先配置的Beyond Compare解决冲突
```

# 参考资料
- [同步一个 fork](https://gaohaoyang.github.io/2015/04/12/Syncing-a-fork/)
- [Git下的冲突解决](http://www.cnblogs.com/sinojelly/archive/2011/08/07/2130172.html)
