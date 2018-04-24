---
title: GitHub删除敏感commit
url: Delete_sensitive_submissions_in_Github
tags:
  - GitHub
categories:
  - 编程杂谈
date: 2018-03-19 21:52:15
---
# 前言
`GitHub`上提交项目时, 有时会把密钥等敏感信息不小心提交上去, 这时候需要删除`commit`。而`GitHub`自身是不支持删除`commit`的, 需要借助`Git`来删除。

<!-- more -->

# 操作
打开一个文件夹, 在里面打开`Git`命令行。

```sh
# 1. clone 整个项目
$ git clone 项目路径
# 2. 查看最近4条commit记录
$ git log -n 4
commit abcdefg1234567 (HEAD -> master, origin/master, origin/HEAD)
Author: Ahaochan <844394093@qq.com>
Date:   Wed Jan 3 09:06:34 2018 +0800
# 3. 根据commit-id回滚
git reset --hard abcdefg1234567 
# 4. 强制push到GitHub上
git push --force
```

# 参考资料
- [5.2 代码回滚：Reset、Checkout、Revert 的选择](https://github.com/geeeeeeeeek/git-recipes/wiki/5.2 代码回滚：Reset、Checkout、Revert 的选择)