---
title: Nginx连接限制和访问控制
url: Nginx_connection_restrictions_and_access_control
tags:
  - Nginx
categories:
  - Nginx
date: 2018-08-08 16:45:00
---

# 前言
`Nginx`自带的模块支持对并发请求数进行限制, 还有对请求来源进行限制。可以用来防止`DDOS`攻击。
阅读本文须知道`nginx`的配置文件结构和语法。

# 连接限制 limit_conn_module
`limit_conn_module`: `TCP`连接频率限制, 一次`TCP`连接可以建立多次`HTTP`请求。
配置语法: 
| `limit_conn_module`语法 | 范围 | 说明 |
|:------:|:------:|:------:|
| `limit_conn_zone 标识 zone=空间名:空间大小;` | `http` | 用于声明一个存储空间 |
| `limit_conn 空间名 并发限制数;` | `http`、`server`或`location` | 用于限制某个存储空间的并发数量 |
| `limit_conn_log_level 日志等级;` | `http`、`server`或`location` | 当达到最大限制连接数后, 记录日志的等级 |
| `limit_conn_status 状态码;` | `http`、`server`或`location` | 当超过限制后，返回的响应状态码，默认是`503` |

`limit_conn_zone`会声明一个`zone`空间来记录连接状态, 才能限制数量。
`zone`是存储连接状态的空间, 以键值对存储, 通常以客户端地址`$binary_remote_addr`作为`key`来标识每一个连接。
当`zone`空间被耗尽，服务器将会对后续所有的请求返回`503(Service Temporarily Unavailable)` 错误。

# 请求限制 limit_req_mudule
`limit_req_mudule`: `HTTP`请求频率限制, 一次`TCP`连接可以建立多次`HTTP`请求。
 配置语法:
| `limit_req_mudule`语法 | 范围 | 说明 |
|:------:|:------:|:------:|
| `limit_req_zone key zone=空间名:空间大小 rate=每秒请求数;` | `http` |  用于声明一个存储空间 |
| `limit_req zone=空间名 [burst=队列数] [nodelay];` | `http`、`server`或`location` | 用于限制某个存储空间的并发数量 |
这里的`zone`也是用来存储连接的一个空间。

## burst和nodelay
`burst`和`nodelay`对并发请求设置了一个缓冲区和是否延迟处理的策略。
先假设有如下`zone`配置。
```
http {
    limit_req_zone $binan_remote_addr zone=req_zone:1m rate=10r/s;
}
```

情况1: `limit_req zone=req_zone;`
1. 第`1`秒发送`10`个请求, 正常响应。
1. 第`1`秒发送`13`个请求, 前`10`个请求正常响应, 后`3`个请求返回`503(Service Temporarily Unavailable)`。

不加`brust`和`nodelay`的情况下, `rate=10r/s`每秒只能执行`10`次请求, 多的直接返回`503`错误。

--------------

情况2: `limit_req zone=req_zone brust=5;`
1. 第`1`秒发送`10`个请求, 正常响应。
1. 第`1`秒发送`13`个请求, 前`10`个请求正常响应, 后`3`个请求放入`brust`等待响应。
1. 第`1`秒发送`20`个请求, 前`10`个请求正常响应, 后`5`个请求放入`brust`等待响应, 最后`5`个请求返回`503(Service Temporarily Unavailable)`, 第`2`秒执行`brust`中的`5`个请求。
1. 第`1`秒发送`20`个请求, 前`10`个请求正常响应, 后`5`个请求放入`brust`等待响应, 最后`5`个请求返回`503(Service Temporarily Unavailable)`, 第`2`秒发送`6`个请求, 执行`brust`中的`5`个请求, 将`5`个请求放入`brust`等待响应, 剩下的`1`个请求返回`503(Service Temporarily Unavailable)`。

加`brust=5`不加`nodelay`的情况下, 有一个容量为`5`的缓冲区, `rate=10r/s`每秒只能执行`10`次请求, 多的放到缓冲区中, 如果缓冲区满了, 就直接返回`503`错误。而缓冲区在下一个时间段会取出请求进行响应, 如果还有请求进来, 则继续放缓冲区, 多的就返回`503`错误。

--------------

情况3: `limit_req zone=req_zone brust=5 nodelay;`
1. 第`1`秒发送`10`个请求, 正常响应。
1. 第`1`秒发送`13`个请求, `13`个请求正常响应。
1. 第`1`秒发送`20`个请求, 前`15`个请求正常响应, 后`5`个请求返回`503(Service Temporarily Unavailable)`。
1. 第`1`秒发送`20`个请求, 前`15`个请求正常响应, 后`5`个请求返回`503(Service Temporarily Unavailable)`, 第`2`秒发送`6`个请求, 正常响应。

加`brust=5`和`nodelay`的情况下, 有一个容量为`5`的缓冲区, `rate=10r/s`每秒能执行`15`次请求, `15=10+5`。多的直接返回`503`错误。 

--------------

#  基于IP的访问控制
`http_access_module`: 基于`IP`的访问控制, 通过代理可以绕过限制, 防君子不防小人。

| `http_access_module`语法 | 范围 | 说明 |
|:------:|:------:|:------:|
| `allow IP地址 \| CIDR网段 \| unix: \| all;` | `http`、`server`、`location`和`limit_except` | 允许`IP地址`、`CIDR`格式的网段、`unix`套接字或所有来源访问 |
| `deny IP地址 \| CIDR网段 \| unix: \| all;` | `http`、`server`、`location`和`limit_except` | 禁止`IP地址`、`CIDR`格式的网段、`unix`套接字或所有来源访问 |

`allow `和`deny`会按照顺序, 从上往下, 找到第一个匹配规则, 判断是否允许访问, 所以一般把`all`放最后。
```
location / {
    deny  192.168.1.1;
    allow 192.168.1.0/24;
    allow 10.1.1.0/16;
    allow 2001:0db8::/32;
    deny  all;
}
```

#  基于用户密码的访问控制
`http_auth_basic_module`: 基于文件匹配用户密码的登录

| `http_auth_basic_module`语法 | 范围 | 说明 |
|:------:|:------:|:------:|
| `auth_basic 请输入你的帐号密码 \| off;` | `http`、`server`、`location`和`limit_except` | 显示用户登录提示(有些浏览器不显示提示) |
| `auth_basic_user_file 存储帐号密码的文件路径;` | `http`、`server`、`location`和`limit_except` | 从文件中匹配帐号密码 |

密码文件可以通过`htpasswd`生成, `htpasswd`需要安装`yum install -y httpd-tools`。
```sh
# -c 创建新文件, -b在参数中直接输入密码
$ htpasswd -bc /etc/nginx/conf.d/passwd user1 pw1
Adding password for user user1
$ htpasswd -b /etc/nginx/conf.d/passwd user2 pw2
Adding password for user user2
$ cat /etc/nginx/conf.d/passwd 
user1:$apr1$7v/m0.IF$2kpM9NVVxbAv.jSUvUQr01
user2:$apr1$XmoO4Zzy$Df76U0Gzxbd7.5vXE0UsE0
```

# 参考资料
1. [limit_conn_module](http://nginx.org/en/docs/http/ngx_http_limit_conn_module.html)
1. [limit_req_mudule](http://nginx.org/en/docs/http/ngx_http_limit_req_module.html)
1. [http_access_module](http://nginx.org/en/docs/http/ngx_http_access_module.html)
1. [http_auth_basic_module](http://nginx.org/cn/docs/http/ngx_http_auth_basic_module.html)