---
title: TravisCI加密配置文件并自动部署Hexo
url: TravisCI_encrypts_configuration_files_and_automatically_deploys_Hexo
tags: 
  - Travis-CI
  - Hexo
categories:
  - Hexo
date: 2018-05-05 15:03:00
---
# 前言
[Travis-CI](https://travis-ci.org/)是一个可以将`Github`上的代码做持续集成的网站。
持续集成和版本控制相关联, `Git`就是一种版本控制, 可以提交, 也可以下载, 就像网盘一样。
持续集成就是你的每一次提交上传, 服务器都会自动对你提交后的代码进行编译, 单元测试等一系列行为, 并告知你是否成功。

<!-- more -->

# 阅读条件
1. 至少一次手动`hexo d`部署过`GitHub Page`博客
2. 熟悉Linux基本命令
3. 熟练Git基本命令

# 准备环境
## 准备虚拟机
1. 使用的是`CentOS7`虚拟机, 用户名`root`, 密码`root`
2. 网络连接选择**桥接**模式, 关于桥接模式可以看我的另一篇文章。
{% qnimg TravisCI加密配置文件并自动部署Hexo_01.png %}

3. `Windows`网络环境选择专用网络
{% qnimg TravisCI加密配置文件并自动部署Hexo_02.png %}
4. `Windows10`需要在网络适配器属性界面, 添加`VMware Bridge Protocol`协议。
{% qnimg TravisCI加密配置文件并自动部署Hexo_03.png %}

5. 使用[Xshell](https://www.netsarang.com/products/xsh_overview.html)(发送命令)和[FileZilla](https://filezilla-project.org/)(传输文件)在`Windows`上连接虚拟机. 两者都是通过`ssh`连接的, 在软件中配置好虚拟机的`IP`地址和账号密码`root`即可。
{% qnimg TravisCI加密配置文件并自动部署Hexo_04.png %}
{% qnimg TravisCI加密配置文件并自动部署Hexo_05.png %}
{% qnimg TravisCI加密配置文件并自动部署Hexo_06.png %}

## 准备Travis-CI帐号
[Travis-CI](https://travis-ci.org/)支持`GitHub`帐号登录。
配置教程参考[使用 Travis 自动部署 Hexo 到 Github 与 自己的服务器](https://segmentfault.com/a/1190000009054888#articleHeader1)

## 准备Git并clone
```sh
# 1. 修改yum源 为 网易源
$ yum install -y wget
$ wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
$ yum clean all
$ yum makecache
# 2. 安装git
$ yum install -y git
# 3. 配置git
$ git config --global user.name "Ahaochan"
$ git config --global user.email "844394093@qq.com"
# 3. clone项目到/opt文件夹下
$ cd /opt
$ git clone https://github.com/Ahaochan/Ahaochan.github.io.git
$ cd Ahaochan.github.io/
# 4. 新建并切换到source分支
$ git branch source
$ git checkout source
# 5. 删除所有文件, 为hexo源文件腾出位置
$ rm -rf *
```

## 准备Travis-CI 客户端
```sh
# 1. 安装gcc和ruby环境
$ yum install -y gcc ruby ruby-devel
# 2. 改为国内gem源
$ gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/ 
# 3. 安装Travis
$ gem install travis
# 4. 登录Travis, 并输入账号密码
$ travis login
```

## 将本地的hexo移动到服务器
**请确保服务器的项目分支已经切换到`source`**
通过[FileZilla](https://filezilla-project.org/)将本地的`hexo`文件夹部署到服务器。
为了节省`GitHub`空间, 我只将以下文件加入仓库中。
{% qnimg TravisCI加密配置文件并自动部署Hexo_07.png %}

# 加密next.yml
我将`hexo/_config.yml`和`theme/next/_config.yml`的内容统一复制到`source/_data/next.yml`中。
配置文件包含太多敏感信息, 所以我进行了加密.
`Travis-CI`提供了加密策略, 只要加密后, 就只有`Travis-CI`能解密, 就算是加密的人也不能解密。具体可以看我翻译的`Travis-CI`文档。

```sh
# 1. 确保在source分支下操作
$ git checkout source
# 2. 进入next.yml所在文件夹
$ cd source/_data
# 3. 进行加密(如果想要加密多个文件, 需要将多个文件打包, 再在Travis-CI解压)
$ travis encrypt-file next.yml
# 4. 在.travis.yml中加入配置, 注意要指定source/_data/next.yml路径. (这里不要复制我的key, 每个人都不一样)
$ vim /opt/Ahaochan.github.io/.travis.yml
before_install:
- openssl aes-256-cbc -K $encrypted_3873d9e40d23_key -iv $encrypted_3873d9e40d23_iv -in source/_data/next.yml.enc -out source/_data/next.yml -d
# 5. 在.gitignore添加一行, 不提交next.yml
$ vim /opt/Ahaochan.github.io/.gitignore
source/_data/next.yml
```

# 给予Travis推送GitHub的权限
网上很多都是生成`ssh`公钥, 或者直接使用`git push -u origin master`的方式部署。
我参考的[使用 Travis 自动部署 Hexo 到 Github 与 自己的服务器](https://segmentfault.com/a/1190000009054888#articleHeader1)配置了`REPO_TOKEN`, 但是没有物尽其用。
这里将`REPO_TOKEN`做了替换。
```yml
# next.yml
deploy:
  - type: git
    repo: https://REPO_TOKEN@github.com/Ahaochan/Ahaochan.github.io.git
    branch: master
```

```yml
# .travis.yml
before_install:
# 注意要放在解密next.yml文件命令之后
- sed -i "s/REPO_TOKEN/${REPO_TOKEN}/" source/_data/next.yml
```


# 从GitHub下载最新模块和主题
为了节省`Github`空间, 我在`.travis.yml`配置了很多的下载命令.
详细可以看我的GitHub
```yml
# 使用语言
language: node_js
# node版本
node_js: stable
# 设置只监听哪个分支
branches:
  only:
  - source
# 缓存，可以节省集成的时间，这里我用了yarn，如果不用可以删除
cache:
  apt: true
  yarn: true
  directories:
    - node_modules
    - theme
before_install:
#  配置git
- git config --global user.name "Ahaochan"
- git config --global user.email "844394093@qq.com"
# 由于使用了yarn，所以需要下载，如不用yarn这两行可以删除
- curl -o- -L https://yarnpkg.com/install.sh | bash
- export PATH=$HOME/.yarn/bin:$PATH
# npm模块安装
- npm install -g hexo-cli
- npm install hexo-generator-searchdb --save
- npm install hexo-generator-feed --save
- npm install hexo-qiniu-sync --save
- npm install hexo-related-popular-posts --save
- npm install hexo-symbols-count-time --save
- npm install hexo-generator-sitemap --save
- npm install hexo-generator-baidu-sitemap --save
- npm install hexo-deployer-git --save
- npm install hexo-leancloud-counter-security --save
# next.yml配置文件解密
- openssl aes-256-cbc -K $encrypted_3873d9e40d23_key -iv $encrypted_3873d9e40d23_iv -in source/_data/next.yml.enc -out source/_data/next.yml -d
# 将 GitHub Token 替换到 next.yml 中
- sed -i "s/REPO_TOKEN/${REPO_TOKEN}/" source/_data/next.yml
# next主题下载
- git clone https://github.com/theme-next/hexo-theme-next themes/next
# next主题依赖下载
- git clone https://github.com/theme-next/theme-next-pangu.git themes/next/source/lib/pangu
- git clone https://github.com/theme-next/theme-next-reading-progress themes/next/source/lib/reading_progress
- git clone https://github.com/theme-next/theme-next-fastclick themes/next/source/lib/fastclick
- git clone https://github.com/theme-next/theme-next-jquery-lazyload themes/next/source/lib/jquery_lazyload
- git clone https://github.com/theme-next/theme-next-pace themes/next/source/lib/pace
- git clone https://github.com/theme-next/theme-next-canvas-nest themes/next/source/lib/canvas-nest
- git clone https://github.com/theme-next/theme-next-fancybox3 themes/next/source/lib/fancybox
install:
# 不用yarn的话这里改成 npm i 即可
- yarn
script:
# 配置 LeanCloud
- hexo lc-counter register $leancloud_username $leancloud_password --config source/_data/next.yml
- hexo clean --config source/_data/next.yml
- hexo g --config source/_data/next.yml
- hexo d --config source/_data/next.yml
```
# 最后
最后将所有文件`git push -u origin source`推送到远程的`source`分支上即可。
如果失败, 可以在 https://travis-ci.org/Ahaochan/Ahaochan.github.io/requests 查看错误信息。


# 参考资料
- [CentOS yum 源的配置与使用](https://www.jianshu.com/p/d8573f9d1f96)
- [使用 Travis 自动部署 Hexo 到 Github 与 自己的服务器](https://segmentfault.com/a/1190000009054888)
- [Auto Deploy Hexo.io to Github Pages With Travis CI](http://kflu.github.io/2017/01/03/2017-01-03-hexo-travis/)