---
title: NPM包管理工具入门
url: what_is_npm
tags:
  - Nodejs
categories:
  - Nodejs
date: 2021-03-01 23:03:00
---

# 前言
`NPM`对于`Nodejs`, 就像`Maven`对于`Java`.
`NPM`是一个包管理工具, 用于管理依赖. 

<!-- more -->

# npmrc 详解
作为一个包管理工具, 肯定有相关的配置.
比如, 从哪个仓库下载依赖, 保存到本地的哪个目录下.

安装好`NPM`后, 会有三个文件
1. 每个项目的配置文件(`/path/to/my/project/.npmrc`)
1. 每个用户的配置文件(`〜/.npmrc`)
1. 全局配置文件(`$PREFIX/etc/npmrc`)
1. `NPM`内置配置文件(`/path/to/npm/npmrc`)

具体可以看看[`npmrc`官方文档](https://docs.npmjs.com/cli/v7/configuring-npm/npmrc)

```shell script
# 设置远程仓库
npm config set registry https://registry.npm.taobao.org 
# 设置缓存位置
npm config set cache "D:\nodejs\node_cache"
# 设置全局模块存放位置  
npm config set prefix "D:\nodejs"

npm config ls
```
像我们一开始都会配置国内仓库, 这些命令都是去修改用户的配置文件, 也就是`~/.npmrc`

# package.json 和 package-lock.json
和`pom.xml`类似, `package.json`就是描述这个项目的, 发布的时候会用到.
这里拿`hexo`的举个例子.
```json
{
  "name": "hexo-site",
  "version": "0.0.0",
  "scripts": {
    "build": "hexo generate",
    "clean": "hexo clean",
    "deploy": "hexo deploy",
    "server": "hexo server"
  },
  "hexo": {
    "version": "5.3.0"
  },
  "dependencies": {
    "hexo": "^5.0.0",
    "hexo-generator-archive": "^1.0.0",
    "hexo-generator-category": "^1.0.0",
    "hexo-generator-index": "^2.0.0",
    "hexo-generator-tag": "^1.0.0",
    "hexo-renderer-ejs": "^1.0.0",
    "hexo-renderer-marked": "^3.0.0",
    "hexo-renderer-stylus": "^2.0.0",
    "hexo-server": "^2.0.0",
    "hexo-theme-landscape": "^0.0.3"
  }
}
```

`name`和`version`是必填项, 用来标记项目名称和版本号. 这个`name`可以作为`require`的参数传递.
`scripts`用来注册`npm`命令, 比如`npm clean`就会调用`hexo clean`命令.
`hexo`是自定义的配置, 不用管.
`dependencies`表示本项目的所有依赖名称以及版本哈.

具体可以看看[`package.json`官方文档](https://docs.npmjs.com/cli/v7/configuring-npm/package-json)

`package-lock.json`和`package.json`结构差不多, 那为什么要有两个不同的文件呢?

# package.json 和 package-lock.json
比如说`hexo`依赖的`hexo-renderer-ejs`在`package.json`的版本号是`1.0.0`.
在执行`npm install`的时候, `npm`会根据`package.json`的定义, 从本地磁盘或远程仓库里获取依赖.

假设`hexo-renderer-ejs`紧急发布了一个修复`bug`的版本`1.0.2`.
那在执行`npm install`的时候就会去根据主版本号`1`去获取最新的`hexo-renderer-ejs`版本.

正常按语义化版本的规范来说, 只要主版本号不变, 那都是兼容的.
但万一不按规范来, 比如`1.0.2`和`1.0.0`是不兼容的. 而`npm install`每次都会根据主版本号去拉取最新的依赖, 那风险就很大了.

为了解决这个问题, `package-lock.json`就出现了. `package-lock.json`和`package.json`结构差不多.
执行`npm install`的时候, `npm`会根据`package.json`拉取最新的依赖版本, 然后生成`package-lock.json`, 锁定版本号.
然后下次`npm install`的时候, 就会从`package-lock.json`中获取准确的版本号, 就不会出现升级风险. 

# 参考资料
- [官方文档](https://docs.npmjs.com/cli/v7/)
