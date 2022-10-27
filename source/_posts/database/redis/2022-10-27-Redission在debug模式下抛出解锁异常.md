---
title: Redission在debug模式下抛出解锁异常
url: not_locked_by_current_thread_by_node_id_in_debug_mode
tags:
  - Redis
categories:
  - Redis 
date: 2022-10-27 15:07:55
---

# 前言
最近用`Redission`出现一个很有趣的问题，在线上环境加锁解锁没有问题，但是一旦进行`debug`调试，就会抛出异常。

# 场景复现
编写以下代码
```java
public class AhaoTest {
    @Test
    void unlockDebug() throws Exception {
        RLock lock = redissonClient.getLock(REDIS_KEY);
        boolean result = lock.tryLock();
        if (!result) {
            Assertions.fail("加锁失败");
        }
        try {
            // 打断点30秒以上
            Thread.sleep(10000);
        } finally {
            lock.unlock();
        }
        Assertions.assertEquals(0, lock.getHoldCount());
    }
}
```

然后以`debug`模式执行，在断点处停留`30`秒以上。
```text
java.lang.IllegalMonitorStateException: attempt to unlock lock, not locked by current thread by node id: e8f58212-5f8e-43db-94ba-606e07e9d984 thread-id: 1
	at org.redisson.RedissonBaseLock.lambda$unlockAsync$1(RedissonBaseLock.java:312)
	at org.redisson.misc.RedissonPromise.lambda$onComplete$0(RedissonPromise.java:187)
	...
	at org.redisson.misc.RedissonPromise.trySuccess(RedissonPromise.java:82)
	at org.redisson.RedissonBaseLock.lambda$evalWriteAsync$0(RedissonBaseLock.java:224)
	at org.redisson.misc.RedissonPromise.lambda$onComplete$0(RedissonPromise.java:187)
	...
	at io.netty.util.concurrent.DefaultPromise.trySuccess(DefaultPromise.java:104)
	at org.redisson.misc.RedissonPromise.trySuccess(RedissonPromise.java:82)
	at org.redisson.command.CommandBatchService.lambda$executeAsync$7(CommandBatchService.java:326)
	at org.redisson.misc.RedissonPromise.lambda$onComplete$0(RedissonPromise.java:187)
	...
	at org.redisson.misc.RedissonPromise.trySuccess(RedissonPromise.java:82)
	at org.redisson.command.RedisCommonBatchExecutor.handleResult(RedisCommonBatchExecutor.java:130)
	at org.redisson.command.RedisExecutor.checkAttemptPromise(RedisExecutor.java:447)
	at org.redisson.command.RedisExecutor.lambda$execute$3(RedisExecutor.java:169)
	at org.redisson.misc.RedissonPromise.lambda$onComplete$0(RedissonPromise.java:187)
	...
	at org.redisson.misc.RedissonPromise.trySuccess(RedissonPromise.java:82)
	at org.redisson.client.handler.CommandDecoder.decodeCommandBatch(CommandDecoder.java:293)
	at org.redisson.client.handler.CommandDecoder.decodeCommand(CommandDecoder.java:188)
	at org.redisson.client.handler.CommandDecoder.decode(CommandDecoder.java:116)
	at org.redisson.client.handler.CommandDecoder.decode(CommandDecoder.java:101)
	...
```

可以看到，这个异常堆栈很诡异，异常堆栈里没有任何我编写的代码的痕迹，全是`Redisson`和`Netty`的代码。

# 排查问题
## 求助搜索引擎
网上大部分都是锁使用方式不对，测试代码已经是最简化的了，正常执行的情况下不会有任何报错。

## 异常信息里有node id和thread id
先解释下这里的两个参数
- `node id`是构造锁对象时，拿到的连接管理器`id`
- `thread id`是当前线程`id`

所以我开始怀疑是否是因为`debug`模式下，导致这两个`id`发生了变化。

`thread id`好拿，使用`Thread.currentThread().getId()`就拿到了。
`node id`要去构造函数里面获取。
```java
// org.redisson.RedissonBaseLock
public abstract class RedissonBaseLock extends RedissonExpirable implements RLock {
    public RedissonBaseLock(CommandAsyncExecutor commandExecutor, String name) {
        super(commandExecutor, name);
        this.commandExecutor = commandExecutor;
        this.id = commandExecutor.getConnectionManager().getId();
        // 这里打断点, 得到node id为ef35f099-4f38-48c2-93d6-2136b8c160aa
    }
}
```

一通折腾完，发现`node id`和`thread id`根本没变。

## 分析异常堆栈
查看最顶层的异常堆栈位置
`at org.redisson.RedissonBaseLock.lambda$unlockAsync$1(RedissonBaseLock.java:312)`
```java
// org.redisson.RedissonBaseLock
public abstract class RedissonBaseLock extends RedissonExpirable implements RLock {
    @Override
    public RFuture<Void> unlockAsync(long threadId) {
        RPromise<Void> result = new RedissonPromise<>();
        RFuture<Boolean> future = unlockInnerAsync(threadId);
        future.onComplete((opStatus, e) -> {
            // 省略部分代码
            if (opStatus == null) { // 关注这里
                IllegalMonitorStateException cause = new IllegalMonitorStateException("attempt to unlock lock, not locked by current thread by node id: " + id + " thread-id: " + threadId);
                result.tryFailure(cause);
                return;
            }
            // 省略部分代码
        });
        return result;
    }
}
```
很明显，只有`opStatus`为`null`时才会进入这个`if`判断里。
这个`onComplete`明显是`unlockInnerAsync`异步解锁完成后的回调函数，那么是哪里调用了这个回调函数呢？
我们在这个`if`判断这里打个断点。里面有一些`netty`的代码，先跳过。

```java
// org.redisson.RedissonBaseLock
public abstract class RedissonBaseLock extends RedissonExpirable implements RLock {
    protected <T> RFuture<T> evalWriteAsync(String key, Codec codec, RedisCommand<T> evalCommandType, String script, List<Object> keys, Object... params) {
        CommandBatchService executorService = createCommandBatchService();
        // redis异步执行lua脚本
        RFuture<T> result = executorService.evalWriteAsync(key, codec, evalCommandType, script, keys, params);
        if (commandExecutor instanceof CommandBatchService) {
            return result;
        }
        RPromise<T> r = new RedissonPromise<>();
        RFuture<BatchResult<?>> future = executorService.executeAsync();
        future.onComplete((res, ex) -> {
            if (ex != null) {
                r.tryFailure(ex);
                return;
            }
            // 关注这里，这里的result.getNow()就是上面拿到的opStatus
            r.trySuccess(result.getNow());
        });
        return r;
    }
}
```
我们猜，这里的`result.getNow()`就是上面回调函数的入参`opStatus`，实际上如果你跟着我打断点，可以确定这个猜想是正确的。
这个`result`是`Redis`异步执行解锁`Lua`脚本的时候返回的。我们看看解锁脚本
```java
// org.redisson.RedissonLock
public class RedissonLock extends RedissonBaseLock {
    protected RFuture<Boolean> unlockInnerAsync(long threadId) {
        return evalWriteAsync(getRawName(), LongCodec.INSTANCE, RedisCommands.EVAL_BOOLEAN,
                "if (redis.call('hexists', KEYS[1], ARGV[3]) == 0) then " +
                        "return nil;" +
                        "end; " +
                        "local counter = redis.call('hincrby', KEYS[1], ARGV[3], -1); " +
                        "if (counter > 0) then " +
                        "redis.call('pexpire', KEYS[1], ARGV[2]); " +
                        "return 0; " +
                        "else " +
                        "redis.call('del', KEYS[1]); " +
                        "redis.call('publish', KEYS[2], ARGV[1]); " +
                        "return 1; " +
                        "end; " +
                        "return nil;",
                Arrays.asList(getRawName(), getChannelName()), LockPubSub.UNLOCK_MESSAGE, internalLockLeaseTime, getLockName(threadId));
    }
}
```

可以看到`hexists`不存在的时候才会返回`null`。也就是`Redis`锁数据丢失了。
使用`redis-cli -h 127.0.0.1`命令上去看看，果然`get`不到数据了。
所以是因为`Redis`锁数据丢失，才导致异步解锁失败，抛出了异常。

# 问题根因
那么很奇怪，为什么加的锁为什么在`debug`模式会丢失数据呢？为什么不打断点就不会丢数据，而打断点就会丢失数据呢？

这里就涉及了`Redission`锁的自动续期机制，叫做`watch dog`。
简单的说，`Redission`默认加锁的存活时间是`30秒`，然后后台会有一个定时任务给这个`Redis Key`续期。

当我们打了断点后，`watch dog`就暂停了，无法对锁进行续期，导致加的锁在超出一定时间后就自动过期失效了。
后面放开断点，再去解锁，就解锁异常了。

线上环境是不允许打断点的，所以不会有这个问题。