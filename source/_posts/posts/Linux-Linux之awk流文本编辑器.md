---
title: Linux之awk流文本编辑器
url: awk_of_Linux
tags:
  - Linux
categories:
  - Linux
date: 2018-03-19 21:54:59
---
# 前言
`awk`是`Unix`的行处理命令, 以**行**为单位, 依次读入文本的每行进行切片处理。
```sh
# 复制测试文件
[root@localhost ~]# cp /etc/passwd /tmp/passwd
```

<!-- more -->

# 使用格式
```
awk [option] '[BEGIN{awk 操作命令}]pattern{awk 操作命令}[END{awk 操作命令}]' file(s)
```
`BEGIN{awk 操作命令}`: 可选的, 前置操作, 在执行`pattern`循环之前执行。
`END{awk 操作命令}`:   可选的, 后置操作, 在执行`pattern`循环之后执行。
`pattern{awk 操作命令}`: 必选的, 对每行进行处理。
`awk 操作命令`: 包括函数调用`printf()`, 控制指令`if else`等。

# 切片处理
所谓的**切片处理**, 举个例子就是`a:b:c`, 可以将`:`作为分隔符, 划分为`3`个片段。

`-F separator`选项: 指定`separator`作为分隔符, 默认为空格
`$n`变量: `$0`表示当前行的内容, `$n`表示当前行内, 以上面的`separator`分割的第`n`个片段
`NR`变量: 每行的行号, `The total number of input records seen so far.`
`NF`变量: 分割的片段的数量, `The number of fields in the current input record.`
`FILENAME`变量: 正在处理的文件名

```sh
# 1. 获取以 : 作为分隔符, 第3个片段, 即UID
awk -F ':' '{print $3}' /tmp/passwd
# 2. 获取以 : 作为分隔符, 第1和3个片段, 即用户名和UID
awk -F ':' '{print $1,$3}' /tmp/passwd
awk -F ':' '{print $1" "$3}' /tmp/passwd
awk -F ':' '{print "USER:"$1"\tUID:"$3}' /tmp/passwd
# 3. 输出每行的行号NR和片段数NF
awk -F ':' '{print NR"\t"NF"\tUSER:"$1"\tUID:"$3}' /tmp/passwd
# 4. 输出处理的文件名
awk -F ':' '{print FILENAME"\tUSER:"$1"\tUID:"$3}' /tmp/passwd
```

# pattern
`pattern`是每行前的一个匹配表达式。分为两种。
1. `~`, `!~`: 匹配正则表达式
2. `==`, `!=`, `<`, `>`: 判断逻辑表达式

```sh
# 1. 打印出匹配root的每行行号和内容
awk -F ':' '/root/{print NR"\t"$0}' /tmp/passwd
# 2. 打印出UID为1开头的每行行号和UID和用户名
awk -F ':' '$3~/^1.*/{print NR"\t"$3"\t"$1}' /tmp/passwd
# 3. 打印出UID不为1开头的每行行号和UID和用户名
awk -F ':' '$3!~/^1.*/{print NR"\t"$3"\t"$1}' /tmp/passwd

# 1. 打印出UID大于100的行号和UID和用户名
awk -F ':' '{if($3>100) print NR"\t"$3"\t"$1}' /tmp/passwd
awk -F ':' '$3>100{print NR"\t"$3"\t"$1}' /tmp/passwd
# 2. 打印出UID等于0的行号和UID和用户名
awk -F ':' '$3==0{print NR"\t"$3"\t"$1}' /tmp/passwd
# 3. 打印出UID不等于0的行号和UID和用户名
awk -F ':' '$3!=0{print NR"\t"$3"\t"$1}' /tmp/passwd
```

# 函数调用
```sh
# 1. 打印出行号和用户名
awk -F ':' '{print NR"\t"$1}' /tmp/passwd
awk -F ':' '{printf("%s\t%s\n", NR, $1)}' /tmp/passwd
```

# 逻辑计算
```
awk [option] '[BEGIN{awk 操作命令}]pattern{awk 操作命令}[END{awk 操作命令}]' file(s)
```
这里的`BEGIN`和`END`可以进行一些初始化操作和结尾操作。

```sh
# 1. 统计 / 文件夹下所有文件的大小总和, BEGIN可以声明变量
ll / | awk 'BEGIN{size=0}{size+=$5}END{print "size:"size/1024/1024"M"}'

# 2. 统计 /etc/passwd 下有多少个用户, 用正则表达式 ^$ 排除空行
awk -F ':' 'BEGIN{count=0}$1!~/^$/{count++}END{print "count:"count}' /etc/passwd

# 3. 打印出UID大于100的行号和用户名, 加上表头和表尾
awk -F ':' 'BEGIN{print "NR\tUsername"}{if($3>100) print NR"\t"$1}END{print "-------"FILENAME"-------"}' /etc/passwd

# 4. 使用数组记录所有UID大于100的用户名
awk -F ':' 'BEGIN{count=0}{if($3>100)name[count++]=$1}END{for(i=0;i<count;i++) print i"\t"name[i]}' /etc/passwd

# 5. 分别统计LISTEN和CONNECTED的连接数量
netstat -anp | awk '$6~/(LISTEN)|(CONNECTED)/{sum[$6]++}END{for(i in sum) print i" : "sum[i]}'
```