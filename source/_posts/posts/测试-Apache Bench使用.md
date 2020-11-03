---
title: Apache Bench使用
url: How_to_use_Apache_Bench
tags:
  - Apache Bench
categories:
  - 测试
date: 2020-11-03 11:00:00
---

# 简介
`Apache Bench`简称`ab`工具, 是一款简单方便的测试工具.
安装方式
```shell script
yum -y install httpd-tools
apt -y install apache2-utils
``` 

# 使用
使用方式: `ab [options] [http[s]://]hostname[:port]/path`
常用选项

| 选项 | 说明 |
|:----:|:----:|
| `-n` | 总请求次数, 最小默认为`1` |
| `-c` | 并发次数, 最小默认为`1`, 且不能大于总请求次数. 例如, `10`个请求, `10`个并发，实际就是`1`人请求`1`次 |
| `-p` | `post` 参数文档路径（-p 和 -T 参数要配合使用）|
| `-T` | `header`头内容类型 |

# 分析结果
我们简单的对百度做个压测, `20`个用户同时发起请求, 总共请求`1000`次.
```shell script
ab -n 1000 -c 20 "https://www.baidu.com/s?wd=test"
```
结果马上就出来了, 我们主要看以下几个参数
```shell script
# 完成所有请求花费的时间
Time taken for tests:   5.058 seconds
# 吞吐率，指某个并发用户数下单位时间内处理的请求数
Requests per second:    197.72 [#/sec] (mean)
# 用户平均请求等待时间 = 完成所有请求花费的时间 / (总请求数 / 并发用户数)
Time per request:       101.155 [ms] (mean)
# 服务器平均请求处理时间 = 完成所有请求花费的时间 / 总请求数
Time per request:       5.058 [ms] (mean, across all concurrent requests)
```

# 常用例子
```shell script
# 1. get请求, 20个用户同时发起请求, 总共请求1000次
ab -n 1000 -c 20 -H "header1:value1" -H "header1:value1" "https://www.baidu.com/s?wd=test"
# 2. post请求, 将 post.txt 的内容作为请求参数发送出去
ab -n 1000 -c 10 -p post.txt -T "application/x-www-form-urlencoded" "https://www.baidu.com/s?wd=test"
ab -n 1000 -c 10 -p post.txt -T "application/json" "https://www.baidu.com/s?wd=test"
```