---
title: Nginx的location配置
url: Nginx_location_configuration
tags:
  - Nginx
categories:
  - Nginx
date: 2018-07-08 18:42:00
---

# 前言
`location`匹配到的`url`可以执行特定的操作, 比如拦截, 转发。

<!-- more -->

# url匹配
语法: 
`location [=|~|~*|^~|@] uri { 配置 }`
`location`的`url`匹配遵循最长匹配原则。

| modifier | 说明 |
|:---:|:----:|
| =  | 精确匹配, 和这个`url`完全一样的会被匹配到 |
| ^~ | 前缀匹配, 以这个`url`开头都会被匹配到 |
| ~  | 表示执行一个正则匹配，区分大小写 |
| ~* | 表示执行一个正则匹配，不区分大小写 |
|    | 什么都没有, 就说明以这个`uri`开头的都会被匹配到 |
| @  | "@" 定义一个命名的 location，使用在内部定向时使用，例如 error_page, try_files |


匹配步骤:
1. 将所有的非正则匹配规则放入**排序三叉树**中, 正则匹配规则放入一个顺序队列(按配置文件书写顺序排序)中。
1. 在三叉树中匹配`url`。如果匹配到`location =`就停止搜索。如果是前缀匹配`location ^~`或默认规则`location `则找到最长匹配。
2. 再在正则匹配规则队列中匹配`url`, 如果有, 则使用这个正则匹配, 没有则使用三叉树中找到的匹配规则。

# 示例
上面说这么多, 还是得看例子来理解, 等看完例子再回过头去看上面的详细说明。
[nginx-location-match-visible](https://detailyang.github.io/nginx-location-match-visible/)提供了一个可视化的匹配步骤。
将下面规则复制到其中, 即可查看匹配步骤和匹配结果。

## = 和 none 的区别
匹配规则
```text
location / {}      # A
location = / {}    # B
location = /123 {} # C
```
测试用例
```text
/      # 匹配B
/123   # 匹配C
```

##　~ 正则(区分大小写)
匹配规则
```text
location / {}                           # A
location ~ \.(gif|jpg|png|js|css)$ {}   # B
location ~ \.(GIF|JPG|PNG|JS|CSS)$ {}   # C
```
测试用例
```text
/       # 匹配A
/a.jpg  # 匹配B
/a.JPG  # 匹配C
```

## ~ 正则(不区分大小写)
匹配规则
```text
location / {}                            # A
location ~* \.(gif|jpg|png|js|css)$ {}   # B
```
测试用例
```text
/       # 匹配A
/a.jpg  # 匹配B
/a.JPG  # 匹配B, 注意!! nginx-location-match-visible 有误! 实际是匹配到B的!
```

## @
`@`常用于内部跳转
```text
location ~* \.(gif|jpg|png|js|css)$ {
    error_page 404 @img_err
}
location @img_err {
    # 规则
}
```

## 复合
匹配规则
```text
location = / {}                         # A
location = /login {}                    # B
location ^~ /static/ {}                 # C
location ~ \.(gif|jpg|png|js|css)$ {}   # D
location ~* \.png$ {}                   # E
location / {}                           # F
```
测试用例
```text
/                   # 匹配F
/login              # 匹配B
/static             # 匹配F
/static/a           # 匹配C
/test.png           # 匹配D
/static.png         # 匹配D
/test.PNG           # 匹配E, 注意!! nginx-location-match-visible 有误! 实际是匹配到E的!
/static/a.png       # 匹配C
/static/a.gif       # 匹配C
```

# 最佳实践
一般把`Nginx`作为负载均衡服务器, 静态资源可以存在`Nginx`服务器。
负载均衡配置本文不详细讲, 简单的说就像是买卖房屋的中介, 给你(客户端)介绍一个好的(连接的上的)房屋(服务端)。
```
http {
    upstream tomcats {
        server 192.168.0.100:8080;
        server 192.168.0.101:8080;
        server example.com:8080;
    }

    server {
        # 1. 静态文件处理 参照另一篇文章, 这里简单的列举一下
        location ^~ /static/ {
            root /webroot/static/;
        }
        location ~* \.(gif|jpg|jpeg|png|css|js|ico)$ {
            root /webroot/res/;
        }
         
        # 2. 负载均衡, 首页单独处理, 加快速度
        location = / {
            proxy_pass http://tomcats/index
        }
        location / {
            proxy_pass http://tomcats
        }
    }
}
```