---
title: Docker Swarm容器编排
url: Docker_Swarm_mode_overview
tags:
  - Docker
categories:
  - Docker
date: 2020-07-11 23:08:00
---
# 前言
`Swarm`是一个`Docker`官方提供的容器编排工具. 是`Docker`推出的一个`kubernetes`的竞品(当然现在已经是`kubernetes`的天下了
`Swarm`用来解决多机下`Docker`容器的部署问题, 这是传统`Docker`和`Docker compose`解决不了的.
并且`Swarm`已经集成到`Docker`原生工具里了, 可以直接使用.

<!-- more -->

# 拓扑图
![拓扑图](https://yuml.me/diagram/nofunky;dir:UD/class/[manager1]->[worker1],[manager1]->[worker2],[manager1]->[worker3],[manager2]->[worker2],[manager2]->[worker3])
`Docker Swarm`有两个角色, `Manager`和`Worker`.
`Manager`用于管理多个`Worker`.


# 手动创建三个节点的Swarm集群
这里用一个在线环境来搭建. [`labs.play-with-docker`](https://labs.play-with-docker.com/)
先创建`3`个节点
```bash
# 1. 在节点A上声明自己是 manager
docker swarm init --advertise-addr=`hostname -i | awk '{print $1}'`
# Swarm initialized: current node (ob8gsaxiz3a4k8rubrv20im2q) is now a manager.
# To add a worker to this swarm, run the following command:
#     docker swarm join --token SWMTKN-1-4luou0jd1580qrjuodc74c7nnavzdoj6pmo8sdfjxy7i0mdld3-45orfnut6qf9ey4kxzs36yjkw 192.168.0.8:2377
# To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

# 2. 在节点B和节点C上执行上面提供的命令, 加入到 manager 的管理下 
docker swarm join --token SWMTKN-1-4luou0jd1580qrjuodc74c7nnavzdoj6pmo8sdfjxy7i0mdld3-45orfnut6qf9ey4kxzs36yjkw 192.168.0.8:2377

# 3. 在 manager 上查看节点
docker node ls
# ID                            HOSTNAME    STATUS  AVAILABILITY    MANAGER STATUS  ENGINE VERSION
#  ob8gsaxiz3a4k8rubrv20im2q *   node1       Ready   Active          Leader          19.03.11
#  jlhp9zpjdhgwygxxl0hrky794     node2       Ready   Active                          19.03.11
#  cohz6uotcm6iogvlxmrh7cdwi     node3       Ready   Active                          19.03.11

# 4. 在 manager 上创建一个 service
docker service create --name service1 alpine /bin/ping 127.0.0.1
# u83i2d5k6aiog3elo9fndbic5
# overall progress: 1 out of 1 tasks 
# 1/1: running   [==================================================>] 
# verify: Service converged 

# 5. 在 manager 上查看 service
docker service ls
# ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
# u83i2d5k6aio        service1            replicated          1/1                 alpine:latest

# 6. 在 manager 上给 service 动态扩容成 2 个节点
docker service scale service1=2
```

# 手动搭建一个 wordpress
```bash
# 1. 创建一个 overlay 网络
docker network create -d overlay my-overlay
# 2. 创建 mysql 的 service 
docker service create --name my-mysql --network my-overlay --mount type=volume,source=mysql-data,destination=/var/lib/mysql --env MYSQL_ROOT_PASSWORD=root --env MYSQL_DATABASE=wordpress mysql
# 3. 创建 wordpress 的 service 
docker service create --name my-wordpress --network my-overlay -p 80:80 --env WORDPRESS_DB_PASSWORD=root --env WORDPRESS_DB_HOST=mysql wordpress
# 4. 为 wordpress 扩容
docker service scale my-wordpress=3
```
这又回到了古老的`docker run`, 有没有类似`docker compose`的东西呢?

# 使用 yaml 配置文件部署 swarm 集群
`docker stack`就是在`swarm`上的`docker compose`, 用的也是`yaml`配置.
`compose file`在`3`之后提供了一个`deploy`的配置, 用于`swarm`集群的部署.

这里还是用`wordpress`举例
```yaml
version: "3.3"
services:
  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    networks:
      - my-overlay
    deploy:
      mode: replicated
      replicas: 3
      endpoint_mode: vip
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
  db:
    image: mysql:5.7
    volumes:
      - mysql-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    networks:
      - my-overlay
    deploy:
      mode: global # 只部署一个节点
      placement:
        constraints:
          - node.role == manager # 只部署在 manager 节点上
volumes:
  mysql-data: {}
networks:
  my-overlay:
    driver: overlay
```
然后使用`docker stack`命令启动
```bash
# 1. 编辑 docker-compose.yml
vim docker-compose.yml
# 2. 部署 swarm 集群
docker stack deploy wordpress --compose-file=docker-compose.yml
# 3. 查看 service
docker stack services wordpress
# ID                  NAME                  MODE                REPLICAS            IMAGE               PORTS
# 3uuc9055uadr        wordpress_db          global              1/1                 mysql:5.7           
# z7l7b5chkq0t        wordpress_wordpress   replicated          3/3                 wordpress:latest    *:80->80/tcp
```

# 参考资料
- [`compose-file`文档](https://docs.docker.com/compose/compose-file/)