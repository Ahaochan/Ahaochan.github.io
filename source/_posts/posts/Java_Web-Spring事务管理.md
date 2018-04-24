---
title: Spring事务管理
url: Spring_Transaction_Management
tags:
  - Spring
categories:
  - Java Web
date: 2017-03-24 14:36:19
---

# 接口介绍
- PlatformTransactionManager事务管理器
- TransactionDefinition事务定义信息
 * ISOLATION隔离级别
 * PROPAGATION传播行为
 * TIMEOUT超时信息
- TransactionStatus事务具体运行状态

<!-- more -->

# 编程式事务管理（很少应用）
通过`TransactionTemplate`手动管理事务，在`service`使用`TransactonTemplate`，依赖`DataSourceTransactionManager`，依赖`DataSource`构造
`spring`配置
```xml
<beans>
    <!--配置数据库连接池DataSource-->
    <bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource">
        <property name="driverClass" value="com.mysql.cj.jdbc.Driver"/>
        <property name="jdbcUrl" value="jdbc:mysql://localhost:3306/test?serverTimeZone=GMT&useUnicode=true&characterEncoding=utf8"/>
        <property name="user" value="root"/>
        <property name="password"value="root"/>
    </bean>
    
    <!--在service层注入事务管理模板-->
    <bean id="accountService" class="com.ahao.javaeeDemo.service">
        <property id="dao" ref="accountDao"/>
        <property id="transactionTemplate" ref="transactionTemplate" />
    </bean>
    <!--配置事务管理模板-->
    <bean id="transactionTemplate" class="org.springframework.transaction.support.TransactionTemplate">
        <property name="transactionManager" ref="transactionManager"/><!--注入事务管理器-->
    </bean>    
    <!--配置事务管理器-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/><!--注入数据库连接池-->
    </bean>
</beans>
```
在`service`层编写`java`代码
```java
public class AccountServiceImpl implements AccountService{
    private AccountDao dao;
    private TransactionTemplate transactionTemplate;
    // getter And Setter
    public void transfer(String out, String in, Double money){
        transactionTemplate.execute(new TransactionCallbackWithoutResult(){
            protected void doInTransactionWithoutResult(TransactionStatus status){
                dao.outMoney(out, money);
                int i = 1/0;//引发异常，事务回滚
                dao.inMoney (in, money);
            }
        });
    }
}
```


# 声明式事务管理
通过`XML`配置，代码侵入性小，通过`AOP`实现
需要导入
- http://mvnrepository.com/artifact/aopalliance/aopalliance
- http://mvnrepository.com/artifact/org.springframework/spring-aop 

## 基于TransactionProxyFactoryBean的方式（很少应用）
缺点是要为每个增强类添加一个`TransactionProxyFactoryBean`配置。
`spring`配置
```xml
<beans>
    <!--配置数据库连接池DataSource-->
    <!--service层-->
    <bean id="accountService" class="com.ahao.javaeeDemo.service">
        <property id="dao" ref="accountDao"/>
    </bean>
    <!--创建代理对象-->
    <bean id="accountServiceProxy" class="org.springframework.transaction.interceptor.TransactionProxyFactoryBean">
        <property name="target" ref="accountService"/><!--注入被增强的对象-->
        <property name="transactionManager" ref="transactionManager"/><!--注入事务管理器-->
        <property name="transactionAttributes">
            <props>
                <!--<prop key"save*表示以save开头的方法">PROPAGATION(事务传播行为),ISOLATION(事务隔离级别),readOnly(只读),-Exception(发生某些异常回滚),+Exception(发生某些异常不回滚)</prop>-->
                <prop key="transfer">PROPAGATION_REQUIRED</prop>
            </props>
        </property>
    </bean>    
    <!--配置事务管理器-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/><!--注入数据库连接池-->
    </bean>
</beans>
```

## 基于AspectJ的XML方式（推荐）
需要导入    
- http://mvnrepository.com/artifact/org.aspectj/aspectjweaver 
- http://mvnrepository.com/artifact/org.springframework/spring-aop

`spring`配置
```xml
<beans>
    <!--配置数据库连接池DataSource-->
    <!--service层-->
    <bean id="accountService" class="com.ahao.javaeeDemo.service">
        <property id="dao" ref="accountDao"/>
    </bean>
    <!--配置事务的通知-->
    <tx:advice id="txAdvice" transaction-manager="transactionManager">
        <tx:attributes>
            <tx:method name="transfer" propagation="REQUIRED" isolation="DEFAULT" read-only="false" no-rollback-for="MyException1" rollback-for="MyException2" timeout="-1"/> 
        </tx:attributes>
    </tx:advice>
    <!--配置切面-->
    <aop:config>
        <!--配置切入点-->
        <aop:pointcut id="pointcut" expression="execution(* com.ahao.javaeeDemo.service.AccountService+.*(..))"/>
        <!--配置切面-->
        <aop:advisor advice-ref="txAdvice" pointcut-ref="pointcut" />
    </aop:config>

    <!--配置事务管理器-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/><!--注入数据库连接池-->
    </bean>
</beans>
```

## 基于注解的方式（代码侵入性强，配置简单）

`spring`配置
```xml
<beans>
    <!--配置数据库连接池DataSource-->
    <!--service层-->
    <bean id="accountService" class="com.ahao.javaeeDemo.service">
        <property id="dao" ref="accountDao"/>
    </bean>
    <!--配置注解驱动-->
    <tx:annotation-driven transaction-manager="transactionManager"/>
    <!--配置事务管理器-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/><!--注入数据库连接池-->
    </bean>
</beans>
```
在类上添加注解
```java
@Transactional(propagation = Propagation.REQUIRED, isolation = Isolation.DEFAULT,readOnly = false)
public class AccountServiceImpl implements AccountService {
    private AccountDaoImpl dao;
    public void setDao(AccountDaoImpl dao) {
        this.dao = dao;
    }
    @Override
    public void transfer(String out, String in, Double money) {
        dao.outMoney(out, money);
        int i = 1/0;
        dao.inMoney(in, money);
    }
}
```
