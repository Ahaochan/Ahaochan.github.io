---
title: Collectors.reducing压缩List&lt;Map&gt;为Map
url: how_to_use_Collectors.reducing_method_to_reducing_List[Map]_to_Map
tags:
  - Java8
categories:
  - Java SE
date: 2017-09-11 20:25:49
---
# 前言
`reduce`操作可以实现从一组元素中生成一个值, 也可以作为`downstream`下游处理器。本文默认读者已经掌握基本的`Stream`知识。

<!-- more -->

# 结论
先大致看下结论, 不懂可以看下面的解释。
1. ` identity ` 只会初始化一次。
2. ` identity ` 在每次 `downstream` 的时候会重新放到 **左值(left)** 中。
3. 如果操作 ` identity ` 的话, 将会影响下次 ` downstream ` 的第一次的 **左值(left)**

# 情景重现
假设有一个邮递员业务的数据。用json展示。可以复制到[【JSON在线解析及格式化验证】](http://www.json.cn/)进行格式化。
就是一个数组，每个元素都包含**日期**、**邮件数量**、**发送地区的行政区划代码**、**是否大件行李**。
```json
[
  {
    "date": "2016-01",  // 日期
    "number": "1",      // 邮件数量
    "code": "420000",   // 发送地区的行政区划代码
    "type": "false"     // 是否大件行李
  },
  {
    "date": "2016-01",
    "number": "2",
    "code": "440000",
    "type": "false"
  },
  {
    "date": "2016-02",
    "number": "3",
    "code": "420000",
    "type": "false"
  },
  {
    "date": "2016-03",
    "number": "4",
    "code": "420000",
    "type": "true"
  },
  {
    "date": "2016-03",
    "number": "5",
    "code": "410000",
    "type": "false"
  },
  {
    "date": "2016-03",
    "number": "6",
    "code": "440000",
    "type": "true"
  },
  {
    "date": "2016-04",
    "number": "7",
    "code": "420000",
    "type": "false"
  },
  {
    "date": "2016-04",
    "number": "8",
    "code": "440000",
    "type": "false"
  }
];
```
目标是根据 **日期** 分组, 根据 **是否大件行李** 分区, 把结果 `List<Map>` 压缩成一个 ` Map<行政区划代码， 数量> `。

# 进行编码
```java
public class MyTest{
    public static void main(String[] args) {
        List<Map<String, String>> postmans = new ArrayList<>();

        // "420000" :行政区划代码, "false": 是否为大件行李
        postmans.add(createMap("2016-01", "1", "420000", "false"));
        postmans.add(createMap("2016-01", "2", "440000", "false"));
        postmans.add(createMap("2016-02", "3", "420000", "false"));
        postmans.add(createMap("2016-03", "4", "420000", "true"));
        postmans.add(createMap("2016-03", "5", "410000", "false"));
        postmans.add(createMap("2016-03", "6", "440000", "true"));
        postmans.add(createMap("2016-04", "7", "420000", "false"));
        postmans.add(createMap("2016-04", "8", "440000", "false"));

        // 使用 fastjson 打印输出 原始数据
        System.out.println(JSONObject.toJSONString(postmans));

        Map<String, Map<Boolean, Map>> data = postmans.stream()
                .collect(
                    Collectors.groupingBy(    // 分组
                        d -> d.get("date"),   // 根据 日期 分组
                        TreeMap::new,         // 使用 TreeMap 构造有序 Map
                        Collectors.partitioningBy(
                            d-> d.get("type").equals("true"), // 根据 是否大件行李 分区
                            Collectors.reducing(new HashMap(), (left, right)->{ // 压缩 List<Map> 为 Map
                                Object code = right.get("code");
                                Object number = right.get("number");
                                left.put(code, number);
                                // 这里不应该修改left, 也就是identity
                                return left;
                            }))));
        // 使用 fastjson 打印输出 格式化后的数据
        System.out.println(JSONObject.toJSONString(data));

    }

    private static Map<String,String> createMap(String date, String number, String code, String type){
        Map<String, String> map = new HashMap<>();
        map.put("date", date);
        map.put("number", number);
        map.put("code", code);
        map.put("type", type);
        return map;
    }
}
```

# 预期和实际的结果不同
很明显, 每次最新的 **行政区划代码** 和 **对应的数量** 覆盖了之前的值。
可以复制到[【JSON在线解析及格式化验证】](http://www.json.cn/)进行格式化。
```javascript
var 预期结果 = {
  "2016-01": {
    "false": {
      "420000": "1",
      "440000": "2"
    }
  },
  "2016-02": {
    "false": {
      "420000": "3"
    }
  },
  "2016-03": {
    "false": {
      "410000": "5"
    },
    "true": {
      "420000": "4",
      "440000": "6"
    }
  },
  "2016-04": {
    "false": {
      "420000": "7",
      "440000": "8"
    }
  }
};
var 实际结果= {
  "2016-01": {
    "false": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    },
    "true": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    }
  },
  "2016-02": {
    "false": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    },
    "true": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    }
  },
  "2016-03": {
    "false": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    },
    "true": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    }
  },
  "2016-04": {
    "false": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    },
    "true": {
      "410000": "5",
      "420000": "7",
      "440000": "8"
    }
  }
};
```

# 问题解决
上[【stackoverflow】](https://stackoverflow.com/questions/46143242/)问了下，有人给出了正确的代码。
```java
Collectors.reducing(
    new HashMap<>(),
    (left, right) -> {
        // 注意这里 new 了个 Map
        Map<String, String> map = new HashMap<>();
        String leftCode = left.get("code");
        String leftNumber = left.get("number");

        if (leftCode == null) {
            map.putAll(left);
        } else {
            map.put(leftCode, leftNumber);
        }

        String rightCode = right.get("code");
        String rightNumber = right.get("number");

        map.put(rightCode, rightNumber);

        return map;
    })
```
再结合自己调试之后，发现了几点
1. ` identity ` 只会初始化一次。
2. ` identity ` 在每次 `downstream` 的时候会重新放到 **左值(left)** 中。
3. 如果操作 ` identity ` 的话, 将会影响下次 ` downstream ` 的第一次的 **左值(left)**

注意我的代码, 我修改了 ` identity ` 的值, 造成了之后每次 `downstream` 重新放到 **左值** 的  ` identity ` 携带了上一次`downstream` 处理过的参数
```java
Collectors.reducing(
    new HashMap(), 
    (left, right)->{ // 压缩 List<Map> 为 Map
        Object code = right.get("code");
        Object number = right.get("number");
        left.put(code, number);
        // 我修改了 identity 的值
        return left;
    });
```
而新的代码, 是重新 new 了个 Map, 没有修改 ` identity ` 。保持了 ` identity ` 的纯净。

# 具体调试代码
```java
public class MyTest{
    public static void main(String[] args) {
        List<Map<String, String>> postmans = new ArrayList<>();

        // "420000" : post area code, "false": just paper(without goods)
        postmans.add(createMap("2016-01", "1", "420000", "false"));
        postmans.add(createMap("2016-01", "2", "440000", "false"));
        postmans.add(createMap("2016-02", "3", "420000", "false"));
        postmans.add(createMap("2016-03", "4", "420000", "true"));
        postmans.add(createMap("2016-03", "5", "410000", "false"));
        postmans.add(createMap("2016-03", "6", "440000", "true"));
        postmans.add(createMap("2016-04", "7", "420000", "false"));
        postmans.add(createMap("2016-04", "8", "440000", "false"));

        // before, I use fastjson Library
        System.out.println(JSONObject.toJSONString(postmans));


        Map<String, Map<Boolean, Map>> data = postmans.stream()
                .collect(Collectors.groupingBy(d -> d.get("date"), TreeMap::new,
                        Collectors.partitioningBy(d-> d.get("type").equals("true"),
                                Collectors.reducing(newHashMap(), (left, right)->{

                                    System.out.println("开始:"+JSONObject.toJSONString(left)+","+JSONObject.toJSONString(right));

                                    Object code = right.get("code");
                                    Object number = right.get("number");
                                    // I think bug in reducing
                                    left.put(code, number);
                                    System.out.println("结果:"+JSONObject.toJSONString(left)+"\n");

                                    return left;
                                }))));
        // after, I use fastjson Library
        System.out.println(JSONObject.toJSONString(data));

        Map<String, Map<Boolean, Map<String, String>>> test = postmans.stream()
                .collect(Collectors.groupingBy(d -> d.get("date"), TreeMap::new,
                        Collectors.partitioningBy(d -> d.get("type").equals("true"),
                                Collectors.reducing(newHashMap(), (left, right) -> {
                                            Map<String, String> map = new HashMap<>();

                                            System.out.println("开始:"+JSONObject.toJSONString(left)+","+JSONObject.toJSONString(right));

                                            String leftCode = left.get("code");
                                            String leftNumber = left.get("number");

                                            if (leftCode == null) {
                                                map.putAll(left);
                                            } else {
                                                map.put(leftCode, leftNumber);
                                            }

                                            String rightCode = right.get("code");
                                            String rightNumber = right.get("number");

                                            map.put(rightCode, rightNumber);

                                            System.out.println("结果:"+JSONObject.toJSONString(map)+"\n");

                                            return map;
                                        }))));
        System.out.println(JSONObject.toJSONString(test));

    }

    private static Map<String, String> newHashMap(){
        Map<String, String> map = new HashMap<>();
        map.put("time"+System.currentTimeMillis(), "测试:"+System.currentTimeMillis());
        return map;
    }

    private static Map<String,String> createMap(String date, String number, String code, String type){
        Map<String, String> map = new HashMap<>();
        map.put("date", date);
        map.put("number", number);
        map.put("code", code);
        map.put("type", type);
        return map;
    }
}
```

# 结论
1. ` identity ` 只会初始化一次。
2. ` identity ` 在每次 `downstream` 的时候会重新放到 **左值(left)** 中。
3. 如果操作 ` identity ` 的话, 将会影响下次 ` downstream ` 的第一次的 **左值(left)**

# 参考资料
- [java8 Stream List<Map> how to covert a Map after groupingBy](https://stackoverflow.com/questions/46143242/)
