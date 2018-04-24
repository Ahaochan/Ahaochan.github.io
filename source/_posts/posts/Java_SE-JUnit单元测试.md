---
title: JUnit单元测试
url: junit_foundation
tags:
  - JUnit
categories:
  - Java SE
date: 2017-01-11 22:25:40
---


# 常规的单元测试
## 编写被测试类
进行单元测试首先需要一个被测试类和被测试方法
```java
public class Div{
   public static void div(int a, int b){
        return a/b;
   }
}
```
<!-- more -->

## 编写测试类
```java
public class DivTest {
    @BeforeClass
    public static void initClass(){    System.out.println("加载类前执行");    }
    
    @Before
    public void init(){    System.out.println("执行每个方法前执行");    }

    @Test
    public void divTest(){
       TestCase.assertEquals(3, Div.div(6,2));
       System.out.println("预期值为3,实际值为3");
    }
    
    @After
    public void destory(){    System.out.println("执行每个方法后执行");    }

    @AfterClass
    public static void destoryClass(){    System.out.println("执行完所有Test方法后执行");    }
}
```

# 其他常用注释
## @Test
- `expected`：预期会抛出某个异常
- `timeout`：预期运行时间不超过`xx`毫秒

```java
public class DivTest {
    @Test(expected = ArithmeticException.class, timeout = 2000)
    public void divTest(){
        TestCase.assertEquals(3, Div.div(6,0));
        //会抛出ArithmeticException异常，由于expected捕获了异常，所以不会抛出
    }
}
```

## @Ignore
```java
public class DivTest {
    @Ignore
    @Test()
    public void divTest(){
        TestCase.assertEquals(3, Div.div(6,0));
        //这个方法不执行，被忽略
    }
}
```

# 测试套件的使用（多个测试类一起执行）
有时候需要将几个测试类一起测试，需要用到测试套件
```java
@RunWith(Suite.class)//修改JUnit的默认执行类,默认值为Suite.class
@Suite.SuiteClasses({DivTest.class,DivTest.class})//接收一个Class数组，表示要测试的类
public class SuiteTest {
    //空类体，本测试套件将执行DivTest两次
}
```

# 参数化设置（编写测试用例）
```java
@RunWith(Parameterized.class)//修改JUnit的默认执行类
public class ParameterizdTest {
    int expected = 0;
    int input1 = 0;
    int input2 = 0;
    
    public ParameterizdTest(int expected, int input1, int input2){
        this.expected = expected;
        this.input1 = input1;
        this.input2 = input2;
    }

    //实现一个被@Parameterized.Parameters注解修饰的返回Collection的方法
    @Parameterized.Parameters
    public static Collection<Object[]> t(){
        return Arrays.asList(new Object[][]{
                {3, 6, 2},
                {4, 4, 2}
        });
    }

    @Test
    public void divTest(){
        TestCase.assertEquals(expected, Div.div(input1, input2));
    }
}
```
