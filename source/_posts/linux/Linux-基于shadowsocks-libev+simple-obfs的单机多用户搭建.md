---
title: 基于shadowsocks-libev+simple-obfs的单机多用户搭建
url: multi_user_of_shadowsocks_libev
tags:
  - Linux
  - shadowsocks
categories:
  - Linux
date: 2018-12-11 20:11:33
---
# 前言
你好啊，感谢你阅读本文。
`18`年的时候，我发布了这篇文章，介绍了如何部署一套我当时以为安全的流量混淆和多用户限流工具。

转眼到了`22`年，现在我遇到了几个问题
1. 我的`Linux`虚拟机迫切需要使用科学上网，但是当时这篇文章里没有介绍关于`Linux Client`的使用。
2. 我的`shadowsocks-libev`版本过于老旧，不知道是否会有安全漏洞，需要更新。
3. `simple-obfs`混淆插件已经停止维护，拙劣的混淆可能会暴露自己。

随后我在搜索引擎上找到了一篇文章，[如何部署一台抗封锁的`Shadowsocks-libev`服务器](https://gfw.report/blog/ss_tutorial/zh/) 。
**PS：在写这篇文章的时候，根据上文进行配置，第二天就被封`IP`了，建议大家还是开上`simple obfs`等混淆插件，不要裸奔。**

本文基于`Ubuntu 18.04`在虚拟机中进行操作, 并于`VPS`上测试成功。

<!-- more -->

# 允许root远程登录（仅限虚拟机，请勿用于生产环境）
建议使用`root`避免各种权限问题。
实际使用时应该登录普通用户后`sudo -s`切换到`root`用户。
```sh
# 设置root用户的密码为root，并允许root用户远程登录
sudo passwd root
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo service sshd restart
```

# shadowsocks-libev 服务端安装配置
服务端使用[`shadowsocks-libev`](https://github.com/shadowsocks/shadowsocks-libev)
[配置文件官方文档](https://github.com/shadowsocks/shadowsocks-libev/blob/master/doc/shadowsocks-libev.asciidoc#config-file)
```sh
# 1. 安装 shadowsocks-libev
apt update -y
apt install shadowsocks-libev -y # 安装或升级
dpkg -l | grep shadowsocks       # 查看版本号
```
**建议使用`openssl rand -base64 16`来生成强密码**

## 单用户配置
```bash
# 1. 添加单用户配置文件
vim /etc/shadowsocks-libev/config.json
{
    "server":["::0","0.0.0.0"],
    "server_port": 8452,
    "method": "chacha20-ietf-poly1305",
    "password": "Zqx465gr5snppXlYWMEKZQ==",
    "mode": "tcp_and_udp",
    "fast_open": false
}

# 2. 启动服务端
ss-server
systemctl start   shadowsocks-libev.service # 启动
systemctl enable  shadowsocks-libev.service # 开机自启
systemctl status  shadowsocks-libev.service # 查看状态
systemctl restart shadowsocks-libev.service # 重启
```

## 多用户配置
```bash
# 1. 添加多用户配置文件
vim /etc/shadowsocks-libev/config.json
{
  "server":["::0","0.0.0.0"],
  "port_password": {
    "8452": "Zqx465gr5snppXlYWMEKZQ=="
  },
  "method": "chacha20-ietf-poly1305",
  "mode": "tcp_and_udp",
  "fast_open": false
}
# 2. 启动服务端
ss-manager -c /etc/shadowsocks-libev/config.json
```

## 测试使用
客户端连接上, 然后开启全局模式, 执行如下操作
1. 访问`www.baidu.com`, 访问成功
2. 关闭服务端, 访问`www.baidu.com`, 访问失败

则说明`shadowsocks-libev`已经成功配置。

# 配置 simple-obfs 混淆插件
[`simple-obfs`](https://github.com/shadowsocks/simple-obfs) 是一个简单的混淆插件, 可以伪装成 `http` 流量。

## 服务端配置
```bash
# 1. 从 Github 下载源码进行编译
cd /opt
apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake -y
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh && ./configure && make && make install

# 2. 添加配置文件, 添加 plugin 和 plugin_opts 参数
vim /etc/shadowsocks-libev/config.json
{
  ...省略其他配置
  "plugin":"obfs-server",
  "plugin_opts":"obfs=http;failover=apps.bdimg.com"
}

# 3. 重启 shadowsocks-libev
systemctl restart shadowsocks-libev.service # 重启
```

## 客户端配置
`win`: https://github.com/shadowsocks/simple-obfs/releases
复制到客户端同一目录下, 并配置以下参数
插件程序: `obfs-local`
插件选项: `obfs=http;obfs-host=apps.bdimg.com`

`android`: https://github.com/shadowsocks/simple-obfs-android/releases

没有苹果设备, 不做研究。

# 配置 v2ray 混淆插件（暂未落地）
地址：https://github.com/shadowsocks/v2ray-plugin

# 流量统计（暂未落地）
~~[shadowsocks-manager](https://github.com/shadowsocks/shadowsocks-manager)要部署邮箱才行, 放弃.~~
~~[shadowsocks-hub](https://github.com/shadowsocks/shadowsocks-hub)依赖于[shadowsocks-restful-api](https://github.com/shadowsocks/shadowsocks-restful-api), 也是依赖于原生的`manager API`接口.(虽然我跑`docker`失败了)~~

`shadowsocks-libev`提供了原生的`manager API`接口, 可以统计流量使用情况.接口文档在这里[protocol](https://github.com/shadowsocks/shadowsocks-libev/blob/master/doc/ss-manager.asciidoc#protocol).

# 优化
## 开启BBR
`BBR`需要内核`4.9`以上.
```sh
# 1. 查看内核
uname -r

# 2. 启动BBR
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 3. 如果以下两条命令都有bbr说明开启成功
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr
```

## 部署一个正常的网站到80端口
也可以用来部署一些自己的`web`应用
```sh
apt install nginx -y
nginx reload
```

## 备用端口
```bash
# 配置端口转发
iptables -t nat -A PREROUTING -p tcp --dport 18452 -j REDIRECT --to-port 8452
iptables -t nat -A PREROUTING -p udp --dport 18452 -j REDIRECT --to-port 8452
iptables -t nat -L PREROUTING -nv --line-number # 查看状态
# iptables -t nat -D PREROUTING 1 # 删除num为1的规则 
```

## 开启防火墙
```bash
apt update && sudo apt install -y ufw
ufw allow ssh
ufw allow 8452 # 这里配置堆外暴露的端口号
ufw allow 80
ufw enable
ufw status # 查看状态
```

## 封禁恶意访问IP
使用 `fail2ban`
```sh
# 1. 安装 fail2ban
apt install fail2ban -y

# 2. ssh 安全规则
vim /etc/fail2ban/jail.d/ssh.conf
[ssh-iptables]
enabled = true
filter     = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath = /var/log/secure

# 3. 重启服务
service fail2ban restart
```

# 结语
吐槽下, `libev`关于`config.json`的配置没有一个完整的`example`, 也没有`wiki`页, 还是我翻了下`issue`才发现了文档位置. 并且有些参数配置在`config.json`还没有对应位置.

开发者觉得我弄出来能用就好了, 不懂就去看源码全在那. 
小白则是素质三连, 怎么用不了了, 报错了, 打不开怎么办.

开源不易, 珍惜每个用心写文档的开发者和每个用心写复现步骤的小白.
