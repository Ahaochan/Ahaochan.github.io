---
title: Linux下的定时任务
url: Timing_tasks_of_Linux
tags:
  - Linux
categories:
  - Linux
date: 2018-02-03 17:17:46
---
# 前言
同步数据之类的工作需要定时去完成, 如果要人工去做, 那是费时费力的。
既然是定时, 有规律可循, 那就应该使用编程完成, 而不是依赖人力完成。
`Java` 有 `Quartz` 可以完成。`Linux` 和 `Windows` 也有相同的工具。

<!-- more -->

# 一次执行和多次执行
一次执行: `at`命令, 需要`atd`服务的支持。
多次执行: `crontab`命令, 需要`crond`服务的支持。

# 只执行一次的定时任务
## 打开atd服务
```sh
# 确保打开 atd
[root@localhost ~]# /etc/init.d/atd restart
停止 atd：                                                 [确定]
启动 atd：                                                 [确定]
# 将启动 atd 服务写入配置文件, 开机自动打开
[root@localhost  ~]# chkconfig atd on
```

## 指定允许使用at的用户
`at` 有两个重要的文件, 用来限制可以使用`at`定时任务的用户。
一个用户名占一行。
`/etc/at.allow`白名单和`/etc/at.deny`黑名单。
`at`根据文件是否存在判断使用白名单或者黑名单。

| `/etc/at.allow` | `/etc/at.deny` | 说明 |
|:------------------:|:-----------------:|:--:|
| √                     | 无论是否存在 | 只允许`/etc/at.allow`的用户执行`at` |
| ×                     | √                     | 禁止`/etc/at.deny`的用户执行`at`     |
| ×                     | ×                     | 只有`root`能执行`at`                        |

## 例子
```sh
# 1. 创建一次性的5分钟后创建文件的定时任务
[root@localhost ~]# at -m now + 5 minutes 
at> cat 'now+5minutes file' > /tmp/now+5minutes.file
at> echo 'execute at task' # 使用 -m 选项可以将输出信息发送到email中
at> <EOT> # 按Ctrl+D结束输入
job 6 at 2017-10-19 04:31

# 2. 查看at定时任务队列(queue), 或者 at -l
[root@localhost ~]# atq
6	2017-10-19 04:31 a root

# 3. 查询定时任务的内容, -c 指定任务号
[root@localhost ~]# at -c 6
#!/bin/sh
# 省略一堆环境变量
# 进入创建定时任务时所在的文件夹
cd /root || {
	 echo 'Execution directory inaccessible' >&2
	 exit 1
}
cat 'now+5minutes file' > /tmp/now+5minutes.file
echo 'execute at task'

# 4. 根据任务号6, 移除(remove)定时任务
[root@localhost ~]# atrm 6
# 5. 再次查看任务列表, 没有定时任务, 已经被删除了
[root@localhost ~]# atq
```

## 其他的时间格式
除了用`now + 5 minutes`指定时间外, 还有其他的时间格式

| 时间格式 | 说明 |
|:---:|:---:|
| HH:MM | 在HH时MM分执行一次 |
| HH:MM YYYY-MM-DD | 在YYYY年MM月DD日HH时MM分执行一次 |
| HH:MM[am/pm] [Month] [Date] | 在Month月Date日早上/下午HH时MM分执行一次, 月份是**英文**表示 |
| HH:MM[am/pm] + number [minutes/hours/days/weeks] | 在早上/下午HH时MM分的number分钟/小时/天/周后执行一次 |

## batch空闲时运行
`batch`可以控制在工作负载低于`0.8`的时候执行一次定时任务。
工作负载为1, 说明这个时间点有1个程序在运行。
工作负载为2, 说明这个时间点有2个程序在运行。
负载越高, 说明CPU单位时间内切换程序的次数越多。
当然, 程序不可能一直在运算, 所以也有低于1的情况产生。
`batch`可以避免在程序繁忙的时候执行一些操作, 比如定时重启。让定时任务延后运行。
可以看到最后一行代码是执行了`at`命令, 只是附带了一些参数而已。
和`at`命令一样的用法。
```sh
[root@localhost ~]# nl /usr/bin/batch
42  exec /usr/bin/at $OPT_f $OPT_m $OPT_q $OPT_v $OPT_V $time_date_arg
```

# 多次执行的定时任务
`Java`下有`Quartz`这个定时任务框架, 也使用到了`corn`表达式。
`Linux`下的多次执行的定时任务是通过`cron`服务实现的。
检查`crontab`工具是否安装: `crontab -l`
检查`crond`服务是否启动: `service  crond status`

## 指定允许使用cron的用户
和`at`一样, `cron`也有两个文件用来限制可以使用`cron`定时任务的用户。
一个用户名占一行。
`/etc/cron.allow`白名单和`/etc/cron.deny`黑名单。

| `/etc/cron.allow` | `/etc/cron.deny` | 说明 |
|:------------------:|:-----------------:|:--:|
| √                     | 无论是否存在 | 只允许`/etc/cron.allow`的用户执行`cron` |
| ×                     | √                     | 禁止`/etc/cron.deny`的用户执行`cron`     |
| ×                     | ×                     | 只有`root`能执行`cron`                        |

## 配置文件
`/etc/crontab`文件存储了**系统**的定时任务
`/var/spool/cron/用户名`文件存储了各个**用户**的定时任务
`/etc/cron.allow`文件指定了允许执行定时任务的**白名单**
`/etc/cron.deny`文件指定了允许执行定时任务的**黑名单**

通过查看`/etc/crontab`可以看到看到**系统**的定时任务
```sh
[root@localhost ~]# cat /etc/crontab 
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/

# run-parts 后面跟一个目录, 可以执行目录下所有可执行文件
01 * * * * root run-parts /etc/cron.hourly
02 4 * * * root run-parts /etc/cron.daily
22 4 * * 0 root run-parts /etc/cron.weekly
42 4 1 * * root run-parts /etc/cron.monthly
```

# cron表达式
从上可以看出cron表达式的格式如下

|  | 分 | 时 | 日 | 月 | 星期几 | 用户名 | 命令 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 取值范围 | 0~59 | 0~23 | 1~31 | 1~12 | 0~7(0或7都是星期天) | 可选 | 命令 |

```sh
[root@localhost ~]# who
ahao     pts/1        2017-10-19 06:40 (192.168.94.121)

# 1. 编辑任务, 每分钟输出一次hello到终端屏幕/dev/pts/1上
[root@localhost ~]# crontab -e
*/1 * * * * echo 'hello' > /dev/pts/1

# 2. 查看定时任务列表
[root@localhost ~]# crontab -l
*/1 * * * * echo 'hello' > /dev/pts/1

# 3. 清空定时任务, 单项删除用 crontab -e 编辑
[root@localhost ~]# crontab -r
```

## 例子
具体的用法, 只要看懂下面几个例子就行了
```sh
# 每天21:30重启apache
30 21 * * * service httpd restart

# 每月1、10、22日4:45重启apache, 逗号表示或
45 4 1,10,22 * * service httpd restart

# 每月的1-10日4:45重启apache, 横杠表示区间
45 4 1-10 * * service httpd restart

# 每隔2分钟重启apache, 斜杠表示每隔一段时间
*/2 * * * * service httpd restart

# 每天23点到7点每隔1小时重启apache
0 23-7/1 * * * service httpd restart

# 每天18:00到23:00每隔30分钟重启apache
*/30 18-23 * * * service httpd restart

# 4月的1-7号或每个星期日早晨1时59分重启apache
59 1 1-7 * 4 0 service httpd restart

# 4月的第1个星期日早晨1时59分重启apache, 第三个时间位置和第五个时间位置是【或】的关系
59 1 1-7 4 * test $(date +%w) -eq 0 && service httpd restart

# 每30秒重启apache, 通过sleep进行精确到秒级的操作, 注意要两个任务都存在
*/1 * * * * service httpd restart
*/1 * * * * sleep 30s; service httpd restart
```

# 参考资料
- [at命令](http://man.linuxde.net/at)
- [crontab命令](http://man.linuxde.net/crontab)