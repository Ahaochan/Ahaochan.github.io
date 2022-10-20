---
title: Struts2自定义拦截器
url: Struts2_how_to_Custom_interceptors
tags:
  - Struts2
categories:
  - Java Web
date: 2017-02-08 19:11:08
---

# 实现

## 实现Interceptor接口
```java
public interface Interceptor extends Serializable {
    void init();//初始化拦截器所需资源
    void destroy();//释放在init()中分配的资源
    String intercept(ActionInvocation invocation) throws Exception;
    //实现拦截器功能
    //利用invocation.getAction()获取Action状态
    //返回result作为逻辑视图名，比如success
}
```
<!-- more -->

## 继承AbstractInterceptor抽象类
`AbstractInterceptor`类实现了`Interceptor`接口
```java
public class AbstractInterceptor implements Interceptor{
    void init(){}//空实现
    void destroy(){}//空实现
    String intercept(ActionInvocation invocation) throws Exception;
}
```

# 配置
在`struts.xml`中注册拦截器
```xml
<struts>
    <package name="default" extends="struts-default">
        <interceptors><!--注册拦截器-->
            <interceptor name="myInterceptor" class="包名.MyInterceptor" />
        </interceptors>
        <action name="myAction" class="包名.MyAction">
            <interceptor-ref name="myInterceptor" /><!--引用拦截器-->
        </action>
    </package>
</struts>
```

# 内置拦截器
在`struts-default.xml`中

| 拦截器              | 作用                                                     |
|:--------------------|:---------------------------------------------------------|
| params拦截器        | 负责将请求参数设置为Action属性                           |
| staticParams拦截器  | 将配置文件中action元素的子元素param参数设置为Action属性  |
| servletConfig拦截器 | 将源于ServletAPI的各种对象注入到Action，必须实现对应接口 |
| fileUpload拦截器    | 对文件上传提供支持，将文件和元数据设置到对应的Action属性 |
| exception拦截器     | 捕获异常，并且将异常映射到用户自定义的错误界面           |
| validation拦截器    | 调用验证框架进行数据验证                                 |

# 简单功能
## 计算Action执行时间
```java
public class TimerInterceptor extends AbstractInterceptor{
    public String intercept(ActionInvocation invocation) throws Exception{
        long start = System.currentTimeMillis();
        String result = invocation.invoke();//执行下一个拦截器，如果没有拦截器就执行Action，返回视图名，如"success"
        long end = System.currentTimeMillis();
        System.out.println("时间："+(end-start)/1000+"s");
        return result;
    }
}
```

## 权限校验
```java
public class AuthInterceptor extends AbstractInterceptor{
    public String intercept(ActionInvocation invocation) throws Exception{
        ActionContext context = ActionContext.getContext();
        Map<String, Object> session = context.getSession();
        if(session.get("loginInfo")!=null) { //已登录
            return invocation.invoke();
        } else {//未登录
            return "login";//需要登录
        }
    }
}
```
