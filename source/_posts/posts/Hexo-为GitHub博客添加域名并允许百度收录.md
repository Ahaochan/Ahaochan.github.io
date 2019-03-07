---
title: 为GitHub博客添加域名并允许百度收录
url: Add_domain_and_allow_Baidu
tags: 
  - Travis-CI
  - Hexo
categories:
  - Hexo
date: 2019-03-08 00:21:00
---
# 前言
之前写了一篇文章, [TravisCI 加密配置文件并自动部署 Hexo](https://ahao.moe/posts/TravisCI_encrypts_configuration_files_and_automatically_deploys_Hexo.html)
迫于囊中羞涩, 没有域名, 于是也绕不过`GitHub`对`Baidu`的封锁.
现在买了个域名`ahao.moe`, 终于让`Baidu`访问到我的博客了.

<!-- more -->

# GoDaddy 购买域名
注意, 有些域名是不能备案的, 比如`moe`域名.

# 为 GitHub 博客添加 DNS 解析

## 更换 DNS 解析服务器
因为阿里云提供了免费的`SSL`证书, 所以使用阿里云做域名解析.
在`GoDaddy`配置阿里云的`DNS`解析服务器.
```text
ns1.alidns.com
ns2.alidns.com
```

## 阿里云添加 A 记录
然后回到阿里云, 在[管理界面](https://dns.console.aliyun.com/#/dns/domainList)新增一个域名`ahao.moe`.
进入[`ahao.moe`解析设置](https://dns.console.aliyun.com/#/dns/setting/ahao.moe)
```text
https://dns.console.aliyun.com/#/dns/setting/ahao.moe
```

先去看下[GitHub文档](https://help.github.com/en/articles/setting-up-an-apex-domain#configuring-a-records-with-your-dns-provider)
根据这几个`IP`地址, 设置`A记录`, 这里列举要修改的值, 其他没列出的默认即可.

| 记录类型 | 主机记录 | 解析线路 | 记录值 |
|:-------:|:-------:|:-------:|:------:|
| `A` | `@` | 默认 | `185.199.108.153` |
| `A` | `@` | 默认 | `185.199.109.153` |
| `A` | `@` | 默认 | `185.199.110.153` |
| `A` | `@` | 默认 | `185.199.111.153` | 

## 阿里云添加 SSL 证书
进入[云盾证书服务](https://common-buy.aliyun.com/?commodityCode=cas#/buy), 选择`免费型DV SSL`.
之后填上自己的域名`ahao.moe`即可, 注意此证书只能针对一个域名, 不包括子域名.

然后我们回到阿里云[`ahao.moe`解析设置](https://dns.console.aliyun.com/#/dns/setting/ahao.moe)
```text
https://dns.console.aliyun.com/#/dns/setting/ahao.moe
```
添加验证的记录

| 记录类型 | 主机记录 | 解析线路 | 记录值 |
|:-------:|:-------:|:-------:|:------:|
| `TXT` | `_dnsauth` | 默认 | `123456789abcdefg` |

## GitHub 博客项目配置
进入`GitHub`的[博客项目](https://github.com/Ahaochan/Ahaochan.github.io). 
在`Setting`里的`GitHub Pages`标签, 看到`Custom domain`, 在里面配置`ahao.moe`, 并勾选`Enforce HTTPS`.

同时, 我们还要在[`source`](https://github.com/Ahaochan/Ahaochan.github.io/blob/source/source)添加一个[`CNAME`](https://github.com/Ahaochan/Ahaochan.github.io/blob/source/source/CNAME)文件.
```text
ahao.moe
```
至此, 等待几分钟, 就可以在`ahao.moe`访问到自己的`GitHub`博客了.

# 部署到 Coding Pages

## 腾讯云项目配置
`Coding Pages`现在已经迁移到[腾讯云开发者平台](https://dev.tencent.com/u/Ahaochan)了
我们先[新建](https://dev.tencent.com/user/projects/create)一个`Ahaochan.coding.me`的项目.

和`GitHub`一样, 我们也要指定`ahao.moe`.
在`https://dev.tencent.com/u/Ahaochan/p/Ahaochan.coding.me/git/pages/settings`里绑定新域名`ahao.moe`
然后在阿里云配置`A`记录即可, 注意`IP`地址我们需要自己手动查询, 还有解析线路要改为**百度**.
```bash
# 1. windows 查询 IP
nslookup Ahaochan.coding.me
# 2. linux 查询 IP
host -a Ahaochan.coding.me
```

| 记录类型 | 主机记录 | 解析线路 | 记录值 |
|:-------:|:-------:|:-------:|:------:|
| `A` | `@` | 百度 | `128.1.133.223` |
| `A` | `@` | 百度 | `128.1.138.212` |
| `A` | `@` | 百度 | `128.1.138.154` |
| `A` | `@` | 百度 | `128.1.138.163` |
| `A` | `@` | 百度 | `128.1.138.9` |

## Travis CI 配置
注意, 此时`Ahaochan.coding.me`仍然是一个空项目, 我们需要在`Travis CI`中配置`push`到腾讯云平台.

先在`https://dev.tencent.com/user/account/setting/tokens/new`新建一个`Token`令牌, 配置所需权限.
和`GitHub`一样, 在`Travis CI`的`Environment Variables`配置加密变量`CODING_TOKEN`.
之后的步骤就和`GitHub`一样了, 参考我开头的那篇文章.
这里放下`next.yml`和`.travis.yml`
```yaml
# next.yml
deploy:
  - type: git
    repo: https://REPO_TOKEN@github.com/Ahaochan/Ahaochan.github.io.git
    branch: master
  - type: git
    repo: https://Ahaochan:CODING_TOKEN@git.dev.tencent.com/Ahaochan/Ahaochan.coding.me.git
    branch: master
    
# .travis.yml
before_install:
# - 解密 next.yml
- sed -i "s/REPO_TOKEN/${REPO_TOKEN}/" source/_data/next.yml
- sed -i "s/CODING_TOKEN/${CODING_TOKEN}/" source/_data/next.yml
```

# 添加百度和谷歌收录

## 谷歌收录
进入谷歌站长工具, 点击左边的**添加资源**.
```text
https://search.google.com/search-console?resource_id=sc-domain%3Aahao.moe)
```
选择**添加网域**, 输入`ahao.moe`. 
谷歌会提示你将`google-site-verification=123456789`这段代码在`DNS`配置为`TXT`记录.
我们回到阿里云[`ahao.moe`解析设置](https://dns.console.aliyun.com/#/dns/setting/ahao.moe)
```text
https://dns.console.aliyun.com/#/dns/setting/ahao.moe
```

| 记录类型 | 主机记录 | 解析线路 | 记录值 |
|:-------:|:-------:|:-------:|:------:|
| `TXT` | `@` | 默认 | `google-site-verification=123456789` |

然后为`hexo`添加`hexo-generator-sitemap`插件([.travis.yml#L30](https://github.com/Ahaochan/Ahaochan.github.io/blob/source/.travis.yml#L30)), 它会生成一个`sitemap.xml`.
回到谷歌站长工具, 添加一个`sitemap`地址`https://ahao.moe/sitemap.xml`.
```text
https://search.google.com/search-console/sitemaps?resource_id=sc-domain%3Aahao.moe
```

## 百度收录
进入[百度站点管理](https://ziyuan.baidu.com/site/index), 添加`https://ahao.moe`, 选择`CNAME`验证.

| 记录类型 | 主机记录 | 解析线路 | 记录值 |
|:-------:|:-------:|:-------:|:------:|
| `CNAME` | `abcdefg` | 默认 | `ziyuan.baidu.com` |

同理, 为`hexo`添加`hexo-generator-baidu-sitemap`插件([.travis.yml#L31](https://github.com/Ahaochan/Ahaochan.github.io/blob/source/.travis.yml#L31)), 它会生成一个`baidusitemap.xml`.
回到百度站长工具, 添加一个`sitemap`地址`https://ahao.moe/baidusitemap.xml`.
```text
https://ziyuan.baidu.com/linksubmit/index?site=https%3A%2F%2Fahao.moe/
```

因为之前在阿里云`DNS`解析将百度的爬虫指向了`Coding Me`, 所以绕开了`GitHub`的封锁.