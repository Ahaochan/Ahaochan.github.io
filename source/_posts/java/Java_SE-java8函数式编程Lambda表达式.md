---
title: java8函数式编程Lambda表达式
url: java8_lambda_foundation
tags:
  - Java8
categories:
  - Java SE
date: 2017-05-14 10:56:53
---

# 前言
在开发安卓的时候就通过`RxJava`进行过函数式编程。java源码中的建造者模式也是类似函数式编程的玩意。
举个例子
```java
String url = builder.baseUrl(url)
                    .param("username", "admin")
                    .param("password", "admin")
                    .build();
```
<!-- more -->

# Lambda表达式-使代码更简洁
通过`匿名内部类`，我们可以减少类的数量，并且逻辑更清晰。
```java
@Test
public void test() {
    new Thread(new Runnable() {
        @Override
        public void run() {
            System.out.println("测试");     
        }
    });
}
```
但是，这明显还不够简洁。`Runable`只有一个方法`run()`，每次都要重复相同的代码。
java8提供了Lambda表达式。用于满足这种`只有一个方法的接口`的简洁写法。
原本`5`行代码浓缩成了`1`行！
```java
@Test
public void test() {
    new Thread(() -> System.out.println("测试"));
}
```

常见的表达式
```java
Runable noArguments = () -> System.out.println("无参Lambda");
ActionListener oneArguments = event -> System.out.println("含有一个参数的Lambda");
Runable multiStatement = () -> {
    System.out.println("含有多行");
    System.out.println("代码的Lambda");
};
BinaryOperator(Long) multiArgument = (x,y) -> {
    System.out.println("含有多个参数的Lambda");
    return x+y;
}
BinaryOperator(Long) multiArgument = (Long x, Long y) -> {
    System.out.println("含有多个指定类型的参数的Lambda");
    return x+y;
}
```

# Stream流-新的迭代方式
在java8以前，迭代一般都是通过`for`或者`while`实现。
在java5，产生了`foreach`的迭代方式。
现在，java8提供了新的`Stream`的迭代方式。

## 基本使用
**collect(toList())创建集合**
通过``
```java
 @Test
public void test() {
    List<Integer> list = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9).collect(Collectors.toList());
    System.out.println(list);//[1, 2, 3, 4, 5, 6, 7, 8, 9]
}
```

**filter()过滤**
有时候需要获取满足条件的集合元素。
比如大于5的元素
```java
@Test
public void test() {
    List<String> list = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9)
            .filter(x -> x>5)
            .collect(Collectors.toList());
    System.out.println(list);//[6, 7, 8, 9]
}
```

**max()最大值与min()最小值**
这里的最大值最小值不只是指长度或数值上的大小。可以进行自定义排序的指标。
```
@Test
public void test() {
    String max = Stream.of("i","love","you").max(Comparator.comparing(String::length)).get();
    String min = Stream.of("i","love","you").min(Comparator.comparing(String::length)).get();
    System.out.println(max+","+min);// love, i
}
```

## Map转换
**map()转换类型**
将`int`转换为`String`类型
```
@Test
public void test() {
    List<String> list = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9)
            .map(x -> "数字"+x)
            .collect(Collectors.toList());
    System.out.println(list);
    //[数字1, 数字2, 数字3, 数字4, 数字5, 数字6, 数字7, 数字8, 数字9]
}
```

**flatMap()转换类型**
将`多个Stream`压缩成`一个Stream`
```java
@Test
public void test() {
    List<Integer> list1 = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9).collect(Collectors.toList());
    List<Character> list2 = Stream.of('a','b','c').collect(Collectors.toList());
    
    System.out.println(Stream.of(list1, list2)
                                .flatMap(list -> list.stream())
                              //.flatMap(Collection::stream) //方法引用
                                .collect(Collectors.toList()));
}
```

## reduce()一组数据生成一个数据
上面的`max()`和`min()`都是`reduce操作`
求和例子，
```
@Test
public void test() {
    int sum = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9)
                    .reduce(0, (acc, element) -> acc+element);
//  long sum2 = Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9).mapToInt(x -> x).summaryStatistics().getSum();                    
//  开发时应使用这种方式求和
    System.out.println(sum);
}
```


# ::方法引用
上面的flatMap方法中，使用了`Collection::stream`，类似C++的语法。
等价于`list -> list.stream()`。
```java
@Test
public void test() {
    List<String> list1 = Stream.of("i", "love","you").collect(Collectors.toList());
    String max = list1.stream().max(Comparator.comparing(String::length)).get();
    System.out.println(max);
}
```

# collect收集器的使用
上面的例子中有一个`collect`方法，可以将`Stream`转化为`List`等集合对象。
```java
@Test
public void test() {
    List<String> list = Stream.of("i", "love","you").collect(Collectors.toList());
    System.out.println(list);
}
```

** 转化为指定集合类型 **
有时候需要指定特定的集合比如`TreeSet`之类的。需要手动指定产生集合。
```java
@Test
public void test() {
    Set<String> set = Stream.of("i", "love","you")
                .collect(Collectors.toCollection(TreeSet::new));
    System.out.println(set);
}
```

** 转化为值 **
有时候需要按照某种顺序找到一个值。比如找一个最长的单词。
这个例子在实际开发中不使用。
```java
@Test
public void reduce() {
    String max = Stream.of("i", "love","you")
            .collect(Collectors.maxBy(
                                Comparator.comparing(String::length)
                    ))
            .get();
    System.out.println(max);
}
```

** 集合生成字符串 **
有时候需要将集合的所有字符提取出来，组合在一起
```java
@Test
public void reduce() {
    String str = Stream.of("i", "love","you").collect(Collectors.joining("*","(",")"));
    System.out.println(str);//(i*love*you)
}
```

** 数据分块分组 **
`partitioningBy`将Stream分成两个部分，存储在一个Map中，以`true`和`false`为键。
```
@Test
public void test() {
    Map<Boolean, List<String>> map = Stream.of("i", "love","you")
            .collect(Collectors.partitioningBy(str->str.length()>3));
    for(Map.Entry entry : map.entrySet()){
        System.out.println(entry.getKey()+","+entry.getValue());
    }
}
```

大部分情况需要分成不止两个部分，可能更多。
`groupingBy`可以将Stream分成多个部分，下面的例子是将相同长度的字符串存储到一起。
```
@Test
public void test() {
    Map<Integer, List<String>> map = Stream.of("i", "love","you", "hhh")
        .collect(Collectors.groupingBy(String::length));
    for(Map.Entry entry : map.entrySet()){
        System.out.println(entry.getKey()+","+entry.getValue());
    }
}
```

** 下游收集器 **
使用`groupingBy`的时候发现有多个重载方法。
`groupingBy(Function classifier, Collector downstream)`提供了一个下游收集器`downstream`。
可以将`classifier`收集的流，通过downstream转化。
如下面代码
```
@Test
public void test(){
    List<String> list = Stream.of("i","love","you","too").collect(Collectors.toList());
    Map<Integer, Long> map = list.stream().collect(
        Collectors.groupingBy(String::length,   //根据字符串长度转化为map集合
                                Collectors.counting()));    //处理上游的map集合，转化为集合的个数
    for(Map.Entry entry : map.entrySet()){
        System.out.println(entry.getKey()+","+entry.getValue());
    }
    // 1, 1
    // 3, 2
    // 4, 1
}
```
