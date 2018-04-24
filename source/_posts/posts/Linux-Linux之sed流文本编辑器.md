---
title: Linux之sed流文本编辑器
url: sed_of_Linux
tags:
  - Linux
categories:
  - Linux
date: 2018-03-19 21:57:01
---
# 前言
`stream editor`是`Unix`的行处理命令, 以**行**为单位, 依次读入文本的每行进行处理。
`sed`**一般**不会对原文件进行操作, 当然, 有例外。
```sh
# 复制测试文件
[root@localhost ~]# cp /etc/passwd /tmp/passwd
```

<!-- more -->

# 打印内容
`p`参数: 前面接数字或正则表达式, 打印匹配内容
`-n`参数: 不自动打印内容, 如果不和`p`一起使用, 则会输出两次相同内容
`!`参数: 对之前的参数进行取反
`a~b`参数: 从`a`行开始, 每隔`b`行执行操作
```sh
# 1. 打印所有行
[root@localhost ~]# nl /tmp/passwd | sed -n 'p'
# 2. 打印所有行, 不使用 -n 会打印两次
[root@localhost ~]# nl /tmp/passwd | sed 'p'
# 3. 打印第2行
[root@localhost ~]# nl /tmp/passwd | sed -n '2p'
# 4. 打印匹配正则表达式为 root 的一行
[root@localhost ~]# nl /tmp/passwd | sed -n '/root/p'
# 5. 打印第2-10行的内容
[root@localhost ~]# nl /tmp/passwd | sed -n '2,10p'
# 6. 打印匹配正则表达式为 root 和 ahao 之间的行的内容
[root@localhost ~]# nl /tmp/passwd | sed -n '/root/,/ahao/p'
# 7. 打印除了第2-10行的所有行内容
[root@localhost ~]# nl /tmp/passwd | sed -n '2,10!p'
# 8. 打印第2行开始, 每3行的所有行内容
[root@localhost ~]# nl /tmp/passwd | sed -n '2~3p'
```

# 增删(不影响原文件)
`na string`参数: 表示在第`n`行后面追加(`append`)一行`string`
`ni string`参数: 表示在第`n`行前面插入(`insert`)一行`string`
`nd`参数: 将第`n`行或匹配正则表达式`n`的一行删除(`delete`)
```sh
# 1. 在第5行后面追加(append)一行内容
[root@localhost ~]# nl /tmp/passwd | sed '5a HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'
# 2. 在第2-5行每行后面追加(append)一行内容
[root@localhost ~]# nl /tmp/passwd | sed '2,5a HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'

# 3. 在第5行前面插入(insert)一行内容
[root@localhost ~]# nl /tmp/passwd | sed '5i HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'
# 4. 在第2-5行每行前面插入(insert)一行内容
[root@localhost ~]# nl /tmp/passwd | sed '2,5i HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'

# 5. 将第2-5行的内容删除(delete)
[root@localhost ~]# nl /tmp/passwd | sed '2,5d'
# 6. 将匹配正则表达式 root 的行内容删除(delete)
[root@localhost ~]# nl /tmp/passwd | sed '/root/d'
```


# 替换(不影响原文件)
`nc string`参数: 将第`n`行替换(`replace`)为`string`
`s/regexp/replacement/`参数: 将每行第一个匹配`regexp`正则表达式的替换为`replacement`
`s/regexp/replacement/g`参数: 将每行所有匹配`regexp`正则表达式的替换为`replacement`
`s/regexp/str1 & str2/g`参数: `&`参数表示正则表达式匹配的值
`s/regexp/\u&/g`参数: `\u`首字母大写, `\U`所有字母大写
`()`参数: 括号捕获多个值, 用`\1`、`\2`等表示捕获的第几个值
```sh
# 1. 将第5行替换(replace)为指定字符串
[root@localhost ~]# nl /tmp/passwd | sed '5c HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'
# 2. 将第2-5行替换(replace)为指定字符串
[root@localhost ~]# nl /tmp/passwd | sed '2,5c HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH'

# 3. 将每行第1个匹配正则表达式 : 的内容替换为 %
[root@localhost ~]# nl /tmp/passwd | sed 's/:/%/'
# 4. 将每行所有匹配正则表达式 : 的内容替换为 %, g 全局替换
[root@localhost ~]# nl /tmp/passwd | sed 's/:/%/g'
# 5. 将每行所有匹配正则表达式 : 的内容替换为 %包裹的字符串, &表示匹配的字符串
[root@localhost ~]# nl /tmp/passwd | sed 's/:/%&%/g'

# 6. 将匹配到的单词首字母转为大写, \u转为大写
[root@localhost ~]# nl /tmp/passwd | sed 's/[a-z]*/\u&/g'
# 7. 将匹配到的单词所有字母转为大写, \U转为大写
[root@localhost ~]# nl /tmp/passwd | sed 's/[a-z]*/\U&/g'

# 8. 使用()获取用户名, UID, GID, -r 不用加转义符
[root@localhost ~]# cat /tmp/passwd | sed 's/^\([a-z_-]\+\):x:\([0-9]\+\):\([0-9]\+\):.*$/USER:\1  UID:\2  GID:\3/'
[root@localhost ~]# cat /tmp/passwd | sed -r 's/^([a-z_-]+):x:([0-9]+):([0-9]+):.*$/USER:\1  UID:\2  GID:\3/'
```

# 退出
`q`参数: 退出`sed`命令
```sh
# 1. 到第3行就退出(quit)sed
[root@localhost ~]# nl /tmp/passwd | sed '3q'
# 2. 找到匹配 root 正则就退出(quit)sed
[root@localhost ~]# nl /tmp/passwd | sed '/root/q'
```

# 读写原文件(修改原文件)
```sh
# 1. 创建一个文件
[root@localhost ~]#  echo -e '123\n456\n789' > hello.txt
# 2. 将/tmp/passwd插入 读入(read)的hello.txt文件的第1行后面打印输出, 不修改hello.txt
[root@localhost ~]# sed '1r /tmp/passwd' hello.txt
# 3. 将 hello.txt 写入(write)覆盖 /tmp/passwd, 修改/tmp/passwd
[root@localhost ~]# sed 'w /tmp/passwd' 
# 4. 将 hello.txt 的第2行写入(write)覆盖 /tmp/passwd
[root@localhost ~]# sed '2w /tmp/passwd' hello.txt
```