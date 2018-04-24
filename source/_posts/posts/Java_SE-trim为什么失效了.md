---
title: trim为什么失效了
url: Why_did_trim_fail_execute
tags:
  - 最佳实践
categories:
  - Java SE
date: 2017-07-30 22:50:06
---

# 前言
一直以为`String#trim()`是去掉字符串两边空格的。但是以下代码却与预期不同。
```java
System.out.println("测试:["+"820000    ".trim()+"]"); // ASCII码 160 的空格
System.out.println("测试:["+"　市辖区"+"]"); // ASCII码 12288 的空格
// 测试:[820000    ]
// 测试:[　市辖区]
```
这段数字加空格是我从[最新县及县以上行政区划代码](http://www.stats.gov.cn/tjsj/tjbz/xzqhdm/201703/t20170310_1471429.html)爬取的。

<!-- more -->
# 查看源码
很明显, 算法就是
1. 从前往后, 找到第一个非空格的字符
2. 从后往前, 找到第一个非空格的字符
3. 使用substring截取字符串
4. substring使用构造复制函数进行拷贝
```java
public String trim() {
    int len = value.length;
    int st = 0;
    char[] val = value;    /* avoid getfield opcode */

    while ((st < len) && (val[st] <= ' ')) {
        st++;
    }
    while ((st < len) && (val[len - 1] <= ' ')) {
        len--;
    }
    return ((st > 0) || (len < value.length)) ? substring(st, len) : this;
}

public String substring(int beginIndex, int endIndex) {
    int subLen = endIndex - beginIndex;
    return ((beginIndex == 0) && (endIndex == value.length)) ? this
            : new String(value, beginIndex, subLen);
}
```
明显没毛病, 要我写我也差不多是这样写。

# 断点调试
给`trim`加上断点, 保险起见, 每条语句加上断点。
```java
public String trim() {
·    int len = value.length;
·    int st = 0;
·    char[] val = value;    /* avoid getfield opcode */
·
·    while ((st < len) && (val[st] <= ' ')) {
·        st++;
·    }
·    while ((st < len) && (val[len - 1] <= ' ')) {
·        len--;
·    }
·    return ((st > 0) || (len < value.length)) ? substring(st, len) : this;
}
```

调试结果如下, 代码走到第9行, 进不去这个`while`。
那明显是`(val[len - 1] <= ' ')`出了问题。
```
len (slot_1) = 10
st (slot_2) = 0
value = {
    0 = '8' 56
    1 = '2' 50
    2 = '0' 48
    3 = '0' 48
    4 = '0' 48
    5 = '0' 48
    6 = ' ' 160
    7 = ' ' 160
    8 = ' ' 160
    9 = ' ' 160
}
```

这时候注意`value[9]`的ASCII码为`160`。
查阅[ASCII码表](http://ascii.911cha.com/)可以知道, 空格的ASCII码应该为`32`。
可是这明显是空格啊! 为什么是160呢!

# 为什么眼见不为实
web中有一个常识是, 要使用连续空格, 必须使用`&nbsp;`。
如果只按住`space`输入空格的话, 会被压缩为`一个`空格。

很明显, 这个`&nbsp;`的ASCII码就是`160`。
而`trim`方法只判断了ASCII码为`32`的空格。
就算是apache的`StringUtils#trim()`, 底层也是调用`String#trim()`的。

后来还发现了一个ASCII码为`12288`的空格, 一个汉字宽度的空格。

# 自己动手丰衣足食
参考源码, 进行改造
```java
public class StringHelper{
    /**
     * 去除字符串首尾空格
     * 32 为 普通空格
     * 160 为 html的空格 &nbsp;
     * 12288 为 一个汉字宽度的空格
     * @param str
     * @return
     */
    public static String trim(String str) {
        if (str == null) {
            return null;
        }
        char[] val = str.toCharArray();
        int len = val.length;
        int st = 0;

        while ((st < len) &&
                StringUtils.equalsAny(val[st] + "",
                        (char) (32) + "",
                        (char) (160) + "",
                        (char) (12288) + "")) {
            st++;
        }
        while ((st < len) &&
                StringUtils.equalsAny(val[len - 1] + "",
                        (char) (32) + "",
                        (char) (160) + "",
                        (char) (12288) + "")) {
            len--;
        }
        return ((st > 0) || (len < val.length)) ? str.substring(st, len) : str;
    }
}
```
