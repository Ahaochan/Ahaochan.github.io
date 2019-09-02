---
title: 精通ES的单节点和集群安装
url: ES_single_and_cluster_installation
tags:
  - ElasticSearch
categories:
  - ElasticSearch
date: 2019-09-02 22:28:00
---

# 前言
之前有用到搜索引擎`Solr`, 当时我想上`ElasticSearch`的, 然后趁机学习下, 可是`Leader`要用`Solr`没说原因.
现在想来, 应该机器资源不够.
结果`Solr`的文章还没出来, 反而先出了`ElasticSearch`的.
于是现在就开始学习如何精通`ElasticSearch`, 工欲善其事必先利其器, 先来精通一下如何安装.

# 选择 ES 版本
[https://www.elastic.co/cn/support/matrix](https://www.elastic.co/cn/support/matrix)

| 版本 | `JDK8` | `JDK9` | `JDK10` |
|:----:|:------:|:------:|:-------:|
| `5.6.x` | ✔ | ✖ | ✖ |
| `6.0.x` | ✔ | ✖ | ✖ |
| `6.1.x` | ✔ | ✖ | ✖ |
| `6.2.x` | ✔ | ✔ | ✖ |
| `6.3.x` | ✔ | ✖ | ✔ |

从官方提供的表格, 可以看到`6.x`开始, 官方将`JDK`打包到`ElasticSearch`里面了.
并且, `6.2.x`开始同时支持`JDK8`和`JDK9`, `6.3.x`同时支持`JDK8`和`JDK10`, 支持的版本号一路突飞猛进.
目前生产环境最新也才`JDK8`, 所以我这里选择了最新的`5.x`版本`5.6.3`.

# 安装 ES 并在单节点启动
直接在[官网下载](https://www.elastic.co/downloads/elasticsearch)就好了
```bash
cd /opt
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.3.tar.gz
tar zxvf elasticsearch-5.6.3.tar.gz
mv elasticsearch-5.6.3 elasticsearch
cd elasticsearch/
./bin/elasticsearch
# ./bin/elasticsearch -d # 后台启动
```
然后访问`http://虚拟机IP:9200`.
一般这样就可以启动了, 但是我在虚拟机里面启动的, 所以出现了各种各样的问题.

## 修改 jvm 内存
> OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x0000000085330000, 2060255232, 0) failed; error='Cannot allocate memory' (errno=12)
> #
> # There is insufficient memory for the Java Runtime Environment to continue.
> # Native memory allocation (mmap) failed to map 2060255232 bytes for committing reserved memory.
> # An error report file with more information is saved as:
> # /opt/elasticsearch/hs_err_pid3215.log

可以看到, `JVM`内存不足了, 有两个建议
1. 给虚拟机加内存.
1. 修改`-Xms`和`-Xmx`配置, 改小一点, 如`512m`.

```bash
vim config/jvm.options

# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space
-Xms512m
-Xmx512m
```
如果改了`JVM`配置还是启动不了, 就直接加虚拟机内存吧. 我后来是加了内存.

## 禁止 root 用户启动
> Caused by: java.lang.RuntimeException: can not run elasticsearch as root
> 	at org.elasticsearch.bootstrap.Bootstrap.initializeNatives(Bootstrap.java:106) ~[elasticsearch-5.6.3.jar:5.6.3]
> 	at org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:195) ~[elasticsearch-5.6.3.jar:5.6.3]
> 	at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:342) ~[elasticsearch-5.6.3.jar:5.6.3]
> 	at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:132) ~[elasticsearch-5.6.3.jar:5.6.3]

那就新建一个`es`用户就好了
```bash
# 添加一个 es 用户组
groupadd es
# 添加一个 es 用户
useradd es -g es -p es -m
# 修改 elasticsearch 目录的权限
chown -R es:es /opt/elasticsearch
# 切换到 es 用户, 并启动应用
sudo su es
./bin/elasticsearch
```

## 虚拟内存区域太低 vm.max_map_count
> ERROR: [1] bootstrap checks failed
> [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

`vm.max_map_count`是`linux`系统的一个配置, 限制一个进程拥有的`VMA`(虚拟内存区域)的数量.
不懂也没关系. 这是运维做的事, 咱们只要能跑起来就好了.
临时解决方案(重启失效)执行以下命令:
```bash
sysctl -w vm.max_map_count=262144
```
永久配置当然是写入文件
```bash
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p
```

## 绑定 IP 允许局域网访问
启动起来后, 发现浏览器访问`http://虚拟机IP:9200`失败.
然后在虚拟机执行以下命令
```bash
curl http://127.0.0.1:9200
# {
#   "name" : "oYRDx50",
#   "cluster_name" : "elasticsearch",
#   "cluster_uuid" : "kXiVFPyvSdO-_s3zY06L3A",
#   "version" : {
#     "number" : "5.6.3",
#     "build_hash" : "1a2f265",
#     "build_date" : "2017-10-06T20:33:39.012Z",
#     "build_snapshot" : false,
#     "lucene_version" : "6.6.1"
#   },
#   "tagline" : "You Know, for Search"
# }

curl http://虚拟机IP:9200
# curl: (7) Failed to connect to 虚拟机IP port 9200: 拒绝连接
```
修改配置文件, 注意这里是危险操作, 生产环境不能绑定`0.0.0.0`, 绑定内网`IP`就好了.
```bash
echo "network.host: 0.0.0.0" >> config/elasticsearch.yml
```

# 安装可视化插件 elasticsearch-head
在安装`ElasticSearch`集群前, 先来安装一下这个可视化插件.
[`elasticsearch-head`](https://github.com/mobz/elasticsearch-head)提供了一个可视化的操作页面.
不同`ElasticSearch`版本有不同的安装方法. 
在`5.0.0`后, `ElasticSearch`不再支持直接安装`elasticsearch-head`插件, 所以只能单独启动`elasticsearch-head`服务器.
> https://github.com/mobz/elasticsearch-head/issues/262#issuecomment-228927247

因为要安装`npm`, 我就懒得弄了, 直接跑`docker`搞定.
```bash
docker run -p 9100:9100 -d mobz/elasticsearch-head:5
```
然后修改`config/elasticsearch.yml`, 追加`CORS`跨域配置.
```yml
http.cors.enabled: true
http.cors.allow-origin: "*"
```
然后访问`http://虚拟机IP:9100`打开控制台, 输入`http://虚拟机IP:9200`, 点击连接即可.

# 安装 ES 集群
要弄一个集群, 我们得先弄几个节点, 我们复制`/opt/elasticsearch`文件夹到`/opt/elasticsearch2`和`/opt/elasticsearch3`.
记得先删除里面的`data`目录, 否则会出现错误`failed to send join request to master`.

先设置个`master`节点, 修改`/opt/elasticsearch/config/elasticsearch.yml`.
```yaml
# 1. 支持跨域访问, 供 head 使用
http.cors.enabled: true
http.cors.allow-origin: "*"
http.port: 9200
network.host: 0.0.0.0

# 2. 设置集群名称
cluster.name: ahao-cluster

# 3. 设置节点名, 以及确定主节点
node.name: ahao-master
node.master: true
```

然后设置两个`slave`节点, 同样修改`config/elasticsearch.yml`, 记得修改端口号, 避免端口冲突.
```yaml
# 1. 支持跨域访问, 供 head 使用
http.cors.enabled: true
http.cors.allow-origin: "*"
http.port: 8200
network.host: 0.0.0.0

# 2. 设置集群名称
cluster.name: ahao-cluster

# 3. 设置节点名, 以及确定主节点地址
node.name: ahao-node1
discovery.zen.ping.unicast.hosts: ["127.0.0.1"]
```

然后都启动起来
```bash
/opt/elasticsearch/bin/elasticsearch -d
/opt/elasticsearch2/bin/elasticsearch -d
/opt/elasticsearch3/bin/elasticsearch -d
```
过一段时间, 启动完毕, 访问`http://虚拟机IP:9100`打开`head`控制台, 连接到任意一个节点, 就可以获取整个集群的信息.