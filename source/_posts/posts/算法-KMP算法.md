---
title: KMP算法
url: KMP_Algorithm
tags:
  - 算法
categories:
  - 算法
date: 2016-11-08 21:29:56
---
# 前言
`KMP`是一种字符串匹配算法，并不算高效，晦涩难懂，比它简单易懂高效的算法是有，但不知为何，课本只讲了这种字符串匹配算法。
整个算法的精髓就在于`next`数组的计算，网上关于`KMP`的资料有很多。这里只讲`next`数组的计算。
<!-- more -->

# 求P＝{ababbaaba}的next数组

1、首先，给前两个赋值01
```
ababbaaba
01
```


2、下标移到3号位，对应下标为a，
前缀为`a`，后缀为`b`，没有相同的，赋1
```
  ↓
ababbaaba
011
```

3、下标移到4号位，对应下标为b，
前缀为`a`、`ab`，后缀为`ba`、`a`
有相同的`a`，长度为1，赋2
```
   ↓
ababbaaba
0112
```

4、下标移到5号位，对应下标为b，
前缀为`a`、`ab`、`aba`，后缀为`bab`、`ab`、`b`
有相同的`ab`，长度为2，赋3
```
    ↓
ababbaaba
01123
```

5、下标移到6号位，对应下标为a，
前缀为`a`、`ab`、`aba`、`abab`，后缀为`babb`、`abb`、`bb`、`b`
没有相同的，赋1
```
     ↓
ababbaaba
011231
```
6、下标移到7号位，对应下标为a，
前缀为`a`、`ab`、`aba`、`abab`、`ababb`，后缀为`babba`、`abba`、`bba`、`ba`、`a`
有相同的`a`，长度为1，赋2
```
      ↓
ababbaaba
0112312
```

7、下标移到8号位，对应下标为b，
前缀为`a`、`ab`、`aba`、`abab`、`ababb`、`ababba`，后缀为`babbaa`、`abbaa`、`bbaa`、`baa`、`aa`、`a`
有相同的`a`，长度为1，赋2
```
       ↓
ababbaaba
01123122
```
8、下标移到9号位，对应下标为a，
前缀为`a`、`ab`、`aba`、`abab`、`ababb`、`ababba`、`ababbaa`，后缀为`babbaab`、`abbaab`、`bbaab`、`baab`、`aab`、`ab`、`b`
有相同的`ab`，长度为2，赋3
```
        ↓
ababbaaba
011231223
```
