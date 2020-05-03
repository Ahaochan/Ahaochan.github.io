---
title: ThreadLocal源码分析以及线程池下的使用问题
url: ThreadLocal_source_code
tags:
  - 源码分析
categories:
  - Java SE
date: 2020-05-03 20:15:00
---

# 前言
如果我想要在多线程下, 同一个变量在不同线程下使用不同的值, 如何去做?
我可以声明一个`Map`, 线程作为`Key`, `Map`作为`value`, 存储当前线程下的键值对.
下面是一个简单的例子(生产不要这样用)

<!-- more -->

```java
public class ThreadMap {
    public static Map<Thread, Map<String, Object>> map = new HashMap<>();
    public static void set(String key, Object value) {
        map.get(Thread.currentThread()).put(key, value);
    }
    public static Object get(String key) {
        return map.get(Thread.currentThread()).get(key);
    }
}
```
是不是很简单? 但是我们不需要去重复造轮子.
`JDK`早就给我们实现了一套轮子, 本质和我写的这个`Demo`是一样的.

# ThreadLocal 实现线程隔离

## 测试用例
我们来看个简单的[单元测试例子](https://github.com/Ahaochan/project/blob/master/ahao-spring-boot-async/src/test/java/com/ahao/spring/boot/async/ThreadLocalTest.java)
```java
public class ThreadLocalTest {
    @Test
    public void threadLocal1() throws Exception {
        ThreadLocal<String> context = new ThreadLocal<>();

        Assertions.assertNull(context.get());
        String expectP = "hello " + DateHelper.getNow(DateHelper.yyyyMMdd_hhmmssSSS);
        context.set(expectP);
        
        Runnable runnable = () -> {
            Assertions.assertNull(context.get());
            String expect = "hello " + DateHelper.getNow(DateHelper.yyyyMMdd_hhmmssSSS);
            context.set(expect);
            String value = context.get();
            System.out.println(Thread.currentThread().getName() + " get " + value);
            Assertions.assertEquals(expect, value);
        };

        Thread thread1 = new Thread(runnable);
        thread1.start();
        thread1.join();

        Thread thread2 = new Thread(runnable);
        thread2.start();
        thread2.join();

        String value = context.get();
        System.out.println(Thread.currentThread().getName() + " get " + value);
        Assertions.assertEquals(expectP, value);
    }
}
```
执行完毕输出
```text
Thread-1 get hello 2020-04-19 00:54:44:249
Thread-2 get hello 2020-04-19 00:54:44:254
main get hello 2020-04-19 00:54:44:230
```
可以看到, 明明是同一个变量, 在不同线程下, 获取到的值却不一样.

## get 和 set 源码分析
关键点就在于`set`和`get`方法. 我们现在先来看`set`方法.
```java
// java.lang.ThreadLocal
public class ThreadLocal<T> {
    public void set(T value) {
        // 1. 获取当前线程作为key
        Thread t = Thread.currentThread();
        // 2. 获取一个以线程为key的Map
        ThreadLocalMap map = getMap(t);
        // 3. 设置Map的值
        if (map != null) map.set(this, value);
        else createMap(t, value);
    }
    ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }
    void createMap(Thread t, T firstValue) {
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }
}
```
可以看到和我一开始写的一样, 就是往一个`Map`里塞数据.
再看看`get`方法.
```java
// java.lang.ThreadLocal
public class ThreadLocal<T> {
    public T get() {
        // 1. 获取当前线程作为key
        Thread t = Thread.currentThread();
        // 2. 获取一个以线程为key的Map
        ThreadLocalMap map = getMap(t);
        // 3. 根据 key 获取 value
        if (map != null) {
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null) {
                return (T)e.value;
            }
        }
        // 4. 找不到就返回一个默认值, 默认为 null
        return setInitialValue();
    }
    ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }
}
```
也一样, 就是从一个`Map`里, 把当前线程作为`key`, 获取数据.

那么不同点来了, 就是这个`Map`的构造, 可以看到不是我用的`HashMap`.
而是当前线程里的`ThreadLocalMap`变量`threadLocals`.

## ThreadLocalMap 源码分析
`ThreadLocalMap`是`ThreadLocal`的静态内部类, 而每一个线程`Thread`都有各自的`ThreadLocalMap`成员变量.
```java
// java.lang.Thread
public class Thread implements Runnable {
    ThreadLocal.ThreadLocalMap threadLocals = null;
}
```
那我们继续来看`ThreadLocalMap`. 和普通的`HashMap`一样, 内部是一个节点数组.
```java
// java.lang.ThreadLocal
public class ThreadLocal<T> {
    static class ThreadLocalMap {
        // 1. 节点数组
        private Entry[] table;
        // 2. 弱引用, GC扫描到就回收掉 ThreadLocal 对象
        static class Entry extends WeakReference<ThreadLocal<?>> {
            Object value;
            Entry(ThreadLocal<?> k, Object v) {
                super(k);
                value = v;
            }
        }
    }
}
```
可以看到`ThreadLocalMap`是以`ThreadLocal`对象为`Key`, `Object`为`Value`的`Map`集合.
而`Entry`继承了弱引用`WeakReference`, 所以当每次`GC`发生时, 扫描到这个对象就会回收`ThreadLocal`. 但这里会有个问题, 会导致一些内存问题, 这里后面讲.

接下来是`ThreadLocalMap`的`set`和`get`方法, 和普通的`HashMap`差不多, 无非就是扩容, `rehash`那一套.
```java
public class ThreadLocal<T> {
    static class ThreadLocalMap {
        private void set(ThreadLocal<?> key, Object value) {
            // 1. 对 key 进行 hash, 获取 Entry 节点的下标
            Entry[] tab = table;
            int len = tab.length;
            int i = key.threadLocalHashCode & (len-1);

            // 2. 如果 hash 冲突, 就 开放定址法 找到下一个下标
            for (Entry e = tab[i]; e != null; e = tab[i = nextIndex(i, len)]) {
                ThreadLocal<?> k = e.get();
                if (k == key) {
                    e.value = value;
                    return;
                }
                // 2.1. 清除 null key 的节点
                if (k == null) {
                    replaceStaleEntry(key, value, i);
                    return;
                }
            }
            // 3. 往下标位置塞数据, 扩容, rehash 
            tab[i] = new Entry(key, value);
            int sz = ++size;
            if (!cleanSomeSlots(i, sz) && sz >= threshold)
                rehash();
        }
        private Entry getEntry(ThreadLocal<?> key) {
            // 1. 对 key 进行 hash, 获取 Entry 节点的下标
            int i = key.threadLocalHashCode & (table.length - 1);
            // 2. 从节点数组获取数据
            Entry e = table[i];
            if (e != null && e.get() == key)
                return e;
            else
                return getEntryAfterMiss(key, i, e);
        }
    }
}
```
值得注意的是, `ThreadLocalMap`的哈希冲突解决方案是**开放定址法**, 而不是`HashMap`的链表红黑树那套.

## ThreadLocal 为什么必须设置为 static ?
经常会听到一种言论, `ThreadLocal`必须设置为`static`静态变量, 否则会浪费内存的问题.

我们先来看一个[单元测试例子](https://github.com/Ahaochan/project/blob/master/ahao-spring-boot-async/src/test/java/com/ahao/spring/boot/async/ThreadLocalTest.java)
```java
public class ThreadLocalTest {
    public static final ThreadLocal<String> staticContext = new ThreadLocal<>();
    @Test
    public void staticVerify() throws Exception {
        // 1. 静态ThreadLocal 设置值
        Assertions.assertNull(staticContext.get());
        staticContext.set(Thread.currentThread().getName());

        Runnable runnable = () -> {
            // 2. 普通ThreadLocal 设置值
            ThreadLocal<String> context = new ThreadLocal<>();
            Thread thread = Thread.currentThread();

            staticContext.set(thread.getName());
            context.set(thread.getName());

            System.out.println(thread.getName() + " static get " + staticContext.get());
            System.out.println(thread.getName() + " get " + context.get()); // 打断点
        };

        Thread thread1 = new Thread(runnable);
        thread1.start();
        thread1.join();

        Thread thread2 = new Thread(runnable);
        thread2.start();
        thread2.join();

        String value = staticContext.get();
        Thread thread = Thread.currentThread();
        System.out.println(thread.getName() + " static get " + staticContext.get());
        Assertions.assertEquals(thread.getName(), value);
    }
}
```
我们打个断点看看`Thread`里的`ThreadLocalMap`的`Key`引用很容易就发现问题.
{% img /images/ThreadLocal源码分析以及线程池下的使用问题_01.png %}

当线程执行的时候, 线程的`ThreadLocalMap`持有两个`Entry`, 一个是静态的`ThreadLocal`, 一个是`new`出来的`ThreadLocal`.
可以看到，静态的`ThreadLocal`在`ThreadLocalMap`是固定的`hashcode`, 而另一个`ThreadLocal`是不同的`hashcode`，说明每次运行都会创建`ThreadLocal`。
虽然并不影响正常使用，但是用`static`修饰`ThreadLocal`可以减少对象的频繁创建，降低`GC`频率, 如果没有特殊要求, 还是用`static`最佳.

另外还有一点需要注意的是, `ThreadLocal`如果设置成`static`了, 就会被当前类对象强引用, 下面的内存泄漏问题会提到.

## ThreadLocal的 内存泄漏 问题
![ThreadLocal引用链](https://yuml.me/diagram/nofunky/class/[Thread]->[ThreadLocalMap],[ThreadLocalMap]->[Entry],[Entry]->[value])

我们注意到`ThreadLocalMap`的`Key`是`ThreadLocal`的弱引用对象. 也就是说, 不管`ThreadLocal`对象是否因为弱引用被`GC`回收, `Entry`节点都会持有`value`的强引用.
要回收掉`value`只有两种方法
1. 结束当前线程
2. 手动释放`Key`为`null`的`Entry`

在`ThreadLocal`的`set`、`get`、`remove`方法内都有对`Key`为`null`的`Entry`做清除引用的操作.

那为什么`Entry`的`Key`要做弱引用, 不直接强引用呢?
我们反推一下, 如果`Entry`的`Key`是强引用, 当`ThreadLocal`的外部强引用取消后, `ThreadLocalMap`内部的`Entry`还持有`ThreadLocal`的强引用.
那么`ThreadLocal`就一直不能被`GC`回收, 需要手动`remove`才能回收.
反之, 如果是弱引用, 那么`ThreadLocal`的外部强引用取消后, 因为`Entry`持有的是`ThreadLocal`的弱引用, 当发生`GC`时, 能及时回收掉`ThreadLocal`.
在下次`set`、`get`、`remove`方法做清除引用的操作.

## 总结
`Thread`线程有一个`ThreadLocalMap`成员变量, 这是一个存储了以`ThreadLocal`为`Key`, 值为`Value`的`Map`集合.
`ThreadLocal`的`set`和`get`方法, 本质是获取当前线程的`ThreadLocalMap`, 对这个`Map`进行操作, 做到线程隔离.

下面是一个简单的最佳实践.
```java
public class Main {
    public static final ThreadLocal<String> local = new ThreadLocal<>();
    public void test() {
        local.set("hello");
        try {
            // 业务操作
        } finally{
            local.remove();
        }
    }
}
```

# InheritableThreadLocal 实现父子线程变量共享
那如果我想要创建一个线程, 然后子线程继承父线程的变量, 要怎么做呢?
你可以看到在上面的单元测试用例中, 我使用了一个断言`Assertions.assertNull(context.get());`.

也就是说, 如果单单使用`ThreadLocal`, 子线程是不能获取到父线程的变量的.
其实这也很好理解, 线程都不一样, 线程对象里面的`Map`变量当然也不一样.

如果让我们来实现, 也很容易. 只要在创建线程的时候, 将父线程的`ThreadLocalMap`复制一份到子线程即可.
```java
public static class ThreadFactory {
    public static Thread createThread() {
        Thread parentThread = Thread.currentThread();
        Thread childThread = new Thread();

        // 复制 ThreadLocalMap
        childThread.threadLocals = parentThread.threadLocals.clone();
        
        return childThread;
    }
}
```
`JDK`内部已经实现了, 我们只要直接使用`InheritableThreadLocal`即可.

## InheritableThreadLocal 源码分析
`InheritableThreadLocal`继承了`ThreadLocal`, 并重写了`ThreadLocalMap`的相关方法.
```java
// java.lang.InheritableThreadLocal
public class InheritableThreadLocal<T> extends ThreadLocal<T> {
    protected T childValue(T parentValue) {
        return parentValue;
    }

    ThreadLocalMap getMap(Thread t) {
       return t.inheritableThreadLocals;
    }
    
    void createMap(Thread t, T firstValue) {
        t.inheritableThreadLocals = new ThreadLocalMap(this, firstValue);
    }
}
// java.lang.ThreadLocal
public class ThreadLocal<T> {
    ThreadLocalMap getMap(Thread t) {
        return t.threadLocals;
    }
    void createMap(Thread t, T firstValue) {
        t.threadLocals = new ThreadLocalMap(this, firstValue);
    }
}
```
我们可以看到, `InheritableThreadLocal`就是换了个变量操作, 它操作的是`inheritableThreadLocals`变量. 避免和`ThreadLocal`操作的变量冲突.
代码就短短几行, 没有涉及到我们说的**复制`ThreadLocalMap`**的操作.
那我们继续看下`Thread`的创建过程.

## Thread 创建
我们直接追源码, 这里省略部分非核心代码.
```java
// java.lang.Thread
public class Thread implements Runnable {
    public Thread() {
        init(null, null, "Thread-" + nextThreadNum(), 0);
    }
    private void init(ThreadGroup g, Runnable target, String name, long stackSize) {
        init(g, target, name, stackSize, null, true);
    }
    private void init(ThreadGroup g, Runnable target, String name, long stackSize, AccessControlContext acc,
                      boolean inheritThreadLocals) { // 注意这个 inheritThreadLocals 变量, 默认为 true
        // 1. 获取创建Thread变量的线程, 作为父线程
        Thread parent = currentThread();
        
        // 2. 如果父线程有 inheritableThreadLocals 的值, 那么就复制一份到子线程
        if (inheritThreadLocals && parent.inheritableThreadLocals != null)
            this.inheritableThreadLocals = new ThreadLocalMap(parent.inheritableThreadLocals);
    }
}
```
一目了然, 就是在`new Thread()`的时候, 从父线程中复制一份`ThreadLocalMap`到子线程.

# TransmittableThreadLocal 线程池子任务共享父线程的变量
`InheritableThreadLocal`解决了父子线程变量共享的问题, 但生产环境下, 我们一般都是用线程池来管理线程的.
这里就涉及到一个线程复用的问题.
`InheritableThreadLocal`只有在创建线程的时候才会将父线程的变量复制给子线程, 但是线程池的线程是复用的.
`new Thread()`之后, 可能会执行多个不同的任务. 这个时候就不能继承父线程的变量了.

还是老套路, 既然线程是复用的, 那我能不能在创建任务的时候, 存一份父线程数据, 在`run()`执行之前丢到子线程里去呢?
```java
public class RunnableWrapper implements Runnable {
    // 1. 创建一个 ThreadLocal, 用于暂存创建Runnable时父线程的数据, 在外部直接使用 RunnableWrapper.holder.set();
    public static ThreadLocal<Map<String, Object>> holder = ThreadLocal.withInitial(HashMap::new);

    private Map<String, Object> value;
    private Runnable runnable;
    public RunnableWrapper(Runnable runnable) {
        this.runnable = runnable;
        // 2. 创建任务的时候, 暂存父线程的数据
        this.value = holder.get();
    }

    @Override
    public void run() {
        // 3. 在子线程执行任务前, 将父线程的数据存入子线程
        holder.set(value);
        runnable.run();
    }
}
```
这里`JDK`可没有提供轮子了, 但是`Alibaba`提供了一个[`transmittable-thread-local`](https://github.com/alibaba/transmittable-thread-local)的轮子.

## 测试用例
我们来看个[单元测试例子](https://github.com/Ahaochan/project/blob/master/ahao-spring-boot-async/src/test/java/com/ahao/spring/boot/async/TtlTest.java)
```java
public class TtlTest {
    @Test
    public void wrapper() throws Exception {
        // 1. 创建 线程池 和 TransmittableThreadLocal
        ExecutorService executorService = Executors.newSingleThreadExecutor();
        TransmittableThreadLocal<String> context = new TransmittableThreadLocal<>();

        String expect = "hello " + DateHelper.getNow(DateHelper.yyyyMMdd_hhmmssSSS);
        context.set(expect);
        System.out.println("[parent thread] set " + context.get());
        Assertions.assertEquals(expect, context.get());

        // 2. 装饰 Runnable
        Runnable task = () -> {
            System.out.println("[child thread] get " + context.get() + " in Runnable");
            Assertions.assertEquals(expect, context.get());
        };
        TtlRunnable ttlRunnable = TtlRunnable.get(task);
        executorService.submit(ttlRunnable).get();

        // 3. 关闭线程池
        executorService.shutdown();
    }
}
```
执行完毕输出
```text
[parent thread] set hello 2020-04-19 00:54:44:230
[child thread] get hello 2020-04-19 00:54:44:230 in Runnable
```
可以看到, 尽管是在线程池里复用线程的情况, 依然能获取到父线程的变量.
如果觉得我只用一个`Runnable`样本不够, 可以自己多创建几百个`Runnable`.

陌生的类只有两个, `TtlRunnable`和`TransmittableThreadLocal`.

## TransmittableThreadLocal 的 set get 源码分析
我们先来看看`set`方法
```java
// com.alibaba.ttl.TransmittableThreadLocal
public class TransmittableThreadLocal<T> extends InheritableThreadLocal<T> implements TtlCopier<T> {
    public final void set(T value) {
        if (!disableIgnoreNullValueSemantics && null == value) {
            // may set null to remove value
            remove();
        } else {
            // 1. 调用 InheritableThreadLocal 的 set 方法, 保证子线程也能拿到数据
            super.set(value);
            // 2. 添加到 holder, 保证子任务能拿到数据
            addThisToHolder();
        }
    }
    private void addThisToHolder() {
        // 判断 holder 没有当前 ThreadLocal 则 put 一份
        if (!holder.get().containsKey(this)) {
            holder.get().put((TransmittableThreadLocal<Object>) this, null); // WeakHashMap supports null value.
        }
    }
    
    // 等价于 Map<线程, Map<ThreadLocal, null>>, 因为没有弱引用的Set, 所以用 WeakHashMap 代替
    private static InheritableThreadLocal<WeakHashMap<TransmittableThreadLocal<Object>, ?>> holder =
     new InheritableThreadLocal<WeakHashMap<TransmittableThreadLocal<Object>, ?>>() {
        @Override
        protected WeakHashMap<TransmittableThreadLocal<Object>, ?> initialValue() {
            return new WeakHashMap<TransmittableThreadLocal<Object>, Object>();
        }

        @Override
        protected WeakHashMap<TransmittableThreadLocal<Object>, ?> childValue(WeakHashMap<TransmittableThreadLocal<Object>, ?> parentValue) {
            return new WeakHashMap<TransmittableThreadLocal<Object>, Object>(parentValue);
        }
    };
}
```
`holder`存储了当前线程下的所有`TransmittableThreadLocal`对象, 并用`Set`去重.
有人看到这里可能有疑问, 上面没看到`Set`关键字. 是因为`JDK`没有弱引用的`Set`, 所以用`WeakHashMap`代替.

再来看看`get`方法, 也只是多了个`addThisToHolder`方法.
```java
// com.alibaba.ttl.TransmittableThreadLocal
public class TransmittableThreadLocal<T> extends InheritableThreadLocal<T> implements TtlCopier<T> {
    public final T get() {
        T value = super.get();
        if (disableIgnoreNullValueSemantics || null != value) addThisToHolder();
        return value;
    }
}
```

## TtlRunnable 源码分析 保存快照
既然上面设置了参数, 下面就要获取这些参数了.

```java
// com.alibaba.ttl.TtlRunnable
public final class TtlRunnable implements Runnable, TtlWrapper<Runnable>, TtlEnhanced, TtlAttachments {
    private final AtomicReference<Object> capturedRef;
    private final Runnable runnable;
    private final boolean releaseTtlValueReferenceAfterRun;
    private TtlRunnable(@NonNull Runnable runnable, boolean releaseTtlValueReferenceAfterRun) {
        // 1. 保存快照
        this.capturedRef = new AtomicReference<Object>(TransmittableThreadLocal.Transmitter.capture());
        this.runnable = runnable;
        this.releaseTtlValueReferenceAfterRun = releaseTtlValueReferenceAfterRun;
    }
    @Override
    public void run() {
        // 2. 获取快照
        Object captured = capturedRef.get();
        if (captured == null || releaseTtlValueReferenceAfterRun && !capturedRef.compareAndSet(captured, null)) {
            throw new IllegalStateException("TTL value reference is released after run!");
        }

        // 3. 保存到当前线程
        Object backup = TransmittableThreadLocal.Transmitter.replay(captured);
        try {
            runnable.run();
        } finally {
            TransmittableThreadLocal.Transmitter.restore(backup);
        }
    }
}
```
顺着开头提到的思路, 在`Runnable`创建时, 先对父线程的变量做一个快照, 在`run`执行时, 复制到新线程里.

那么第一步, 做快照, 关键就是这个`TransmittableThreadLocal.Transmitter.capture()`方法.
```java
public class TransmittableThreadLocal<T> extends InheritableThreadLocal<T> implements TtlCopier<T> {
    public static class Transmitter {
        public static Object capture() {
            // 1. captureTtlValues() 对当前线程下的所有 TransmittableThreadLocal 做一个快照
            // 2. TODO captureThreadLocalValues() 这个操作的是另一个变量, 目前这个场景没用到 
            return new Snapshot(captureTtlValues(), captureThreadLocalValues());
        }
        private static WeakHashMap<TransmittableThreadLocal<Object>, Object> captureTtlValues() {
            WeakHashMap<TransmittableThreadLocal<Object>, Object> ttl2Value = new WeakHashMap<TransmittableThreadLocal<Object>, Object>();
            for (TransmittableThreadLocal<Object> threadLocal : holder.get().keySet()) {
                ttl2Value.put(threadLocal, threadLocal.copyValue()); // 对当前线程下的所有 TransmittableThreadLocal 做一个快照
            }
            return ttl2Value;
        }
        private static class Snapshot {
            final WeakHashMap<TransmittableThreadLocal<Object>, Object> ttl2Value;
            final WeakHashMap<ThreadLocal<Object>, Object> threadLocal2Value;
            private Snapshot(WeakHashMap<TransmittableThreadLocal<Object>, Object> ttl2Value, WeakHashMap<ThreadLocal<Object>, Object> threadLocal2Value) {
                this.ttl2Value = ttl2Value;
                this.threadLocal2Value = threadLocal2Value;
            }
        }
    }
}
```

第二步, 执行`run`方法的时候, 取出快照, 并保存到当前线程
```java
public class TransmittableThreadLocal<T> extends InheritableThreadLocal<T> implements TtlCopier<T> {
    public static class Transmitter {
        @NonNull
        public static Object replay(@NonNull Object captured) {
            final Snapshot capturedSnapshot = (Snapshot) captured;
            return new Snapshot(replayTtlValues(capturedSnapshot.ttl2Value), replayThreadLocalValues(capturedSnapshot.threadLocal2Value));
        }

        @NonNull
        private static WeakHashMap<TransmittableThreadLocal<Object>, Object> replayTtlValues(@NonNull WeakHashMap<TransmittableThreadLocal<Object>, Object> captured) {
            WeakHashMap<TransmittableThreadLocal<Object>, Object> backup = new WeakHashMap<TransmittableThreadLocal<Object>, Object>();
            // 省略部分代码
            
            // 精华! 从快照中获取 ThreadLocal 再重新 set 到当前线程
            for (Map.Entry<TransmittableThreadLocal<Object>, Object> entry : captured.entrySet()) {
                TransmittableThreadLocal<Object> threadLocal = entry.getKey();
                threadLocal.set(entry.getValue());
            }
            
            // 省略部分代码
            return backup;
        }
    }
}
```
老实说, 看到这里的代码, 不由让我惊叹. 这个`for`循环, 太神了.
如此一来, 就将之前保存的`ThreadLocal`快照, 在执行这个`Runnable`的线程重新复制了一遍.

# 总结
`ThreadLocal`算是高频面试考点, 并且一个用的不小心就会造成线上生产问题. 使用的时候只要注意套模版就可以了.
1. `static`修饰`ThreadLocal`
2. `set`之后要用`try {} finally {}`做`remove`
3. 线程池要用`TransmittableThreadLocal`来传递变量.

另外, `Netty`还有一个`FastThreadLocal`的东西, 不过没有涉及本篇的线程变量传递的主题, 所以就不讲了.
