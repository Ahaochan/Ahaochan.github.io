---
title: Quartz之整合Spring
url: Quartz_and_Spring_combination
tags:
  - Quartz
  - Spring
categories:
  - Java Web
date: 2017-10-03 22:23:27
---
# 前言
作为Web开发者, Spring是必不可少的一个框架, 自然需要把Quartz整合进去。所幸网上已有很多教程, 我这里也只是简单的整合一下, 用于以后项目的CV大法。
` Quartz ` 有调度器` Scheduler `、触发器 ` Trigger `、任务 ` JobDetail `三个组件。一个任务可以给多个调度器执行，触发器在指定时间运行任务，调度器操作触发器执行定时任务。

<!-- more -->

# maven配置
这里的 ` Spring ` 版本是 ` 4.3.9.RELEASE ` ,  ` Quartz ` 版本是 ` 2.3.0 `。
- [spring-tx](https://mvnrepository.com/artifact/org.springframework/spring-tx): 定时任务依赖于事务, 引入[spring-jdbc](https://mvnrepository.com/artifact/org.springframework/spring-jdbc)即可, 自带[spring-tx](https://mvnrepository.com/artifact/org.springframework/spring-tx)
- [spring-context-support](https://mvnrepository.com/artifact/org.springframework/spring-context-support): 提供对Quartz定时任务的支持
- [quartz](https://mvnrepository.com/artifact/org.quartz-scheduler/quartz): 定时任务框架

# 创建任务JobDetail的两种方法
1. 使用 ` MethodInvokingJobDetailFactoryBean ` 通过反射调用 ` Bean的方法 `。
2. 使用 ` JobDetailFactoryBean `, 必须搭配 ` QuartzJobBean `。

推荐用第一种方法, 低侵入式, 降低耦合性。
```java
// 第一种创建任务的方法, 不依赖框架的Java Bean形式
public class MyBean1 {
    public void hello(String msg){
        System.out.println(this.getClass().getSimpleName()+" : "+ DateFormatUtils.format(System.currentTimeMillis(),"yyyy-MM-dd HH:mm:ss")+" : "+msg);
    }
}

// 第二种创建任务的方法, 依赖spring-context-support
// org.springframework.scheduling.quartz.QuartzJobBean 
public class MyBean2 extends QuartzJobBean {
    private String key;
    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        System.out.println(this.getClass().getSimpleName()+" : "+ DateFormatUtils.format(System.currentTimeMillis(), "yyyy-MM-dd HH:mm:ss"));
    }

    public void setKey(String key) {
        this.key = key;
    }
}
```
```xml
<beans >
    <bean id="myBean1" class="com.ahao.MyBean1"/>

    <!-- 反射调用Bean的某个方法, 传入arguments参数 -->
    <bean id="myBeanJob1" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
        <property name="targetObject" ref="myBean1"/>
        <property name="targetMethod" value="hello"/>
        <property name="arguments">
            <list>
                <value>hello World!</value>
            </list>
        </property>
    </bean>

    <!-- 依赖QuartzJobBean -->
    <bean id="myBeanJob2" class="org.springframework.scheduling.quartz.JobDetailFactoryBean">
        <!-- MyBean2必须继承QuartzJobBean -->
        <property name="jobClass" value="com.ahao.MyBean2"/>
        <!-- 参数通过setter方法注入 -->
        <property name="jobDataAsMap">
            <map>
                <entry key="key" value="value"/>
            </map>
        </property>
        <!-- 未绑定Trigger时不会抛出异常 -->
        <property name="durability" value="true"/>
    </bean>
</beans>
```

# 创建触发器Trigger的两种方法
```xml
<beans >
    <bean id="trigger1" class="org.springframework.scheduling.quartz.SimpleTriggerFactoryBean">
        <property name="jobDetail" ref="myBeanJob1"/>
        <!-- 延迟1秒启动 -->
        <property name="startDelay" value="1000"/>
        <!-- 每2秒触发一次 -->
        <property name="repeatInterval" value="2000"/>
    </bean>

    <bean id="trigger2" class="org.springframework.scheduling.quartz.CronTriggerFactoryBean">
        <property name="jobDetail" ref="myBeanJob2"/>
        <!-- cron表达式 -->
        <property name="cronExpression" value="0/5 * * * * ?"/>
    </bean>
</beans>
```
# 创建调度器
```xml
<beans>
    <bean class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
        <property name="triggers">
            <list>
                <ref bean="trigger1"/>
                <ref bean="trigger2"/>
            </list>
        </property>
    </bean>
</beans>
```
# 运行
启动Tomcat服务器, 看到控制台有输出即可。
完整的 ` spring-quartz.xml `如下：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans-4.0.xsd">
    <bean id="myBean1" class="com.ahao.MyBean1"/>

    <!-- 反射调用Bean的某个方法, 传入arguments参数 -->
    <bean id="myBeanJob1" class="org.springframework.scheduling.quartz.MethodInvokingJobDetailFactoryBean">
        <property name="targetObject" ref="myBean1"/>
        <property name="targetMethod" value="hello"/>
        <property name="arguments">
            <list>
                <value>hello World!</value>
            </list>
        </property>
    </bean>

    <!-- 依赖QuartzJobBean -->
    <bean id="myBeanJob2" class="org.springframework.scheduling.quartz.JobDetailFactoryBean">
        <!-- MyBean2必须继承QuartzJobBean -->
        <property name="jobClass" value="com.ahao.MyBean2"/>
        <!-- 参数通过setter方法注入 -->
        <property name="jobDataAsMap">
            <map>
                <entry key="key" value="value"/>
            </map>
        </property>
        <!-- 未绑定Trigger时不会抛出异常 -->
        <property name="durability" value="true"/>
    </bean>

    <bean id="trigger1" class="org.springframework.scheduling.quartz.SimpleTriggerFactoryBean">
        <property name="jobDetail" ref="myBeanJob1"/>
        <!-- 延迟1秒启动 -->
        <property name="startDelay" value="1000"/>
        <!-- 每2秒触发一次 -->
        <property name="repeatInterval" value="2000"/>
    </bean>

    <bean id="trigger2" class="org.springframework.scheduling.quartz.CronTriggerFactoryBean">
        <property name="jobDetail" ref="myBeanJob2"/>
        <!-- cron表达式 -->
        <property name="cronExpression" value="0/5 * * * * ?"/>
    </bean>

    <bean class="org.springframework.scheduling.quartz.SchedulerFactoryBean">
        <property name="triggers">
            <list>
                <ref bean="trigger1"/>
                <ref bean="trigger2"/>
            </list>
        </property>
    </bean>
</beans>
```

