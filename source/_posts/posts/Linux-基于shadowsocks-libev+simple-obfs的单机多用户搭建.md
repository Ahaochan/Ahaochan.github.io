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
基于[shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev)+[simple-obfs](https://github.com/shadowsocks/simple-obfs)的单机多用户搭建。
本文基于`Ubuntu 18.04`在虚拟机中进行操作, 并于`VPS`上测试成功。

<!-- more -->

# 允许root远程登录
使用`root`避免各种权限问题, 实际使用时应登录普通用户后`sudo -s`切换到`root`用户。
```sh
sudo passwd root
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo service sshd restart
```

# 服务端配置
服务端使用[shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev), 其他项目似乎都好久没更新了。
[配置文件官方文档](https://github.com/shadowsocks/shadowsocks-libev/blob/master/doc/shadowsocks-libev.asciidoc#config-file)
```sh
# 1. 安装 shadowsocks-libev
sudo apt update -y
sudo apt install shadowsocks-libev -y

# 2. 添加配置文件
sudo mkdir /opt/config
sudo vim /opt/config/manager.json
{
  "port_password": {
    "443": "12345",
#    "端口": "密码"
  },
  "timeout": 300,
  "method": "aes-256-gcm"
}

# 3. 启动
sudo ss-manager -c /opt/config/manager.json
```
客户端连接上, 然后开启全局模式, 执行如下操作
1. 访问`www.baidu.com`, 访问成功
2. 关闭服务端, 访问`www.baidu.com`, 访问失败
则说明`shadowsocks-libev`已经成功配置。

# 配置 simple-obfs 混淆插件

## 服务端配置
[simple-obfs](https://github.com/shadowsocks/simple-obfs) 是一个简单的混淆插件, 可以伪装成 `http` 流量。
```sh
# 1. 从 Github 下载源码进行编译
cd /opt
apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake -y
git clone https://github.com/shadowsocks/simple-obfs.git
cd simple-obfs
git submodule update --init --recursive
./autogen.sh
./configure && make
sudo make install

# 2. 添加配置文件, 添加 plugin 和 plugin_opts 参数
sudo vim /opt/config/manager.json
{
  "port_password": {
    "443": "12345"
#    "端口": "密码"
  },
  "timeout": 300,
  "method": "aes-256-gcm",
  "plugin":"obfs-server",
  "plugin_opts":"obfs=http;failover=apps.bdimg.com"
}

# 3. 重启 shadowsocks-libev
systemctl restart shadowsocks-libev
```

## 客户端配置
`win`: https://github.com/shadowsocks/simple-obfs/releases
复制到客户端同一目录下, 并配置以下参数
插件程序: `obfs-local`
插件选项: `obfs=http`
插件参数: `obfs-host=apps.bdimg.com`

`android`: https://github.com/shadowsocks/simple-obfs-android/releases

没有苹果设备, 不做研究。

# 流量统计
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
lsmod | grep bbr
```

## 部署一个正常的网站到80端口
也可以用来部署一些自己的`web`应用
```sh
apt install apache2 -y
service apache2 start
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

# 3. apache 安全规则
vim /etc/fail2ban/jail.d/apache.conf
[apache-tcpwrapper]
enabled = true
filter     = apache-auth
action   = hostdeny
logpath = /var/log/httpd/error_log

[apache-badbots]
enabled = true
filter     = apache-badbots
action   = iptables-multiport[name=BadBots, pory="http,https"]
logpath = /var/log/httpd/access_log

[apache-shorewall]
enabled = true
filter     = apache-noscript
action   = shorewall
logpath = /var/log/httpd/error_log

# 4. 重启服务
service fail2ban restart
```

# 结语
吐槽下, `libev`关于`config.json`的配置没有一个完整的`example`, 也没有`wiki`页, 还是我翻了下`issue`才发现了文档位置. 并且有些参数配置在`config.json`还没有对应位置.

开发者觉得我弄出来能用就好了, 不懂就去看源码全在那. 
小白则是素质三连, 怎么用不了了, 报错了, 打不开怎么办.

开源不易, 珍惜每个用心写文档的开发者和每个用心写复现步骤的小白.
