---
title: 复制构造函数与clone
url: copy_constructor_and_clone_method
tags:
  - 最佳实践
categories:
  - Java SE
date: 2017-06-04 09:29:00
---

# 前言
对一个对象的复制，通常实现`Cloneable`接口使用`clone`方法。
但这有一个设计缺陷。`Cloneable`没有`clone`方法，反而在`Object`里面调用了`native`修饰的`clone`方法。

<!-- more -->

# 缺陷
```java
public interface Cloneable {
}
```
很明显看到，`Cloneable`是一个空接口，实现`Cloneable`只是为了在调用`clone`方法时，不抛出`CloneNotSupportedException`异常。
而且使用的是`native`修饰的`clone`方法，对应用开发者是透明的，开发者对`clone`方法不可控。


# 使用复制构造函数解决
Josh Bloch推荐使用复制构造函数来实现`clone`功能，实际上，`HashMap`也通过复制构造函数进行clone。
```Java
// java.util.HashMap
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable {
    public HashMap(Map<? extends K, ? extends V> m) {
        this.loadFactor = DEFAULT_LOAD_FACTOR;
        putMapEntries(m, false);
    }
}
```

# 参考资料
- [Copy Constructor versus Cloning](http://www.artima.com/intv/bloch13.html)
