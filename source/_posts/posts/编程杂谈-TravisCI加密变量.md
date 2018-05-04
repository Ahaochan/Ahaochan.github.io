---
title: Travis-CI加密文件
url: Travis_CI_Encrypting_keys
tags:
  - Travis-CI
  - 翻译
categories:
  - 编程杂谈
date: 2018-05-04 23:46:00
---
# 前言
原文: [Encryption keys](https://docs.travis-ci.com/user/encryption-keys/)

**这里有单独的关于[加密文件](https://docs.travis-ci.com/user/encrypting-files/)的文档。**

仓库`Repository`中的`.travis.yml`文件可以具有“加密值”，例如[环境变量](https://docs.travis-ci.com/user/environment-variables/)，通知设置和部署`api`的`key`。这些加密后的值可以由任何人添加，但只能由`Travis CI`解密读取。仓库`Repository`拥有者不保留任何加密`key`。

**请注意，加密的环境变量不适用于[pull requests](https://docs.travis-ci.com/user/pull-requests#Pull-Requests-and-Security-Restrictions)。**

<!-- more -->

# 加密方案
`Travis CI` 使用**非对称密码学**. 对于每个注册过的仓库`Repository`, `Travis CI` 会生成一对`RSA`密钥对. 
`Travis CI` 拥有私钥, 但是可以让每个人都可以使用该公钥. 

例如, `GitHub`仓库`foo/bar` 的**公钥**可以在`https://api.travis-ci.org/repos/foo/bar/key`获取. 任何人都可以在任何仓库`Repository`运行`travis encrypt`, 使用**公钥**来加密参数.
因此, `foo/bar`的**加密后的值**可以被`Travis CI`使用`foo/bar`的**私钥**解密, 但这些**加密后的值**不能被任何人解密, 即使是加密这些值的人, 或者是仓库的拥有者, 任何人都不能解密.

# 用法
使用公钥加密某些东西的最简单方法是使用`Travis CLI`工具。 这个工具是用`Ruby`编写的，并以`gem`的形式发布。 首先，你需要安装gem：
```sh
# 译者追加
$ yum install -y gcc ruby ruby-devel # 安装gcc和ruby环境
$ gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/ # 改为国内gem源

# 原文
$ gem install travis
```

然后, 你可以使用`encrypt`命令去加密数据( 这个例子假设你的工作目录`pwd`是在仓库`Repository`下面, 如果不是, 请追加`-r 用户名/项目名` )
```sh
# 译者追加
$ travis encrypt 变量名="待加密的值"

# 原文
$ travis encrypt SOMEVAR="secretvalue"
```
这将输出一个字符串，如下所示：
```sh
# 译者追加
secure: "加密后的值"

# 原文
secure: ".... encrypted data ...."
```
现在你可以把它放在`.travis.yml`文件中.
你也可以跳过上面的步骤, 直接追加参数`--add`, 自动添加到`.travis.yml`文件中.
```sh
$ travis encrypt SOMEVAR="secretvalue" --add
```
请注意，环境变量的名称及其值都由`travis encrypt`生成的字符串进行编码。您必须将生成的`secure: ".... encrypted data ...."`添加到您的`.travis.yml`中。这样您的程序就可以使用环境变量`SOMEVAR`。

您可以使用多个加密变量, 添加到您的`.travis.yml`文件中。它们都可用于您的程序。

加密后的值可用于[secure environment variables in the build matrix](https://docs.travis-ci.com/user/environment-variables#Defining-Variables-in-.travis.yml) 和[notifications](https://docs.travis-ci.com/user/notifications).

```yml
# 译者追加
# .travis.yml
env:
  global:
  - secure: 执行travis encrypt得到的加密值
  - secure: 可以存在多个加密变量
```

## 关于转义某些符号的注意事项
当你使用`travis encrypt`去加密敏感数据时, 请注意`travis encrypt`将作为`bash`语句处理.
这意味着你正在加密的数据不能出现`bash`语法错误. 
不完整的数据会导致`bash`将错误`statement `语句存储到日志文件中, 这个日志文件会包含你的敏感数据. 并且是明文显示.

所以你需要对[特殊字符]((http://www.tldp.org/LDP/abs/html/special-chars.html)进行转义, 就像`{}`、`()`、`\`、`|`之类的特殊字符.

例如，当您想要将字符串`6&a(5!1Ab\`分配到`FOO`变量中，您需要执行：
```sh
$ travis encrypt "FOO=6\\&a\\(5\\!1Ab\\\\"
```
`travis`加密了字符串`FOO=6\&a\(5\!1Ab\\`,然后`bash`使用加密后的字符串在构建环境中`evaluate`.
你也可以这样做, 这和上面的加密语句等价.
```sh
$ travis encrypt 'FOO=6\&a\(5\!1AB\\'
```

## Notifications 例子
我们想要添加一个`campfire notifications`到`.travis.yml`文件中, 但是我们不想暴露我们的`API token`.
应该在`.travis.yml`中使用以下格式:
```yml
notifications:
  campfire:
    rooms: [subdomain]:[api token]@[room id]
```
举个例子, 比如`rooms: somedomain:abcxyz@14`
我们加密这个字符串`somedomain:abcxyz@14`
```sh
$ travis encrypt somedomain:abcxyz@14
```
会输出以下内容
```yml
Please add the following to your .travis.yml file:
  secure: "ABC5OwLpwB7L6Ca...."
```
我们将其加入到`.travis.yml`文件中
```yml
notifications:
  campfire:
    rooms:
      secure: "ABC5OwLpwB7L6Ca...."
```
这样就完成了

## 详细讨论

**安全变量系统**在配置`YAML`中采用`{ 'secure' => 'encrypted string' }`形式的值，并将其替换为解密后的字符串。

所以会发生如下变化
```yml
notifications:
  campfire:
    rooms:
      secure: "加密后的值"
# 变成
notifications:
  campfire:
    rooms: "解密后的值"
```

```yml
notifications:
  campfire:
    rooms:
      - secure: "加密后的值"
# 变成
notifications:
  campfire:
    rooms:
      - "解密后的值"
```
如果是环境变量, 则会发生如下变化
```yml
env:
  - secure: "加密后的值"
# 变成
env:
  - "解密后的值"
```

# 为您的仓库`Repository`获取公钥
你可以通过`Travis API`获取公钥, 使用`/repos/用户名/仓库名/key`或者`/repos/:id/key`来获取公钥
```
https://api.travis-ci.org/repos/travis-ci/travis-ci/key
```
你也可以使用`travis pubkey`命令行获取公钥.
如果你不在项目文件夹下, 则使用`travis pubkey -r 用户名/项目名`获取指定项目的公钥.

请注意, `Travis`在您的项目中使用`travis.slug`来确定端点是否存在（通过使用`git config --local travis.slug`来检查), 如果您重命名您的仓库或将您的仓库移动到另一个用户/组织，则可能需要对其进行更改。