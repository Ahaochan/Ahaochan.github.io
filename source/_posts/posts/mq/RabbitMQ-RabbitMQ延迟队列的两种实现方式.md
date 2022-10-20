---
title: RabbitMQ延迟队列的两种实现方式
url: Two_implementations_of_the_RabbitMQ_delay_queue
tags:
  - RabbitMQ
categories:
  - 消息队列
date: 2019-08-19 14:47:55
---

# 前言
`RabbitMQ`是没有延迟队列, 但是我们可以通过`TTL`和死信队列间接来实现.
1. 将`Message`指定`TTL`后放入队列中.
1. 等超时后, `Message`放入死信队列.
1. 死信队列将`Message`转发到目标队列.

很麻烦. 
幸运的是, `RabbitMQ`官方提供了一个`rabbitmq-delayed-message-exchange`延迟消息插件.
本文基于`Spring Boot AMQP`来操作.
<!-- more -->

# 使用官方延迟插件 rabbitmq-delayed-message-exchange
要求版本 ` >= 3.5.8`.
`GitHub`地址: https://github.com/rabbitmq/rabbitmq-delayed-message-exchange
下载地址: https://www.rabbitmq.com/community-plugins.html

我这里用的是`3.6.x`的版本.
```bash
# 1. 下载 plugin
cd /opt/
wget https://dl.bintray.com/rabbitmq/community-plugins/3.6.x/rabbitmq_delayed_message_exchange/rabbitmq_delayed_message_exchange-20171215-3.6.x.zip
unzip rabbitmq_delayed_message_exchange-20171215-3.6.x.zip 

# 2. 移动到 plugins 文件夹内, 不同操作系统 plugins 位置不同
cd /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.10/plugins/
cp /opt/rabbitmq_delayed_message_exchange-20171215-3.6.x.ez ./

# 3. 启动延时插件
rabbitmq-plugins list | grep delayed
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```

然后再声明一个延迟交换机`Exchange`.
```java
@Configuration
@EnableRabbit
public class RabbitMQConfig {
    public static final String DELAY_EXCHANGE_NAME = "ahao_delayed_exchange";
    @Bean(DELAY_EXCHANGE_NAME)
    public Exchange delayExchange() {
        Map<String, Object> args = new HashMap<>();
        args.put("x-delayed-type", "direct");
        return new CustomExchange(DELAY_EXCHANGE_NAME, "x-delayed-message", true, false, args);
    }
}
```
然后我们需要将`Queue`队列绑定到交换机上
```java
@Configuration
@EnableRabbit
public class RabbitMQConfig {
    public static final String QUEUE_NAME = "ahao_queue";
    @Bean
    public Queue queue() {
        return new Queue(QUEUE_NAME);
    }
    
    @Bean
    public Binding binding(Queue queue, CustomExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with(QUEUE_NAME).noargs();
    }
}
```
绑定后, 就可以直接发送消息了.
```java
@Service
public class RabbitService {
    public static final String DELAY_EXCHANGE_NAME = "ahao_delayed_exchange";

    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    public void doSendDelay(String queueName, Object data, long delayMilliSeconds) throws IllegalArgumentException {
        if(delayMilliSeconds > 0xffffffffL) {
            throw new IllegalArgumentException("超时过长, 只支持 < 4294967296 的延时值");
        }
        
        CorrelationData correlationId = new CorrelationData(UUID.randomUUID().toString());
        rabbitTemplate.convertAndSend(DELAY_EXCHANGE_NAME, queueName, data, message -> {
            MessageProperties messageProperties = message.getMessageProperties();
            messageProperties.getHeaders().put("x-delay", delayMilliSeconds);
            return message;
        }, correlationId);
    }
}
```

## 坑点1 延时最长为 2^32-1 毫秒
根据[官方文档](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange#performance-impact)来看, 本插件的延时时长最长为`2^32-1`毫秒, 也就是`0xffffffff`毫秒.
换算一下, 大约是`49`天.
如果超过`2^32-1`毫秒, 那么延时值就会溢出, 也就是会立即消费.

[`Issue#122`](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/issues/122#issuecomment-486385307)也有提到.
这应该是`Erlang`本身的限制.
> In Erlang a timer can be set up to (2^32)-1 milliseconds in the future

## 坑点2 队列需要和延时 Exchange 绑定
之前以为指定了`x-delayed-type`为`direct`, 就可以不用绑定`Queue`到这个延时`Exchange`交换机上.
结果发的消息接收不到, 还是需要绑定一下.

# 使用原生死信队列实现延时队列
原生方法就是利用死信队列.
1. 将`Message`指定`TTL`后放入队列中.
1. 等超时后, `Message`放入死信队列.
1. 死信队列将`Message`转发到目标队列.

我们先设计下消息流转流程图
![消息流转流程图](https://yuml.me/diagram/nofunky;dir:LR/activity/(start)-Msg>(delay_exchange)-fanout>(delay_queue)-dead>(biz_exchange)-><a>[key1]->(biz_queue1)->(consumer),<a>[key2]->(biz_queue2)->(consumer)->(end))

1. 用户发送带着`RoutingKey`为`biz_queue1`的一条消息到延时交换机`delay_exchange`上(注意, 这个延时交换机就是一个普通交换机).
1. 延时交换机`delay_exchange`将消息`fanout`到队列`delay_queue`, 这个队列配置了一堆死信参数.
1. 等待消息在`delay_queue`超时, 然后将消息转发到该队列的死信交换机`biz_exchange`上.
1. 因为`delay_queue`没有指定`x-dead-letter-routing-key`, 所以使用的还是原来的`biz_queue1`. 路由到`biz_queue1`队列上.
1. 延时消费成功.

设计完毕开始编码实战. 我们需要初始化交换机`Exchange`和队列`Queue`
```java
@Configuration
@EnableRabbit
public class RabbitMQConfig {
    @Bean
    public Exchange delayExchange() {
        return new FanoutExchange("delay_exchange", true, false, null);
    }
    @Bean
    public Queue delayQueue() {
        Map<String, Object> args = new HashMap<>(2);
        args.put("x-dead-letter-exchange", bizExchange().getName()); // 声明死信交换机
//        args.put("x-dead-letter-routing-key", "");                 // 声明死信路由键
        args.put("x-message-ttl", 10000);                            // 所有消息的默认超时时间
        return new Queue("delay_queue", true, false, false, args);
    }
    @Bean
    public Binding delayBinding() {
        return BindingBuilder.bind(delayQueue()).to(delayExchange()).with(delayQueue().getName()).noargs();
    }

    @Bean
    public Exchange bizExchange() {
        return new DirectExchange("biz_exchange", true, false, null);
    }
    @Bean
    public Queue bizQueue1() {
        return new Queue("biz_queue1", true, false, false, null);
    }
    @Bean
    public Binding bizBinding1() {
        return BindingBuilder.bind(bizQueue1()).to(bizExchange()).with(bizQueue1().getName()).noargs();
    }
    @Bean
    public Queue bizQueue2() {
        return new Queue("biz_queue2", true, false, false, null);
    }
    @Bean
    public Binding bizBinding2() {
        return BindingBuilder.bind(bizQueue2()).to(bizExchange()).with(bizQueue2().getName()).noargs();
    }
}
```
然后写一个单元测试, 我用的`Junit5`
```java
@Service
public class DirectConsumer {
    public static final String QUEUE_NAME = "biz_queue1";
    public static Object value;
    @RabbitListener(queuesToDeclare = @Queue(QUEUE_NAME))
    @RabbitHandler
    public void directQueue(String msg) throws Exception {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        System.out.println("消息接收时间:"+sdf.format(new Date()));
        System.out.println("接收到的消息:"+msg);
        Thread.sleep(1000);
        value = msg;
    }
}

@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ContextConfiguration(classes = {RabbitMQConfig.class, RabbitAutoConfiguration.class, SpringContextHolder.class, DirectConsumer.class})
public class DirectProducerTest {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    @Autowired
    private DirectConsumer consumer;
    @Test
    public void send() throws Exception {
        Assert.assertNotNull(rabbitTemplate);
        Assert.assertNotNull(consumer);
        
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        System.out.println("消息发送时间:" + sdf.format(new Date()));
        String msg = "send()";

        rabbitTemplate.convertAndSend("delay_exchange", DirectConsumer.QUEUE_NAME, msg, message -> {
            MessageProperties messageProperties = message.getMessageProperties();
            messageProperties.setExpiration("3000");
            return message;
        });

        Assert.assertNull(DirectConsumer.value);
        Thread.sleep(5000);
        Assert.assertEquals(msg, DirectConsumer.value);
    }
}
```
我们可以给队列设置`x-message-ttl`, 也可以给每条消息设置`expiration`, `RabbitMQ`会取两者最小值作为消息过期时间.

用死信队列来实现延迟队列, 只要套多几个死信队列, 就可以绕过官方延时插件的只能延时`2^32-1`毫秒的`bug`.
但是和官方延时插件一样, 还是得每个队列都绑定到延时交换机上.

并且! 推荐给队列设置`x-message-ttl`, 而不是给消息设置`expiration`.

## 坑点 同一队列的延时时长不一样导致消息阻塞
我们先看下面这个单元测试, 比起上面那个单元测试, 就是连续发送了两条消息.
```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ContextConfiguration(classes = {RabbitMQConfig.class, RabbitAutoConfiguration.class, SpringContextHolder.class, DirectConsumer.class})
public class DirectProducerTest {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    @Autowired
    private DirectConsumer consumer;
    @Test
    public void sendFailure() throws Exception {
        Assert.assertNotNull(rabbitTemplate);
        Assert.assertNotNull(consumer);
        
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        System.out.println("消息发送时间:" + sdf.format(new Date()));
        
        String msg1 = "sendFailure(1)";
        rabbitTemplate.convertAndSend("delay_exchange", DirectConsumer.QUEUE_NAME, msg1, message -> {
            MessageProperties messageProperties = message.getMessageProperties();
            messageProperties.setExpiration("1000000");
            return message;
        });
        String msg2 = "sendFailure(2)";
        rabbitTemplate.convertAndSend("delay_exchange", DirectConsumer.QUEUE_NAME, msg2, message -> {
            MessageProperties messageProperties = message.getMessageProperties();
            messageProperties.setExpiration("3000");
            return message;
        });

        Assert.assertNull(DirectConsumer.value);
        Thread.sleep(5000);
        Assert.assertNull(msg, DirectConsumer.value);
    }
}
```
执行后可以发现, `5000`毫秒后, 消费者仍然不能接受到`sendFailure(2)`这条消息.
因为消息队列是先进先出的, 当第一条消息没有被消费, 后面的消息也会阻塞不能消费.

所以推荐还是使用给队列设置`x-message-ttl`的形式来设置延时时长. 当然, 官方延时插件就没这个问题了.

# 总结
使用官方插件
- 优点: 
    1. 使用简单
    1. 不会出现因为前一条消息没有消费, 导致后面的消息阻塞的情况
- 缺点:
    1. 延时时长不能超过`2^32-1`毫秒, 大约`49`天.

使用原生死信队列
- 优点:
    1. 使用死信队列套死信队列, 可以突破`2^32-1`毫秒的官方插件限制.
- 缺点:
    1. 实现复杂.
    1. 如果给每条消息设置`expiration`, 则前一条消息会阻塞后一条消息.

然后我写了个工具类[`RabbitMQHelper`](https://github.com/Ahaochan/ahao-common-utils/blob/master/src/main/java/com/ahao/util/spring/mq/RabbitMQHelper.java)可以拿来用下.

# 参考资料
- [RabbitMQ 延迟队列插件 x-delay Bug](http://blog.lbanyan.com/rabbitmq_delay/)
- [springboot rabbitmq 之死信队列（延迟消费消息）](https://my.oschina.net/10000000000/blog/1626278)
- [通过RabbitMQ 死信队列实现延迟MQ消息，消息延迟，MQ延迟队列](https://blog.csdn.net/qq_15071263/article/details/89636161)