---
title: ThreadPoolExecutor源码分析
url: ThreadPoolExecutor_source_code
tags:
  - 源码分析
categories:
  - Java SE
date: 2018-12-13 00:10:00
---

# 前言
`ThreadPoolExecutor`是一个线程池的实现.
`Java`提供了`Executors`工厂类来创建`ExecutorService`线程池实例。

<!-- more -->

![](https://yuml.me/diagram/nofunky/class/[<<Executor>>]^-.-[<<ExecutorService>>],[<<ExecutorService>>]^-.-[AbstractExecutorService],[AbstractExecutorService]^-[ThreadPoolExecutor])


# 构造函数
`ThreadPoolExecutor`的构造方法如下
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    public ThreadPoolExecutor(int corePoolSize, int maximumPoolSize,
                              long keepAliveTime, TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler) {
    }
}
```
把线程池想象一个水壶, `corePoolSize`就相当于液面警戒线, 虽然满了还可以再加水, 但是不可能超过水壶的极限高度`maximumPoolSize`.
`keepAliveTime`则是允许线程空闲下来的时间, `TimeUnit`是时间单位.
`workQueue`是阻塞队列, 用于存储超过`corePoolSize`但是未满`maximumPoolSize`的线程.
`threadFactory`用于创建线程池内的线程, 默认是`DefaultThreadFactory`
`handler`是拒绝策略, 用于回调执行添加线程失败的代码. 

# 线程池内部状态流转
`Java`中的`int`类型有`32`位, `ThreadPoolExecutor`使用`ctl`的高`3`位表示线程池的运行状态, 低`29`位表示线程池中的线程数.
线程池的状态有:
1. `RUNNING`: 运行状态, 可以接收任务
1. `SHUTDOWN`: 调用了`shutdown()`方法后的状态, 等待所有任务执行完毕后关闭线程池.
1. `STOP`: 调用了`shutdownNow()`方法后的状态, 强制结束所有任务并关闭线程池.
1. `TIDYING`: 空闲状态, 所有任务都执行完毕。
1. `TERMINATED`: 终止状态，调用了`terminated()`方法后的状态.
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
    private static final int COUNT_BITS = Integer.SIZE - 3;      // 29
    private static final int CAPACITY   = (1 << COUNT_BITS) - 1; // 11111111111111111111111111111, 29位全1

    // runState is stored in the high-order bits
    private static final int RUNNING    = -1 << COUNT_BITS;    // 111 
    private static final int SHUTDOWN   =  0 << COUNT_BITS;    // 000
    private static final int STOP       =  1 << COUNT_BITS;    // 001
    private static final int TIDYING    =  2 << COUNT_BITS;    // 010
    private static final int TERMINATED =  3 << COUNT_BITS;    // 011

    // Packing and unpacking ctl
    // 获取运行状态, 高3位
    private static int runStateOf(int c)     { return c & ~CAPACITY; }
    // 获取线程数量, 低29位
    private static int workerCountOf(int c)  { return c & CAPACITY; }
    // 获取 ctl 变量, 组合 高3位 和 低29位
    private static int ctlOf(int rs, int wc) { return rs | wc; }
}
```
下面`3`个静态方法用于拆分和组合**运行状态**和**线程数量**.
假设线程池运行状态为`RUNING`, 线程池内有`2`个线程.
那么`ctl`变量的值的二进制形式就是`111 00000000000000000000000000010`.
根据`ctl`获取运行状态: `rs = runStateOf(ctl)   `得到`111 00000000000000000000000000000`
根据`ctl`获取线程数量: `wc = workerCountOf(ctl)`得到`000 00000000000000000000000000010`
如果之后需要根据`rs`和`wc`获取`ctl`, 则调用`ctl = ctlOf(rs, wc)`得到`111 00000000000000000000000000010`

# 添加一个Runnable
## execute(Runnable command)
`ThreadPoolExecutor`实现了`Executor`接口的唯一一个方法`void execute(Runnable command)`;
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
    public void execute(Runnable command) {
        int c = ctl.get();
        // 1. 判断当前线程数量 是否小于 核心线程数量, 尝试添加线程到核心线程池
        //    添加到核心线程池失败 或者 核心线程池满了, 则继续往下走
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true))
                return;
            c = ctl.get();
        }
        // 2. 判断线程池状态是 RUNNING, 往阻塞队列添加这个 Runnable 
        if (isRunning(c) && workQueue.offer(command)) {
            int recheck = ctl.get();
            // 2.1. 判断线程池不是RUNNING, 则从队列删除这个 Runnable, 并调用 reject 回调方法
            if (! isRunning(recheck) && remove(command))
                reject(command);
            // 2.2. 判断线程池内的线程数量如果为0, 则创建一个非核心线程
            else if (workerCountOf(recheck) == 0)
                addWorker(null, false);
        }
        // 3. 如果线程池状态不是 RUNNING, 或者阻塞队列添加失败
        //    尝试添加 Runnable 到非核心线程池, 如果还是失败, 则调用 reject 回调方法
        else if (!addWorker(command, false))
            reject(command);
    }
}
```
1. 只要`Core Pool`没有填满, 线程池就会一直创建线程到`Core Pool`中.
2. 一旦`Core Pool`填满了, 就添加到阻塞队列(构造函数传入)中.
    2.2. 如果添加到阻塞队列成功, 且当前线程池的线程数为0, 则创建一个非`Core`线程.
    3.   如果添加到阻塞队列失败, 尝试创建一个非`Core`线程, 仍然失败则调用`reject`处理器(构造函数传入)的回调函数.

简单点说, 线程池会先填满`corePoolSize`, 再填满队列, 再填满`maximumPoolSize`, 如果还有则调用`reject`回调方法.

## addWorker(Runnable firstTask, boolean core)
上面的代码一直围绕着`addWorker`方法, 这个方法可以创建`Core`线程和非`Core`线程.
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    private boolean addWorker(Runnable firstTask, boolean core) {
        // 1. 省略以上代码, 都是对状态进行判断, 判断是否可以添加 Worker, 不复杂, 就是绕

        boolean workerStarted = false;
        boolean workerAdded = false;
        Worker w = null;
        try {
            // 2. 创建 Worker 实例, 线程池中的线程都是 Worker
            w = new Worker(firstTask);
            final Thread t = w.thread; // 这个线程是用 ThreadFactory 创建的
            if (t != null) {
                // 3. HashSet 不是线程安全的, 加锁, 添加到 HashSet 中
                // 省略部分代码
                final ReentrantLock mainLock = this.mainLock;
                mainLock.lock();
                workers.add(w);
                mainLock.unlock();
                // 4. 执行线程
                t.start();
                workerStarted = true;
            }
        } finally {
            if (! workerStarted)
                addWorkerFailed(w);
        }
        return workerStarted;
    }
}
```
从上面代码可以看出, `Core`线程和非`Core`线程本质都是一个`Worker`, 甚至这个`Worker`都没有属性来标识是否为`Core`线程, 而是通过一堆线程池状态来判断创建的是`Core`线程还是非`Core`线程.

创建完后就执行这个`Worker`线程, 从阻塞队列里不停的取任务来执行.

## Worker
`Worker`是`ThreadPoolExecutor`的内部类. 
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    private final class Worker extends AbstractQueuedSynchronizer implements Runnable {
        final Thread thread; // ThreadFactory 创建的线程
        Runnable firstTask;  // 提交到线程池里的任务
        Worker(Runnable firstTask) {
            setState(-1); // inhibit interrupts until runWorker
            this.firstTask = firstTask;
            this.thread = getThreadFactory().newThread(this);
        }
        public void run() {
            runWorker(this);
        }
        // 省略部分代码
    }
}
```

## runWorker(Worker w)
间接调用了`ThreadPoolExecutor`的`runWorker`方法.
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    final void runWorker(Worker w) {
        Thread wt = Thread.currentThread();
        Runnable task = w.firstTask;
        w.firstTask = null;
        w.unlock(); // allow interrupts
        boolean completedAbruptly = true;
        try {
            // 1. 先执行Worker的任务, 然后从队列中循环取出任务
            while (task != null || (task = getTask()) != null) {
                w.lock();
                try {
                    beforeExecute(wt, task); // 交给子类扩展, 空方法体
                    task.run();
                    afterExecute(task, thrown); // 交给子类扩展, 空方法体
                } finally {
                    task = null;
                    w.completedTasks++;
                    w.unlock();
                }
            }
            completedAbruptly = false;
        } finally {
            processWorkerExit(w, completedAbruptly);
        }
    }
}
```
直接调用了`run`方法, 完成线程任务.

## getTask()
`getTask()`从阻塞队列中获取提交到线程池的任务.
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    private Runnable getTask() {
        boolean timedOut = false; // Did the last poll() time out?

        for (;;) {
            int c = ctl.get();
            int wc = workerCountOf(c);

            // Are workers subject to culling?
            boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

            // 省略跳出循环的代码, timedOut 为 true 则 return null
            try {
                Runnable r = timed ?
                    workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
                    workQueue.take();
                if (r != null)
                    return r;
                timedOut = true;
            } catch (InterruptedException retry) {
                timedOut = false;
            }
        }
    }
}
```
`poll`方法支持延迟从队列中获取元素, `take`则马上从队列中获取元素.
当超时后, `getTask()`返回`null`, 则`runWorker`方法的无限循环也跑不下去了, 自然就结束了这个线程.

一个交给线程池的线程就执行完毕了. 省略了很多状态转换的代码, 如果看不懂可以结合源码阅读。

# 关闭线程池
关闭线程池有两种方法`shutdown()`和`shutdownNow()`.
参考资料提到了一种优雅的关闭线程池的方法, 如下:
```java
long start = System.currentTimeMillis();
for (int i = 0; i <= 5; i++) {
    pool.execute(new Job());
}

pool.shutdown();

while (!pool.awaitTermination(1, TimeUnit.SECONDS)) {
    logger.info("线程还在执行。。。");
}
long end = System.currentTimeMillis();
logger.info("一共处理了【{}】", (end - start));
```

# 参考资料
- [ThreadPoolExecutor](https://github.com/crossoverJie/JCSprout/blob/master/MD/ThreadPoolExecutor.md)
- [深入理解Java线程池原理分析与使用（尤其当线程队列满了之后事项）](https://blog.csdn.net/u010963948/article/details/80573898)
