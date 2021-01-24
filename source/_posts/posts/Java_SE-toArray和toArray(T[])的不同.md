---
title: toArray和toArray(T[])的不同
url: Difference_between_toArray(T[]a)_and_toArray()
tags:
  - 最佳实践
categories:
  - Java SE
date: 2018-07-08 13:05:00
---

# 前言
`Collection`接口有两个方法`Object[] toArray();`和`<T> T[] toArray(T[] a);`, 可以用来将集合转为数组。

<!-- more -->

# 使用
一个返回`Object[]`, 一个返回`T[]`, 为了避免发生强制转化, 我们一般都是使用`<T> T[] toArray(T[] a);`。
而`<T> T[] toArray(T[] a);`传入的数组大小可以直接填`0`, 当然也可以直接填`source.size()`。
但是[arrays-wisdom-ancients](https://shipilev.net/blog/2016/arrays-wisdom-ancients/)这篇文章做了分析, `JDK6`以后直接填`0`性能更好。

```java
List<String> source = new LinkedList<String>();
// 填充数据
String[] array1 = (Object[]) source.toArray();
String[] array2 = source.toArray(new String[0]);
String[] array3 = source.toArray(new String[source.size()]);
```

# 查看ArrayList的实现

```java
public class ArrayList<E> extends AbstractList<E>
        implements List<E>, RandomAccess, Cloneable, java.io.Serializable
{
    public Object[] toArray() {
        return Arrays.copyOf(elementData, size);
    }
        
    public <T> T[] toArray(T[] a) {
        if (a.length < size)
            // Make a new array of a's runtime type, but my contents:
            return (T[]) Arrays.copyOf(elementData, size, a.getClass());
        System.arraycopy(elementData, 0, a, 0, size);
        if (a.length > size)
            a[size] = null;
        return a;
    }
}
public class Arrays {
    public static <T> T[] copyOf(T[] original, int newLength) {
        return (T[]) copyOf(original, newLength, original.getClass());
    }
    public static <T,U> T[] copyOf(U[] original, int newLength, Class<? extends T[]> newType) {
        @SuppressWarnings("unchecked")
        T[] copy = ((Object)newType == (Object)Object[].class)
            ? (T[]) new Object[newLength]
            : (T[]) Array.newInstance(newType.getComponentType(), newLength);
        System.arraycopy(original, 0, copy, 0,
                         Math.min(original.length, newLength));
        return copy;
    }
}
```
当我们调用`ArrayList.toArray`方法的时候, 都会调用`Arrays.copyOf`方法, 最终调用`System.arraycopy`方法, 这是一个`native`方法。
当然, 不同的集合有不同的`toArray`实现方法。

# 总结
如果传入的参数`toArray(T[] a)`小于本身的长度, 会`new`或者反射创建一个新的数组, 然后将元素复制进去。
但是[arrays-wisdom-ancients](https://shipilev.net/blog/2016/arrays-wisdom-ancients/)这篇文章做了分析, `JDK6`以后直接填`0`性能更好。
