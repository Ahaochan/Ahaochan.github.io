---
title: Nginx配置多个域名
url: Nginx_configures_multiple_server_name
tags:
  - Nginx
categories:
  - Nginx
date: 2018-12-03 16:25:00
---

# 前言
解决`Cookie`跨域请求的时候, 发现这样一个[网站scripts.cmbuckley.co.uk](https://scripts.cmbuckley.co.uk/cookies.php), 它拥有无限的子域名, 比如`a.scripts.cmbuckley.co.uk`、`b.scripts.cmbuckley.co.uk`、`hhhhh.scripts.cmbuckley.co.uk`.

<!-- more -->

# 实现思路
这里用本地环境测试, 在虚拟机搭建一个`Nginx`服务器.
`Nginx`的`server_name`在`server`块里面配置, 用于配置基于名称的虚拟主机。
比如`/etc/nginx/conf.d/default.conf`中配置的就是`localhost`.
```
server {
    listen       80;
    server_name  localhost;
    ...
}
```
我们修改`hosts`, 把`localhost`指向服务器的`IP`, 然后访问`http://localhost:80`.
```
192.168.94.189 localhost
```
浏览器发送的请求头会携带一个`Host`参数`localhost`, `Nginx`根据这个`Host`将请求分发到名为`localhost`的`server`进行处理。
如果有多个`server`, 则会按从上到下的顺序一个个匹配, 如果都匹配不到, 则默认交给第一个请求, 或者也可以指定`default_server`.

# 各种server_name
`server_name`支持精确匹配, 支持通配符匹配, 支持正则匹配
```
server_name  domain.com  www.domain.com;
server_name  *.domain.com;
server_name  domain.*;
server_name  ~^(?.+)\.domain\.com$;
```
很明显, 上面提到的无限子域名的网站, 是通过`*.domain.com`的方式实现的.
`Nginx`配好后, 记得`hosts`文件也要改, 手头没有域名, 就只能改`hosts`了.

# 参考资料
- [关于Nginx的server_name](http://blog.51cto.com/onlyzq/535279)