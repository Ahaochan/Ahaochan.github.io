---
title: 使用scan代替keys获取所有key
url: Use_scan_instead_of_keys_to_get_all_the_keys
tags:
  - Redis
categories:
  - Redis
date: 2019-06-30 16:09:00
---

# 介绍
`Redis`的`keys`命令可以获取所有的`key`, 时间复杂度是`O(n)`, 一旦数据量大了, 因为`Redis`是单线程的, 就会导致`Redis`阻塞的情况.
为了解决阻塞问题, `Redis 2.8.0`推出了`scan`命令, `scan`可以返回默认大小为`10`的`key`, 并返回一个游标, 作为下次调用`scan`的参数.

<!-- more -->

# 使用
```bash
127.0.0.1:6379> mset k1 v1 k2 v2 k3 v3 k4 v4 k5 v5 k6 v6 k7 v7 k8 v8 k9 v9 k10 v10 k11 v11 k12 v12 k13 v13 k14 v14
127.0.0.1:6379> keys *
 1) "k14"
 2) "k1"
 3) "k13"
 4) "k5"
 5) "k2"
 6) "k12"
 7) "k11"
 8) "k10"
 9) "k4"
10) "k8"
11) "k9"
12) "k3"
13) "k6"
14) "k7"
127.0.0.1:6379> scan 0 match * count 10
1) "11"
2)  1) "k5"
    2) "k3"
    3) "k6"
    4) "k7"
    5) "k1"
    6) "k11"
    7) "k14"
    8) "k12"
    9) "k2"
   10) "k13"
127.0.0.1:6379> scan 11 match * count 10
1) "0"
2) 1) "k10"
   2) "k4"
   3) "k8"
   4) "k9"
```
初始化一堆`key`
1. 用`keys`命令获取到所有的`key`
1. 用`scan`命令**两次**获取到所有的`key`

# 多线程下原子性问题思考
我们在上面使用了两次`scan`命令, 就说明在这两次`scan`中, 可能会发生`set`或者`del`操作, 不是一个原子性操作.
> Elements that were not constantly present in the collection during a full iteration, may be returned or not: it is undefined.

根据[官方文档](https://redis.io/commands/scan), 也就是说, 如果在`scan`过程中`set`或`del`了某个`key`, 那么这个`key`就变成了玄学状态. 可能被返回, 也可能不被返回.
```bash
127.0.0.1:6379> scan 0 match * count 10
1) "11"
2)  1) "k5"
    2) "k3"
    3) "k6"
    4) "k7"
    5) "k1"
    6) "k11"
    7) "k14"
    8) "k12"
    9) "k2"
   10) "k13"
127.0.0.1:6379> set k15 v15
OK
127.0.0.1:6379> scan 11 match * count 10
1) "0"
2) 1) "k10"
   2) "k4"
   3) "k8"
   4) "k9"

127.0.0.1:6379> scan 0 match * count 10
1) "13"
2)  1) "k5"
    2) "k3"
    3) "k6"
    4) "k7"
    5) "k1"
    6) "k11"
    7) "k14"
    8) "k15"
    9) "k12"
   10) "k2"
127.0.0.1:6379> scan 13 match * count 10
1) "0"
2) 1) "k13"
   2) "k10"
   3) "k4"
   4) "k8"
   5) "k9"
```
可以看到, `k15`没有在第一次扫描时返回, 而在第二次扫描时返回.
所以这个玄学状态, 应该是取决于`set`或`del`的元素的位置.

# 整合 Spring Data Redis
```java
public class Main {
    public void scan(String pattern, Consumer<String> consumer) {
        RedisSerializer<String> keySerializer = (RedisSerializer<String>) stringRedisTemplate.getKeySerializer();

        ScanOptions options = ScanOptions.scanOptions().match(pattern).count(10).build();
        try(Cursor<String> cursor = getStringRedisTemplate().executeWithStickyConnection((RedisCallback<Cursor<String>>) connection ->
            new ConvertingCursor<>(connection.scan(options), keySerializer::deserialize))) {

            if(cursor == null) {
                return;
            }
            while (cursor.hasNext()) {
                String key = cursor.next();
                consumer.accept(key);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```
整合到`Spring Data Redis`中就是这样, 奇怪的是, 最新的`Spring Data Redis 2.1.6`实现了`hscan`命令, 但是却没有实现`scan`, 只能自己写`execute`实现了.
可以参考我的工具类集合[`RedisHelper`](https://github.com/Ahaochan/ahao-common-utils/blob/master/src/main/java/com/ahao/util/spring/redis/RedisHelper.java).

# 参考资料
- [scan 官方文档](https://redis.io/commands/scan)
