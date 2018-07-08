---
title: Nginx日志配置
url: Nginx_log_configuration
tags:
  - Nginx
categories:
  - Nginx
date: 2018-07-08 18:42:00
---

# 日志输出配置
`nginx`的日志有两种
1. `error_log`: 记录服务器错误, 配置在**全局**范围
2. `access_log`: 记录每一次请求访问, 配置在`http`范围

<!-- more -->

日志配置
```
# 1. error.log日志配置
# error_log  日志存储位置  错误日志级别;
error_log  /var/log/nginx/error.log warn;

http {
    # 2. access.log日志配置
    # access_log  日志存储位置  日志格式名;
    access_log  /var/log/nginx/access.log  main;
    # log_format 日志格式名 [escape=default|json] 参数字符串;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
}
```

# 日志格式
语法: `log_format 日志格式名 [escape=default|json] string ...;`
日志格式可以携带一些内置的变量, 如`IP地址`之类的。
## HTTP请求变量
1. `arg_PARANERER`: 请求参数
2. `http_HEADER`: 请求头
3. `sent_HEADER`: 响应头

`Nginx`支持参数、请求头和响应头, 只要把字母转成小写, 横线转为下划线, 再加上`arg`、`http`或`sent`的前缀即可。
比如请求头的`User-Agent`, 对应的变量为`http_user_agent`。 

## 内置变量
[Nginx http core模块的变量](http://nginx.org/en/docs/http/ngx_http_core_module.html#variables)
这里只介绍`nginx.conf`中默认配置的变量
1. `$remote_addr`: 客户端地址, 如`192.168.1.7`
1. `$remote_user`: 随基本身份验证提供的用户名
1. `$time_local`: 通用日志格式的本地时间, 如`07/Jul/2018:15:33:14 +0800`
1. `$request`: 完整原始的请求行, 如`GET / HTTP/1.1`
1. `$status`: 响应状态码, 如`200`、`404`
1. `$body_bytes_sent`: 发送到客户端的字节数，不包括响应头

## 自定义变量
`set`只能配置在`server`、`location`和`if`中。
```
server {
    set $变量名 "变量值"
    location / {
        set $变量名 "变量值"
    }
}
```