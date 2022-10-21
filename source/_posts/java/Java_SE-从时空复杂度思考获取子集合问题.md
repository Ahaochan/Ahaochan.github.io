---
title: 从时空复杂度思考获取子集合问题
url: think_about_the_problem_of_obtaining_sub_collection_from_the_perspective_of_complexity_in_time_and_space
tags:
  - 最佳实践
  - 算法
categories:
  - Java SE
date: 2017-12-06 20:20:38
---

# 前言
需求: 需要从`List`根据条件获取子元素集合`subList`。

有两种方法
1. 时间优先: 添加到新的集合中。
2. 空间优先: 使用`Iterator`迭代器进行删除。

这里以`ArrayList`为例。

<!-- more -->

# 测试数据
现在需要把偶数取出来。
```java
public class Main {
    public static void main(String[] args) {
        List<Integer> list = new ArrayList<>();
        for(int i = 0; i < 100; i++){
            list.add(i);
        }
    }
}
```

# 时间优先
新建一个集合, 遍历参数集合, 将满足条件的数据插入新的集合, 再将新集合插入
```java
public class Main {
    public static void main(String[] args) {
        List<Integer> list = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            list.add(i);
        }
        System.out.println(even1(list));
    }

    private static List<Integer> even1(List<Integer> list) {
        // 添加到新的集合
        List<Integer> result = new ArrayList<>(list.size());
        for (Integer i : list) {
            if (i % 2 == 0) {
                result.add(i);
            }
        }
        return result;
    }
}
```

# 空间优先
直接在已有集合上, 使用迭代器进行删除操作。
```java
public class Main {
    public static void main(String[] args) {
        List<Integer> list = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            list.add(i);
        }
        System.out.println(even2(list));
    }

    private static List<Integer> even2(List<Integer> list) {
        // 在已有集合进行删除
        for (Iterator<Integer> it = list.iterator(); it.hasNext(); ) {
            Integer value = it.next();
            if (value % 2 != 0) {
                it.remove();
            }
        }
        return list;
    }
}
```

# 分析
如何选择最佳的获取子集合策略，取决于该集合的数据结构。
例如 ` ArrayList ` 的集合数据结构是数组, 删除、插入的效率是 ` O(n) ` , 查找的效率是 ` O(1) `。
再综合考虑代码的复杂度, 个人观点, 如果不是空间非常紧张, 还是选**时间优先**的方案比较好。
