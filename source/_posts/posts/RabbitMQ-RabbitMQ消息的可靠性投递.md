---
title: RabbitMQ消息的可靠性投递
url: How_to_ensure_the_reliable_delivery_of_RabbitMQ
tags:
  - RabbitMQ
categories:
  - 消息队列
date: 2020-06-19 19:29:00
---

# 前言
消息中间件`MQ`主要的工作流程如下
1. 生产端`Producer`发送消息给消息中间件`MQ`
2. 消息中间件`MQ`接收到消息, 告诉生产者`Producer`消息已经收到
3. 消息中间件`MQ`将消息路由`Routing`后, 投递给消费者`Consumer`
4. 消费者告诉`MQ`消息是否消费成功

{% img /images/RabbitMQ消息的可靠性投递_01.png %}

<!-- more -->

但是, 现实世界是不可能如此理想的. 如果在某个阶段发生了异常.

比如消息中间件`MQ`接收到消息后, 所在的服务器重启了, 没能告诉生产者`Producer`消息接收成功, 也没能将消息投递给消费者`Consumer`, 这时候就应该让生产者`Producer`重新投递.
比如发生了重放攻击, 生产者`Producer`连续发送了两条相同的消息, 那么消费者`Consumer`应该判断此消息是否消费过, 不应该重复消费.

业界有两种方案
1. 消息落库, 对消息状态进行打标
2. 消息延迟投递, 做二次确认, 回调检查

两种方案都需要做消息的落库处理, 这里提供一个简单的消息表
```sql
create table rabbitmq (
`id`          bigint(20) unsigned not null auto_increment comment '消息ID',
`msg`         varchar(4096) not null comment '消息',
`status`      tinyint unsigned not null comment '状态, 0:未投递, 1:已投递, 2:已确认, 3:已消费, 4: 失败',
`retry_count` tinyint unsigned not null default 0 comment '重试次数',
`create_time` datetime not null comment '创建时间',
`update_time` datetime not null comment '更新时间',
primary key (`id`)
) engine = InnoDB default charset = utf8mb4 comment='消息表';
```

# 方案一: 消息落库, 对状态打标
以电商下单为场景
{% img /images/RabbitMQ消息的可靠性投递_02.png %}
主要的步骤如图
1. 下单请求`Request`发送到订单系统`Order Center`
1. 将订单数据落库`DB`, 将消息落库`DB`, 状态为`1 已投递`
1. 发送消息给消息中间件`MQ`
1. 消息中间件`MQ`告诉订单系统`Order Center`消息接收到了
1. 订单系统`Order Center`接收到消息中间件`MQ`的确认信息`confirm`, 更新`DB`中的消息状态为`2 已确认`
1. 消息中间件`MQ`将消息投递给结算系统`Settlement-Center`
1. 结算系统`Settlement-Center`收到消息, 更新`DB`中的消息状态为`3 已消费`
1. 分布式定时任务扫描那些超过一天还没消费的消息, 重新投递

这算是一个比较完整的解决方案, 不管哪个步骤出问题, 只要状态没有流转到`3 已消费`, 那么分布式定时任务就会抓取消息, 重新投递, 超过特定次数就不再自动投递.
这里就会带来几个问题.
1. 订单落库和消息落库, 是否要加事务?
1. 定时任务必须要是分布式的.

## 保证生产者和消息中间件的之间的可靠性投递
订单落库和消息落库, 我们可以看成是两次`insert`写库操作, 如果订单库和消息库在同一个`DB`实例下, 直接开启本地事务保存即可.
但是如果订单库和消息库在不同的`DB`实例下, 我们要使用分布式事务吗? 业务是否能接受分布式事务带来的性能损耗吗?

如果体量小的项目, 用分布式事务是可以的, 但如果碰到了海量请求的情况下.
我们可以通过快速失败的方式, 来保证两个消息落库成功.
```java
public String order() {
    // 1. 生成订单号
    try {
        // 1. 订单落库
        // 2. 消息落库
        // 3. 发送MQ
    } catch (Exception e) {
        // 4. 根据订单号做回滚操作 或者 根据定时任务扫描失败的记录
        return "下单失败";
    }
}
```

如果订单落库失败, 或着消息落库失败, 那么就直接返回客户端下单失败的提醒. 后续定时任务轮询, 根据业务做回滚操作.
如果订单落库成功, 消息落库成功, 但是发送消息失败, 此时消息库应该有一条消息记录, 状态是`1:已投递`, 后续定时任务轮询重新投递.
如果订单落库成功, 消息落库成功, 消息发送成功, 但是**`MQ`想要告诉生产者发送成功**的这个动作失败了, 消息记录的状态是`1:已投递`, 后续定时任务轮询重新投递.
如果上述的操作都成功了, 那么消息的状态变更为`2:已确认`, 生产者和消费者之间的可靠性投递就算保证了.

那么怎么判断消息发送成功呢?
`RabbitMQ`有两套机制保证, `Confirm`机制和`Return`机制.

### Confirm 确认消息
![Confirm消息确认机制](https://yuml.me/diagram/nofunky/class/[生产者]-1.消息>[消息中间件],[消息中间件]-2.Confirm>[生产者])
1. 生产者发送消息给消息中间件
2. 消息中间件应答, 发送`Confirm`消息给生产者, 告诉生产者发送成功与否.

`RabbitMQ`通过调用`channel.confirmSelect()`开启`Confirm`消息确认机制.

#### 普通confirm
```java
@Test
public void simpleConfirm(Channel channel) throws Exception {
    // 1. 开启确认模式
    int size = 10;
    channel.confirmSelect();
    // 2. 发送消息
    for (int i = 0; i < size; i++) {
        String msg = "deliveryTag: " + deliveryTag + ", 现在时间" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd hh:mm:ss"));
        channel.basicPublish(EXCHANGE_NAME, ROUTING_KEY, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
        // 3. 同步 confirm
        if (!channel.waitForConfirms()) {
            System.out.println("消息[" + msg + "]发送失败");
        }
    }
    // 4. 批量同步 confirm
    // if (!channel.waitForConfirms()) {
    //     System.out.println("消息[" + msg + "]发送失败");
    // }
}
```
`Channel`提供了一个`waitForConfirms`方法. 会阻塞等待服务器端`confirm`.
> Wait until all messages published since the last call have been either ack'd or nack'd by the broker

`waitForConfirms`还支持批量`confirm`, 放在`for`循环外面即可.
当超时或返回`false`时, 需要自己编写业务代码重发消息.

#### 异步confirm
```java
@Test
public void asyncConfirm(Channel channel) throws Exception {
    // 1. 开启确认模式
    int size = 10;
    CountDownLatch latch = new CountDownLatch(size);
    TreeSet<Long> confirmSet = new TreeSet<>(); // 记录未确认的 deliveryTag

    channel.confirmSelect();
    // 添加异步监听器
    channel.addConfirmListener(new ConfirmListener() {
        @Override
        public void handleAck(long deliveryTag, boolean multiple) throws IOException {
            try {
                if(multiple) {
                    System.out.println("消息唯一标识:" + deliveryTag + " 之前的消息都 ACK");
                    confirmSet.headSet(deliveryTag-1).clear();
                } else {
                    System.out.println("消息唯一标识:" + deliveryTag + " 消息 ACK");
                    confirmSet.remove(deliveryTag);
                }
            } finally {
                latch.countDown();
            }
        }

        @Override
        public void handleNack(long deliveryTag, boolean multiple) throws IOException {
            try {
                if(multiple) {
                    System.out.println("消息唯一标识:" + deliveryTag + " 之前的消息都 NACK");
                    confirmSet.headSet(deliveryTag-1).clear();
                } else {
                    System.out.println("消息唯一标识:" + deliveryTag + " 消息 NACK");
                    confirmSet.remove(deliveryTag);
                }

                if(confirmSet.contains(deliveryTag)) {
                    // 从数据库捞记录重发消息
                }
            } finally {
                latch.countDown();
            }
        }
    });

    // 2. 发送消息
    for (int i = 0; i < size; i++) {
        long deliveryTag = channel.getNextPublishSeqNo();
        String msg = "deliveryTag: "+deliveryTag+", 现在时间" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd hh:mm:ss"));
        channel.basicPublish(EXCHANGE_NAME, ROUTING_KEY, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
        confirmSet.add(deliveryTag);
        Thread.sleep(1000); // 延迟, 保证 multiple 为 false
    }

    latch.await();
    Assertions.assertTrue(confirmSet.isEmpty());
}
```
当生产者接受到`confirm`通知时, 会回调监听器的两个方法, `handleAck`和`handleNack`.
1. `handleAck`表示成功处理的消息
2. `handleNack`表示`Broker`丢失了消息. **但是**, 即使返回`Nack`, 也有可能已经将消息投递给了消费者.

`handleAck`和`handleNack`有两个参数, 消息标识`deliveryTag`和批量标识`multiple`.
1. `deliveryTag`用于表示一个`Channel`下的消息的唯一`Id`, 可以通过`channel.getNextPublishSeqNo()`来获取接下来要发送的消息的`deliveryTag`.
2. `multiple`用于表示当前的`ACK`或`NACK`是否批量操作, 如果是批量操作, 那么小于`deliveryTag`的消息都要处理.

#### Spring Boot 实现 confirm
首先要在配置文件里面开启`confirm`模式
```yaml
spring:
  rabbitmq:
    publisher-confirm-type: correlated # confirm模式
```
然后设置`ConfirmCallback`, 多线程跑一下.
```java
@Test
public void confirm() throws Exception {
    String msg = "sendString()";

    int size = 10;
    CountDownLatch latch = new CountDownLatch(size);
    rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
        System.out.println("接收: " + correlationData + ", ack:[" + ack + "], cause:[" + cause + "]");
        latch.countDown();
    });
    for (int i = 0; i < size; i++) {
        new Thread(() -> {
            // 不能在这里设置 ConfirmCallback
            CorrelationData correlationId = new CorrelationData(UUID.randomUUID().toString());
            System.out.println("发送:" + msg + ", correlationId: " + correlationId);
            rabbitTemplate.convertAndSend(DirectConsumer.QUEUE_NAME, (Object) msg, correlationId);
        }).start();
    }

    boolean success = latch.await(10, TimeUnit.SECONDS);
    Assertions.assertTrue(success);
}
```

有一点需要注意下, 一个`RabbitTemplate`只能有一个`ConfirmCallback`. 这里看下源码.
```java
// org.springframework.amqp.rabbit.core.RabbitTemplate#setConfirmCallback
public void setConfirmCallback(ConfirmCallback confirmCallback) {
    Assert.state(this.confirmCallback == null || this.confirmCallback == confirmCallback, "Only one ConfirmCallback is supported by each RabbitTemplate");
    this.confirmCallback = confirmCallback;
}
```
如果业务要求需要对不同的生产者执行不同的`ConfirmCallback`逻辑, 那么再应该`new`一个`RabbitTemplate`.

### Return 不可达消息
![Return不可达消息](https://yuml.me/diagram/nofunky/class/[生产者]-1.消息>[消息中间件],[消息中间件]-2.没找到>[生产者])

> https://www.rabbitmq.com/confirms.html
> For unroutable messages, the broker will issue a confirm once the exchange verifies a message won't route to any queue (returns an empty list of queues). 
> If the message is also published as mandatory, the basic.return is sent to the client before basic.ack. 
> The same is true for negative acknowledgements (basic.nack).

当生产者生产一条消息, 投递到`MQ`消息中间件中, 但是`MQ`消息中间件判定投递失败`unroutable`, 比如没有对应的路由`Key`, 就会触发`return`机制.
在生产消息时, 如果指定`Mandatory`是`true`, 则监听器会接收到路由不可达的消息, 交由`ReturnListener`进行后续处理. 如果为false, 那么`MQ`消息中间件会自动删除这条消息.

#### 原生 API 方式
```java
@Test
public void _return() throws Exception {
    // 1. 开启 return
    CountDownLatch latch = new CountDownLatch(1);
    boolean mandatory = true; // true监听不可达消息, false则自动删除消息

    channel.addReturnListener((replyCode, replyText, exchange, routingKey, properties, body) -> {
        System.out.println("replyCode:[" + replyCode + "], replyText:[" + replyText + "], exchange:[" + exchange + "], routingKey:[" + routingKey + "], BasicProperties:[" + properties + "], body:[" + new String(body, StandardCharsets.UTF_8) + "]");
        latch.countDown();
    });

    // 2. 发送消息
    long deliveryTag = channel.getNextPublishSeqNo();
    String msg = "deliveryTag: " + deliveryTag + ", 现在时间" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd hh:mm:ss"));
    channel.basicPublish(EXCHANGE_NAME, "NULL_KEY", mandatory, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
    // channel.basicPublish("NULL_EXCHANGE", ROUTING_KEY, mandatory, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));

    boolean success = latch.await(10, TimeUnit.SECONDS);
    Assertions.assertTrue(success);
}
```
实际上, 如果传递一个未声明的`Exchange`过去, 不会触发`return`. 而传递不可路由的`RoutingKey`, 则可以触发`return`.

#### Spring Boot 实现 return
首先要在配置文件里面开启`return`模式
```yaml
spring:
  rabbitmq:
    publisher-returns: true # return机制
    template:
      mandatory: true # 与 return 机制结合配置次属性
```
然后设置`ReturnCallback`, 多线程跑一下.
```java
@Test
public void _return() throws Exception {
    String msg = "sendString()";

    int size = 10;
    CountDownLatch latch = new CountDownLatch(size);
    rabbitTemplate.setReturnCallback((message, replyCode, replyText, exchange, routingKey) -> {
        System.out.println("接收: " + message + ", replyCode:[" + replyCode + "], replyText:[" + replyText + "], exchange:[" + exchange + "], routingKey:[" + routingKey + "]");
        latch.countDown();
    });
    for (int i = 0; i < size; i++) {
        new Thread(() -> {
            // 不能在这里设置 ReturnCallback
            CorrelationData correlationId = new CorrelationData(UUID.randomUUID().toString());
            System.out.println("发送:" + msg + ", correlationId: " + correlationId);
            rabbitTemplate.convertAndSend("UNKNOWN", (Object) msg, correlationId);
        }).start();
    }

    boolean success = latch.await(10, TimeUnit.SECONDS);
    Assertions.assertTrue(success);
}
```

有一点需要注意下, 和`Callback`一样, 一个`RabbitTemplate`只能有一个`ReturnCallback`. 这里看下源码.
```java
// org.springframework.amqp.rabbit.core.RabbitTemplate#setReturnCallback
public void setReturnCallback(ReturnCallback returnCallback) {
    Assert.state(this.returnCallback == null || this.returnCallback == returnCallback, "Only one ReturnCallback is supported by each RabbitTemplate");
    this.returnCallback = returnCallback;
}
```
如果业务要求需要对不同的生产者执行不同的`ReturnCallback`逻辑, 那么再应该`new`一个`RabbitTemplate`.

### 我们需要判断消息发送成功吗?
如果我们只管投递消息, 不管是否投递成功, 会有什么情况?
投递成功当然是最好的, 投递失败的话, 订单状态会一直处于`1:已投递`, 而不会变成`2:已确认`.
这样的话, 定时任务扫描到这条处于`1:已投递`的消息, 就会重新发送.

看起来似乎用不用`confirm`和`return`都可以保证消息投递成功了.
我能想象到使用`confirm`和`return`的业务场景有两种情况
1. 投递失败时, 尽快重新投递, 不等定时任务扫描.
2. 监控投递流程, 单位时间内投递失败消息超过一定数量就报警.

## 保证消息中间件的持久化存储, 避免消息丢失
经过上面的操作, 消息已经存储到消息中间件了. 为了保证消息不丢失, 消息中间件应该将消息做持久化处理. 
否则当消息中间件宕机的时候, 在内存中的消息就会丢失.

`RabbitMQ`可持久化的东西有三样, `Exchange`、`Queue`、消息.
持久化也很简单, 只要调用`API`传参即可.

### 原生 API 方式
```java
public void create(Channel channel) {
    // Exchange.DeclareOk exchangeDeclare(String exchange, BuiltinExchangeType type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments);
    channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT, true, false, false, null);

    // Queue.DeclareOk queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments) throws IOException;
    channel.queueDeclare(QUEUE_NAME, true, false, false, null);
    
    // public BasicProperties(String contentType, String contentEncoding, Map<String,Object> headers, Integer deliveryMode, 
    //                          Integer priority, String correlationId, String replyTo, String expiration, String messageId,
    //                          Date timestamp, String type, String userId, String appId, String clusterId)
    // new BasicProperties("text/plain", null, null, 2, 0, null, null, null, null, null, null, null, null, null)
    channel.basicPublish(EXCHANGE_NAME, ROUTING_KEY, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
}
```
`Exchange`和`Queue`的持久化只要在声明的时候, 指定`durable`为`true`即可.
而消息的持久化, 需要在发送消息的时候, 指定`BasicProperties`属性, 将`deliveryMode`设置为`2`持久化.

### Spring Boot 实现
`Spring Boot`可以通过使用`Bean`声明`Exchange`和`Queue`来实现持久化.
```java
@Configuration
public class MyConfig {
    boolean durable = true; // 持久化
    @Bean
    public Exchange exchange() { return new TopicExchange(EXCHANGE_NAME, durable, false, null); }
    @Bean
    public Queue queue() { return new Queue(QUEUE_NAME, durable, false, false, null); }
}
```
也可以使用注解的形式声明`Exchange`和`Queue`实现持久化.
```java
public void create(String exchange, String routingKey, String msg) {
    // Exchange.DeclareOk exchangeDeclare(String exchange, BuiltinExchangeType type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments);
    channel.exchangeDeclare(EXCHANGE_NAME, BuiltinExchangeType.DIRECT, true, false, false, null);

    // Queue.DeclareOk queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments) throws IOException;
    channel.queueDeclare(QUEUE_NAME, true, false, false, null);
    
    // public BasicProperties(String contentType, String contentEncoding, Map<String,Object> headers, Integer deliveryMode, 
    //                          Integer priority, String correlationId, String replyTo, String expiration, String messageId,
    //                          Date timestamp, String type, String userId, String appId, String clusterId)
    // new BasicProperties("text/plain", null, null, 2, 0, null, null, null, null, null, null, null, null, null)
    channel.basicPublish(EXCHANGE_NAME, ROUTING_KEY, MessageProperties.PERSISTENT_TEXT_PLAIN, msg.getBytes(StandardCharsets.UTF_8));
}
```
消息的持久化也是在发消息时通过指定`MessageProperties`实现
```java
public void send(String exchange, String routingKey, String msg) {
    MessageProperties properties = new MessageProperties();
    properties.setDeliveryMode(MessageDeliveryMode.PERSISTENT); // 指定持久化消息
    
    Message message = MessageBuilder.withBody(msg.getBytes(StandardCharsets.UTF_8)).andProperties(properties).build();
    rabbitTemplate.send(exchange, routingKey, message);
}
```

## 保证消息中间件的消费可靠性
`RabbitMQ`要保证消息消费的可靠性, 就必须开启手动`ACK`.
默认情况下, 消费者是开启自动`ACK`的. 也就是说一条消息过来, 不管有没有执行成功, 都会告诉`RabbitMQ`消费成功. 如果出现异常, 也告诉`RabbitMQ`消费成功. 这明显是不合理的.

### 原生 API 手动 ACK
```java
public void consumer(Channel channel) {
    boolean autoAck = true; // 声明自动 ACK
    channel.basicConsume(QUEUE_NAME, autoAck, new DefaultConsumer(channel) {
        @Override
        public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
            try {
                System.out.println("接受到:" + new String(body));
                // channel.basicAck(envelope.getDeliveryTag(), false);
            } catch (Exception e) {
                e.printStackTrace();
                // channel.basicNack(envelope.getDeliveryTag(), false, false);
                // channel.basicReject(envelope.getDeliveryTag(), false);
            }
        }
    });
}
```
可以看到, 自动`ACK`的配置, 是在创建消费者的时候就声明的.
如果设置成手动`ACK`, 那么就要手动调用几个方法.
1. `channel.basicAck(long deliveryTag, boolean multiple)`, 表示正确处理这条消息.
2. `channel.basicNack(long deliveryTag, boolean multiple, boolean requeue)`, 表示消息处理失败, 决定是否重回队列.
3. `channel.basicReject(long deliveryTag, boolean requeue)`, 表示消息处理失败, 决定是否重回队列.

`basicNack`和`basicReject`有点像, 看了下文档, 区别就是能否支持`multiple`.

### Spring Boot 手动 ACK
首先在配置文件里设置
```yaml
spring:
  rabbitmq:
    listener:
      simple:
        acknowledge-mode: manual # 手动ack
```
然后在消费者那里手动调用原生`API`.
```java
@RabbitListener(queuesToDeclare = @Queue(queueName))
public class Consumer {
    @RabbitHandler
    public void directQueue(@Payload String msg, Channel channel, @Header(AmqpHeaders.DELIVERY_TAG) long tag) throws Exception {
        try {
            System.out.println("接收到的消息:" + msg);
            channel.basicAck(tag, false);
        } catch (Exception e) {
            e.printStackTrace();
            channel.basicNack(tag, false, false);
        }
    }
}
```

## 定时任务处理极端情况下的消息处理异常
保证了消息发送、中间件存储、消息消费的可靠性.
但还是防止不了极端情况, 这些无法预料的情况, 必须有个兜底策略来处理.

比如用分布式定时任务扫描那些超过一天还没有流转到`3 已消费`的消息, 重新投递.

至于为什么要用**分布式的**定时任务, 是避免同一条消息, 在同一时刻重复投递.
从源头避免并发消息的产生.
当然, 消息的幂等性处理要由消费者来保证.

# 方案二: 消息延迟投递, 做二次确认, 回调检查
方案一有一个问题, 消息发送之前, 需要落库两次, 业务库和消息库.
在海量高并发下, 每次磁盘`IO`的耗时, 都是不可忽视的. 在这种情况下, 要保证高性能, 将一致性降级为最终一致性.

和方案一相比, 方案二多了一个回调系统, 少了一步落库的操作.
要注意的是, 这里没有使用`RabbitMQ`的`Confirm`和`Return`机制.
{% img /images/RabbitMQ消息的可靠性投递_03.png %}

1. 下单请求`Request`发送到订单系统`Order Center`
1. 将订单数据落库`DB`, 发送一条业务消息, 发送一条延时消息(用于检查第一条消息是否处理成功)
1. 结算系统`Settlement-Center`收到消息, 处理成功后, 发送一条确认消息
1. 回调系统消费这条确认消息, 这个时候再进行消息落库
1. 过了几分钟, 回调系统消费了订单系统发送的延迟消息, 去消息库里检查是否存在这条信息.
1. 如果没有, 就调用订单系统的接口, 重投消息.
1. 分布式定时任务扫描那些超过一天还没消费的消息, 重新投递.

以上都是流程正常的情况. 
那万一中间哪一步出现异常, 要怎么保证消息再次重发呢? 关键点就在于这个用于**检查**的延迟消息.

这个用于检查的延迟消息, 会在一段时间, 比如十分钟后投递到`MQ`消息中间件, 消息体带上订单号等业务信息, 然后回调系统会去检查消息库.
如果看到这条订单消息没有被处理, 那么就调用订单系统的接口, 让订单系统重新投递这条消息.

这里有个大问题, 如果这条延迟消息丢失了怎么办?
只能通过定时任务来补偿了.

# 总结
- [RabbitMQ消息中间件技术精讲](https://coding.imooc.com/class/262.html)
- [消息中间件——RabbitMQ（七）高级特性全在这里!（上）](https://www.javazhiyin.com/47715.html)