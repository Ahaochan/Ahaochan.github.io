---
title: SpringMVC简单使用
url: Spring_MVC_simple_use
tags:
  - Spring MVC
categories:
  - Java Web
date: 2017-03-28 14:31:29
---
# 构建环境
## 导入maven
- [spring-webmvc](https://mvnrepository.com/artifact/org.springframework/spring-webmvc)
- [jstl](https://mvnrepository.com/artifact/javax.servlet/jstl)
- [slf4j-log4j12](https://mvnrepository.com/artifact/org.slf4j/slf4j-log4j12)
- [servlet-api](https://mvnrepository.com/artifact/javax.servlet/servlet-api/3.0.1)

<!-- more -->

## 配置web.xml
```xml
<web-app>
    <display-name>JavaeeDemo</display-name>
    <!--spring-->
    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/configs/spring/spring-bean.xml</param-value>
    </context-param>
    <listener>
        <listener-class>org.springframework.web.context.request.RequestContextListener</listener-class>
    </listener>
    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

    <!--spring webmvc-->
    <servlet>
        <servlet-name>mvc-dispatcher</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>/WEB-INF/configs/spring/mvc-dispatcher-servlet.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>mvc-dispatcher</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```

## 配置spring的xml
`/WEB-INF/configs/spring/mvc-dispatcher-servlet.xml`的配置
```xml
<beans>
    <context:annotation-config/><!--开启注解-->
    <context:component-scan base-package="com.ahao.javaeeDemo"><!--扫描包下的Controller注解-->
        <context:include-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
    </context:component-scan>
    <mvc:annotation-driven/><!--开启注解驱动-->
    <!--<mvc:resources mapping="/resources/**" location="/resources"/>--><!--导入静态资源css等-->
    <!--配置ViewResolver-->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="viewClass" value="org.springframework.web.servlet.view.JstlView"/>
        <property name="prefix" value="/WEB-INF/jsps/"/>
        <property name="suffix" value=".jsp"/>
        <property name="order" value="1000"/><!--配置多个Resolver，InternalResourceViewResolver要排在最后-->
    </bean>
</beans>
```
`/WEB-INF/configs/spring/spring-bean.xml`的配置
```xml
<beans>
    <context:annotation-config/><!--开启注解-->
    <context:component-scan base-package="com.ahao.javaeeDemo"><!--扫描包下的注解，排除Controller注解-->
        <context:exclude-filter type="annotation" expression="org.springframework.stereotype.Controller"/>
    </context:component-scan>
</beans>
```

# url映射
## get、post方式匹配
使用`@RequestParam`注入参数，封装成对象再传入`model`，在`jsp`页面中用`EL`表达式获取即可。
```java
@Controller
@RequestMapping("/hello") // 匹配http://localhost:8080/hello路径
public class MyController {
    @RequestMapping(value = "/mvc", method = RequestMethod.GET) // 匹配http://localhost:8080/hello/mvc，只接收get请求
    public String hello(@RequestParam("name") String name, // 匹配http://localhost:8080/hello/mvc?name=?
                                Model model){
        User user = new User(name);
        model.addAttribute(user);
        return "home";
    }
}
```

## 使用ServletAPI
直接注入`HttpServletRequest`或者`HttpSession`
```java
@Controller
@RequestMapping("/hello")
public class MyController{
    @RequestMapping(value="/mvc", method=RequestMathod.GET) // 匹配http://localhost:8080/hello/mvc?
    public String hello(HttpServletRequest request){
        String name = request.getParameter("name");  // 从request中获得请求参数
        User user = new User(name);
        request.setAttribute("user",user);
        return "home";
    }
}
```

## restful方式匹配
使用`@PathVariable`注入参数
```java
@Controller
@RequestMapping("/hello")
public class MyController{
    @RequestMapping(value="/mvc/{name}", method=RequestMethod.GET) // 匹配http://localhost:8080/hello/mvc/hhh
    public String hello(@PathVariable("name") String name, Map<String,Object> model){
        User user = new User(name);
        model.put("user", user);
        return home;
    }
}
```

# 文件上传
jsp提交页面
```html
<form method="post" action="<%=request.getContextPath()%>/hello/doUpload" enctype="multipart/form-data">
    <input type="file" name="file"/>
    <input type="submit" />
</form>
```
配置spring
```xml
<beans>
    <bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
        <property name="maxUploadSize" value="209715200"/>
        <property name="defaultEncoding" value="UTF-8"/>
        <property name="resolveLazily" value="true"/><!--推迟文件解析，用以捕获文件大小异常-->
    </bean>
</beans>
```
配置Controller
```java
@Controller
@RequestMapping("/hello")
public class MyController{
    @RequestMapping(value="/{name}", method=RequestMethod.GET)
    public String hello(@PathVariable("name") String name, Model model){
        User user = new User(name);
        return "home";
    }
    @RequestMapping(value="/doUpload",method=RequestMethod.POST)
    public String doUpload(@RequestParam("file") MultipartFile file) throws IOException{
        if(!file.isEmpty()){
            System.out.println("文件名:"+file.getOriginalFilename());
            FileUtils.copyInputStreamToFile(file.getInputStream(), new File("D:\\", file.getOriginalFilename+".bak"));
        }
        return "redirect:"+file.getOriginalFilename();
    }
}
```

# 返回json格式数据
配置spring
```xml
<beans>
   <bean id="contentNegotiationManager" class="org.springframework.web.accept.ContentNegotiationManagerFactoryBean">
       <property name="ignoreAcceptHeader" value="true"/>
       <property name="mediaTypes">
           <map>
               <entry key="json" value="application/json"/>
               <entry key="xml" value="application/xml"/>
               <entry key="htm" value="text/html"/>
           </map>
       </property>
    </bean>
    <bean class="org.springframework.web.servlet.view.ContentNegotiationViewResolver">
        <property name="order" value="1"/>
        <property name="contentNegotiationManager" ref="contentNegotiationManager"/>
        <property name="defaultViews">
            <list>
                <bean class="org.springframework.web.servlet.view.json.MappingJackson2JsonView"/>
            </list>
        </property>
    </bean>
</beans>
```
配置Controller
```java
@Controller
@RequestMapping("/hello")
public class MyController{
    @RequestMapping(value="/json1/{name}", method=RequestMethod.GET)
    public @ResponseBody User getUserJson1(@PathVariable("name") String name){
        return new User(name);
    }
    @RequestMapping("value"/json2/{name}", method=ReuqestMethod.GET)
    public ResponseEntity<User> getUserJson2(@PathVariable String name){
        return new ResponseEntity<User>(new User(name), HttpStatus.OK)
    }
}
```

# 拦截器
- 实现`HandlerInterceptor`接口
- 实现`WebRequestInterceptor`接口 : 不能拦截请求
