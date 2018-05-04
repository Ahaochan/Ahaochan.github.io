---
title: Travis-CI加密文件
url: Travis_CI_Encrypting_Files
tags:
  - Travis-CI
  - 翻译
categories:
  - 编程杂谈
date: 2018-05-04 23:43:00
---
# 前言
原文: [Encrypting Files](https://docs.travis-ci.com/user/encrypting-files/)

**请注意，加密文件不适用于[pull requests from forks](https://docs.travis-ci.com/user/pull-requests#Pull-Requests-and-Security-Restrictions)。**

# 先决条件

*   安装 Travis CI [命令行客户端](https://github.com/travis-ci/travis.rb#readme)
*   使用`$ travis login`或者`$ travis login --pro`[登录](https://github.com/travis-ci/travis.rb#login) 到 Travis CI 

```sh
# 译者追加
$ yum install -y gcc ruby ruby-devel # 安装gcc和ruby环境
$ gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/ # 改为国内gem源
$ gem install travis
$ travis login
```
有关系统所需版本的`Ruby`和操作系统的更多信息，请参阅命令行客户端[安装说明](https://github.com/travis-ci/travis.rb#installation)。

# 自动加密

假设:
*   这个仓库设置在了`Travis CI`上
*   你安装了**1.7.0**以上版本的`Travis CI`命令行客户端, 并成功登录`Travis CI`
*   你`clone`了仓库到本地, 并且工作目录`pwd`在该本地仓库下
*   你在仓库中有一个名为`super_secret.txt`的文件, 你想要在`Travis CI`使用这个文件，但你不想在`GitHub`上公开这个文件的内容。

`travis encrypt-file`命令将使用对称加密(AES-256)为你加密文件, 并将密钥存储在`secure`变量中。
`travis encrypt-file`命令将输出以下命令, 你可以在你的构建脚本中解密这个文件。
```sh
$ travis encrypt-file super_secret.txt
encrypting super_secret.txt for rkh/travis-encrypt-file-example
storing result as super_secret.txt.enc
storing secure env variables for decryption
# 请将以下内容添加到您的构建脚本中(例如，在`.travis.yml`中的`before_install`阶段)：
openssl aes-256-cbc -K $encrypted_0a6446eb3ae3_key -iv $encrypted_0a6446eb3ae3_iv -in super_secret.txt.enc -out super_secret.txt -d
# 提示: 你可以添加 `--add` 选项让它自动添加到`.travis.yml`.

# 确保添加 super_secret.txt.enc 到你的 git 仓库
# 确保不要添加 super_secret.txt 到你的 git 仓库
# 提交你的`.travis.yml`
```
您也可以使用`--add`选项自动将解密命令添加到您的`.travis.yml`
```sh
$ travis encrypt-file super_secret.txt --add
encrypting super_secret.txt for rkh/travis-encrypt-file-example
storing result as super_secret.txt.enc
storing secure env variables for decryption

确保添加 super_secret.txt.enc 到你的 git 仓库
确保不要添加 super_secret.txt 到你的 git 仓库
提交你的`.travis.yml`
```

## 加密多个文件
直接加密多个文件会有`bug`，命令行客户端将会[覆盖前一个加密文件](https://github.com/travis-ci/travis.rb/issues/239)。

如果您需要加密多个文件，请首先创建敏感文件的**压缩包**，然后在构建期间将其解密并解压.
假设我们有敏感文件`foo`和`bar`, 运行以下命令.
```sh
$ tar cvf secrets.tar foo bar
$ travis encrypt-file secrets.tar
$ vi .travis.yml
$ git add secrets.tar.enc .travis.yml
$ git commit -m 'use secret archive'
$ git push
```

然后在`.travis.yml`中添加解密步骤, 根据你的需求调整`$*_key` 和`$*_iv`.
```
before_install:
  - openssl aes-256-cbc -K $encrypted_5880cf525281_key -iv $encrypted_5880cf525281_iv -in secrets.tar.enc -out secrets.tar -d
  - tar xvf secrets.tar

```

## 警告

这个函数在本地`Windows`机器上不起作用。 请使用`WSL`(适用于`Linux`的`Windows`子系统)或`Linux`或`OS X`操作系统。

# 手动加密

假设:
*   这个仓库设置在了`Travis CI`上
*   你安装了**1.7.0**以上版本的`Travis CI命令行客户端, 并成功登录
*   你`clone`了仓库到本地, 并且工作目录`pwd`在该本地仓库下
*   你在仓库中有一个名为`super_secret.txt`的文件, 你想要在`Travis CI`使用这个文件，但你不想在`GitHub`上公开这个文件的内容。

该文件可能**太大**，无法通过`travis encrypt`命令直接加密。
但是，您可以使用密码来加密文件，然后再加密这个密码。在Travis CI上，您可以使用密码解密这个文件。

设置过程如下所示：

1.  **创建密码**。首先，你需要一个密码。我们建议使用`pwgen`或`1password`等工具生成随机密码。在我们的例子中，我们将使用`ahduQu9ushou0Roh`作为密码。
1.  **加密这个密码并添加到.travis.yml**。这里我们可以使用这个加密命令: `travis encrypt super_secret_password=ahduQu9ushou0Roh --add`, 注意，如果你有多个文件需要手动加密, 你必须使用不同的变量名, 这样密码就不会相互覆盖。
1.  **本地加密文件**。使用你已经安装在本地的工具`GPG`或`OpenSSL`，它也安装在`Travis CI`上(见下文)。
1.  **设置解密命令**。您应该将用于解密文件的命令添加到`.travis.yml`的`before_install`阶段（请参阅下文）。
确保添加`super_secret.txt`到你的`.gitignore`文件中, 并提交你的`加密后的文件`和`.travis.yml`.

## 使用GPG加密
设置:
```sh
$ travis encrypt super_secret_password=ahduQu9ushou0Roh --add
$ gpg -c super_secret.txt
(将提示您输入密码两次，使用与上述super_secret_password相同的值)
```
```yml
# .travis.yml
env:
  global:
    secure: 加密后的值
before_install:
  - echo $super_secret_password | gpg --passphrase-fd 0 super_secret.txt.gpg

```
加密的文件名为`super_secret.txt.gpg`, 并且必须被提交到仓库。

## 使用OpenSSL
设置:
```sh
$ travis encrypt super_secret_password=ahduQu9ushou0Roh --add
$ openssl aes-256-cbc -k "ahduQu9ushou0Roh" -in super_secret.txt -out super_secret.txt.enc
(记住用适当的值替换密码)
```
```yml
# .travis.yml
env:
  global:
    secure: 加密后的值
before_install:
  - openssl aes-256-cbc -k "$super_secret_password" -in super_secret.txt.enc -out super_secret.txt -d

```
加密的文件名为`super_secret.txt.enc`, 并且必须被提交到仓库。
