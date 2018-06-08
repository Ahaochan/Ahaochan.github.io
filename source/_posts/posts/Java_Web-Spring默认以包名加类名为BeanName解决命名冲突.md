---
title: Spring默认以包名加类名为BeanName解决命名冲突
url: Spring_resolves_naming_conflicts_by_default_with_PackageName_ClassName_BeanName
tags:
  - Spring
  - 最佳实践
categories:
  - Java Web
date: 2018-05-11 21:29:00
---
# 前言
`Spring`可以自动将`@Component`注解修饰的类加载为`Bean`.
比如`MyController`这个类, 就会加载为名称是`myController`的`Bean`.
但是, 如果在不同的模块下, 不同的包下, 有着相同文件名的类, 就会造成`BeanName`冲突。
```
- com.ahao.project
    -  moduleA
        - IndexController.java
        - moduleAService.java
    - moduleB
        - IndexController.java
        - moduleBService.java
```

<!-- more -->

# 解决方案
为什么我们使用`Java`类的时候不会发生冲突呢?
因为`import`将包名导入了, 否则我们需要输入`包名.类名`才能使用这个类。

引用这个思路, 将`BeanName`也设置成`包名.类名`的形式。
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans>
    <context:component-scan base-package="com.ahao" name-generator="com.ahao.core.spring.bean.PackageBeanNameGenerator"/>
</beans>
```
```java
public class PackageBeanNameGenerator implements BeanNameGenerator {
    private static final Logger logger = LoggerFactory.getLogger(PackageBeanNameGenerator.class);

    @Override
    public String generateBeanName(BeanDefinition definition, BeanDefinitionRegistry registry) {
        String beanClassName = Introspector.decapitalize(definition.getBeanClassName());
        logger.debug("装载Bean: " + beanClassName);
        return beanClassName;
    }
}
```

# Mybatis使用BeanNameGenerator
在`Spring`整合发现`Mybatis`的`BeanName`生成没有使用`BeanNameGenerator`。
```xml
<context:component-scan base-package="com.ahao" use-default-filters="false"
                        name-generator="com.ahao.core.beans.PackageBeanNameGenerator">
    <context:include-filter type="annotation" expression="org.springframework.stereotype.Repository"/>
</context:component-scan>
```
```java
@Repository
public interface ModuleDAO {
    List<String> getNames(); // 使用 ModuleMapper.xml
}
```
在调试时，`Mybatis`的代理类没有使用`@Repository`注解，所以`include-filter`没有扫描到代理类。

在`Stack Overflow`提问也没人回。
后来自己找到了解决方法, 在配置`MapperScannerConfigurer`时注入`NameGenerator`即可。
```xml
    <!-- 配置扫描Dao接口包,动态实现DAO接口,注入到spring容器 -->
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <!--注入SqlSessionFactory-->
        <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"/>
        <!-- 给出需要扫描的Dao接口-->
        <property name="basePackage" value="com.ahao.**.dao"/>
        <property name="nameGenerator">
            <bean class="com.nine.rivers.galaxy.spring.beans.PackageBeanNameGenerator"/>
        </property>
    </bean>
```

# 参考资料
- [automatically-assign-springs-bean-name-to-prevent-name-conflicts](https://stackoverflow.com/questions/5414215)