---
title: RabbitMQ概念入门
url: Getting_started_with_RabbitMQ
tags:
  - RabbitMQ
categories:
  - 消息队列
date: 2020-06-02 14:21:00
---

# 前言
`RabbitMQ`是一个`Erlang`实现的开源消息中间件, 实现了`Advanced Message Queuing Protocol(AMQP)`协议.
`AMQP`协议是一个抽象协议, 定义了一系列的接口, 而`RabbitMQ`等消息中间件实现了这些接口.

本文使用原生`RabbitMQ`的`API`来进行调用, 不使用`Spring AMQP`.

<!-- more -->

# AMQP核心概念
`Server`: 又称为`Broker`, 其实就是`RabbitMQ`的服务端, 接收客户端的连接, 实现`AMQP`协议.
`Connection`: 连接, 应用程序与`Broker`的连接.
`Channel`: 网络信道, 生产消费消息都在`Channel`进行, 一个客户端可以建立多个`Channel`.

`Message`: 消息, 应用程序和`Broker`之间传送的数据, 由`Properties`属性和`Body`消息体组成.

`Virtual Host`: 虚拟地址, 用于逻辑隔离. 一般用于区分`dev`环境, `test`环境.
`Exchange`: 交换机, 接收消息, 根据消息的路由`Key`和绑定规则, 投递到对应的`Queue`队列中.
`Binding`: `Exchange`交换机和`Queue`队列之间的绑定规则.
`Queue`: 队列, 保存消息并转发给消费者.

# Broker
`Broker`服务端直接用`docker`启动就好了, 使用默认参数.
```bash
docker run -it --rm --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```
然后访问`http://虚拟机IP:15672`.
除了单节点的启动, `RabbitMQ`还支持集群部署.

# Connection、Channel
接下来是`Connection`和`Channel`, 和数据库连接类似, 我们可以对比下
```java
public class Main {
    @Test
    public void mq() throws Exception {
        // 1. 建立连接工厂
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("127.0.0.1");
        factory.setPort(5672);
        factory.setVirtualHost("/");
        factory.setUsername("guest");
        factory.setPassword("guest");

        // 2. 获取连接, 获取 Channel
        try (Connection connection = factory.newConnection();
             Channel channel1 = connection.createChannel();
             Channel channel2 = connection.createChannel();) {
            // 3. 使用 Channel 创建 Exchange、Queue, 生产消息
        }
    }

    @Test
    public void db() throws Exception {
        // 1. 获取连接, 获取 Statement
        try (Connection connection = DriverManager.getConnection(url, username, password);
             PreparedStatement statement1 = connection.prepareStatement(SQL);
             PreparedStatement statement2 = connection.prepareStatement(SQL);) {
            // 2. 执行语句    
        }
    }
}
```
一般一个应用程序共享一个`Connection`, 每个线程创建自己的`Channel`.
所有的操作, 包括`Exchange`、`Queue`的创建绑定, 消息的生产消费, 都是在`Channel`上执行的.
{% img /images/RabbitMQ概念入门_01.png %}

# Virtual Host、Exchange、Binding、Queue
{% img /images/RabbitMQ概念入门_02.png %}
`Virtual Host`用来区分`dev`环境和`test`环境, 避免两个环境的数据混淆在一起.

从图中可以看到, 生产者只管投递到`Exchange`上, 消费者也只管从`Queue`消费消息, 其中它们是怎么路由的, 生产者和消费者不需要关心.
而`Exchange`和`Queue`之间的路由规则, 就是根据`Message`消息提供的`RoutingKey`, 以及`Exchange`和`Queue`之间的`BindingKey`, 两者匹配上, 路由成功就投递到`Queue`队列上.

# Demo 例子
概念讲完, 这里提供简单的一个[单元测试](https://github.com/Ahaochan/project/blob/master/ahao-spring-boot-rabbitmq/src/test/java/com/ahao/spring/boot/rabbitmq/NativeTest.java)
```java
public class NativeTest {
    public static final String EXCHANGE_NAME = "ahao-exchange";
    public static final String ROUTING_KEY = "ahao-routing-key";
    public static final String QUEUE_NAME = "ahao-queue";

    @Test
    public void producer() throws Exception {
        // 1. 建立连接工厂
        ConnectionFactory factory = this.initFactory();

        // 2. 获取连接, 获取 Channel
        try (Connection connection = factory.newConnection();
             Channel channel = connection.createChannel();) {

            // 3. 创建 Exchange 和 Queue 并绑定
            channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT);
            channel.queueDeclare(QUEUE_NAME, true, false, false, null);
            channel.queueBind(QUEUE_NAME, EXCHANGE_NAME, ROUTING_KEY, null);

            // 4. 发送消息
            String msg = "现在时间"+ LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd hh:mm:ss"));
            channel.basicPublish(EXCHANGE_NAME, ROUTING_KEY, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
        }
    }

    @Test
    public void consumer() throws Exception {
        // 1. 建立连接工厂
        ConnectionFactory factory = this.initFactory();

        // 2. 获取连接, 获取 Channel
        try (Connection connection = factory.newConnection();
             Channel channel = connection.createChannel();) {

            // 3. 创建 Exchange 和 Queue 并绑定
            channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT);
            channel.queueDeclare(QUEUE_NAME, true, false, false, null);
            channel.queueBind(QUEUE_NAME, EXCHANGE_NAME, ROUTING_KEY, null);

            // 4. 消费消息
            CountDownLatch latch = new CountDownLatch(1);
            channel.basicQos(64);
            channel.basicConsume(QUEUE_NAME, true, new DefaultConsumer(channel) {
                @Override
                public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                    System.out.println("接受到:" + new String(body));
                    latch.countDown();
                }
            });

            // 5. 等待消息消费后, 再关闭资源
            latch.await(10, TimeUnit.SECONDS);
        }
    }

    public ConnectionFactory initFactory() {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("MQ地址");
        factory.setPort(5672);
        factory.setVirtualHost("/");
        factory.setUsername("guest");
        factory.setPassword("guest");
        return factory;
    }
}
```