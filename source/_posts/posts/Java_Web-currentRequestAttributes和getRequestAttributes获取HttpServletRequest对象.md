---
title: currentRequestAttributes和getRequestAttributes获取HttpServletRequest对象
url: use_currentRequestAttributes()_and_getRequestAttributes()_to_get_HttpServletRequest_object
tags:
  - Spring MVC
categories:
  - Java Web
date: 2018-05-04 23:58:00
---
# 前言
`Spring`获取`HttpServletRequest`的方法有很多。
比较常用的是使用`@Autowired`或者直接在方法参数里面注入。

# 问题场景
从数据库`dao`层取出了`url`资源路径, 需要结合`ContextPath`进行补充。
比如访问`http://localhost:8080/project/userList`, 项目路径是`project`。
查询到以下数据
```
id    name       avatar_url
1     user1     /avatar1.jpg
2     user2     /avatar2.jpg
3     user3     /avatar3.jpg
```
如果直接将`avatar_url`填入`<img src="/avatar1.jpg"/>`中的话, 会出现`404`错误。
需要在前面添加项目路径`ContextPath`, 也就是`<img src="/project/avatar1.jpg"/>`才能正常访问。

# 尝试解决
现在的项目一般都是通过`MVC`完成的。
```java
@Controller
public class MyController{
    private MyService myService;
    public MyController(MyService myService){ this.myService = myService; }
    
    @RequestMapping("/userList")
    public List<Map<String, String>> userList(){
        return myService.getUserList();    
    }
}


public interface MyService{ List<Map<String, String>> getUserList(); }
@Service
public class MyServiceImpl implements MyService{
    private MyDao myDao;
    public MyServiceImpl(MyDao myDao) { this.myDao = myDao; }

    public List<Map<String, String>> getUserList() {
        // 给avatar_url添加contextPath前缀
        List<Map<String, String>> list = myDao.getUserList();
        for (Map<String, String> user : list) {
            String url = user.get("avatar_url");
            user.put("avatar_url", contextPath+url);
        }
        return list
    }
}

@Repository
class MyDao{
    public List<Map<String, String>> getUserList(){
        // 模拟从数据库取出数据
        List<Map<String, String>> list = new ArrayList<>();
        for(int i = 0; i < 3; i++){
            Map<String, String> user = new HashMap<>();
            user.put("id", String.valueOf(i));
            user.put("name", "user"+i);
            user.put("avatar_url", "/avatar"+i+".jpg");
            list.add(user);
        }
        return list;
    }
}
```

## 使用Spring自动注入
只要是实现了`@Component`注解(`@Controller`中包含`@Component`, 注意, 注解没有继承), `Spring`就可以自动为其注入`HttpServletRequest`。
```java
@Controller
public class MyController{
    // 省略其他代码

    HttpServletRequest request1; // 1. 第一种方法
    @RequestMapping("/userList")
    // 2. 第二种方法
    public List<Map<String, String>> userList(HttpServletRequest request2){
        return myService.getUserList();    
    }
}
```
上面两种都可以取得**线程安全**的`HttpServletRequest`对象。

但是有个弊端。
使用`HttpServletRequest`对象的类必须实现`@Component`注解。
如果我是在工具类`Utils`中使用, 则必须要为`Utils`中的静态方法提供一个`HttpServletRequest`参数。
如果函数调用链足够深, 则会污染整个函数调用链, 导致每个链上的每个函数都有一个`HttpServletRequest`参数。

# 解决方案
每一个`Request`请求都是属于一个线程, 那么就应该可以存放在`ThreadLocal`对象中。
`RequestContextHolder`类里面就有`ThreadLocal`对象。
它有两个方法
```java
// org.springframework.web.context.request.RequestContextHolder
public abstract class RequestContextHolder  {
    private static final ThreadLocal<RequestAttributes> requestAttributesHolder =
            new NamedThreadLocal<RequestAttributes>("Request attributes");

    private static final ThreadLocal<RequestAttributes> inheritableRequestAttributesHolder =
            new NamedInheritableThreadLocal<RequestAttributes>("Request context");

    public static RequestAttributes getRequestAttributes() {
        RequestAttributes attributes = requestAttributesHolder.get();
        if (attributes == null) { attributes = inheritableRequestAttributesHolder.get(); }
        return attributes;
    }

    public static RequestAttributes currentRequestAttributes() throws IllegalStateException {
        // 调用getRequestAttributes()方法
        RequestAttributes attributes = getRequestAttributes();
        if (attributes == null) {
            if (jsfPresent) {
                attributes = FacesRequestAttributesFactory.getFacesRequestAttributes();
            }
            if (attributes == null) {
                throw new IllegalStateException("异常信息");
            }
        }
        return attributes;
    }
```
可以看到`currentRequestAttributes`方法调用了`getRequestAttributes`方法。追加了对`JSF`的判断。

所以我们可以直接使用`currentRequestAttributes`。

```java
public abstract class RequestHelper {
    private RequestHelper() { throw new AssertionError("工具类不允许实例化"); }
    public static HttpServletRequest getRequest(){
        return ((ServletRequestAttributes) RequestContextHolder
                .currentRequestAttributes()).getRequest(); 
    }

    public static String getContextPath(){
        return getRequest().getContextPath();
    }
```

# 参考资料
- [what-is-the-difference-between-these-methods-of-requestcontextholder-currentre](https://stackoverflow.com/questions/47586707)