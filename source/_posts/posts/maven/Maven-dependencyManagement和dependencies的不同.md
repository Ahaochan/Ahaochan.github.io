---
title: dependencyManagement和dependencies的不同
url: differences_between_dependencymanagement_and_dependencies_in_maven
tags:
  - Maven
categories:
  - Maven
date: 2018-06-08 17:23:00
---

# 前言
随着`Spring`全家桶越做越大，和其他框架的结合的机会也越来越多，现在做`Web`基本是起手就是一个`Spring`。这就会出现版本号冲突的问题，比如新的`Spring`和旧的`Quartz`不兼容之类的情况。

<!-- more -->

# Spring framework bom
为了解决这个问题，`Spring`推出了[`spring-framework-bom`](https://mvnrepository.com/artifact/org.springframework/spring-framework-bom/4.2.0.RELEASE)。`Spring Boot`有对应的[`spring-boot-dependencies`](https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-dependencies)。
只需要将以下`pom.xml`加入我们项目的`pom.xml`，就不用在`dependencies`标签中写版本号。`dependencyManagement`会自动帮我们引入版本号。
```xml
<project>
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-framework-bom</artifactId>
                <version>${spring.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <dependencies>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-web</artifactId>
        </dependency>
    </dependencies>
</project>
```

我们可以看下`spring-framework-bom`的源码，可以看到它已经默认为我们填好了版本号。
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.springframework</groupId>
    <artifactId>spring-framework-bom</artifactId>
    <version>4.2.0.RELEASE</version>
    <packaging>pom</packaging>
    <name>Spring Framework (Bill of Materials)</name>
    <description>Spring Framework (Bill of Materials)</description>
    <url>
        https://github.com/spring-projects/spring-framework
    </url>
    <organization>
        <name>Spring IO</name>
        <url>http://projects.spring.io/spring-framework</url>
    </organization>
    <licenses>
        <license>
            <name>The Apache Software License, Version 2.0</name>
            <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>
            <distribution>repo</distribution>
        </license>
    </licenses>
    <developers>
        <developer>
            <id>jhoeller</id>
            <name>Juergen Hoeller</name>
            <email>jhoeller@pivotal.io</email>
        </developer>
    </developers>
    <scm>
        <connection>
            scm:git:git://github.com/spring-projects/spring-framework
        </connection>
        <developerConnection>
            scm:git:git://github.com/spring-projects/spring-framework
        </developerConnection>
        <url>
            https://github.com/spring-projects/spring-framework
        </url>
    </scm>
    <issueManagement>
        <system>Jira</system>
        <url>https://jira.springsource.org/browse/SPR</url>
    </issueManagement>
    <!--===================注意这里===================-->
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-aop</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-aspects</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-beans</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-context</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-context-support</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-core</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-expression</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-instrument</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-instrument-tomcat</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-jdbc</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-jms</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-messaging</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-orm</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-oxm</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-test</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-tx</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-web</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-webmvc</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-webmvc-portlet</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
            <dependency>
                <groupId>org.springframework</groupId>
                <artifactId>spring-websocket</artifactId>
                <version>4.2.0.RELEASE</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
    <!--===================注意这里===================-->
</project>
```

# 总结
`dependencyManagement`是一个版本号管理器，官方说法是**中央依赖版本管理**。
`dependencyManagement`子标签中的`dependency`声明的版本号，可以被引用了该`dependencyManagement`的`pom.xml`继承，但是需要在`pom.xml`中声明`dependency`而不必声明版本号。
简单地说，就是自己的`pom.xml`不用再写`dependencyManagement`中拥有的`dependency`的版本号了，但是要写`dependency`的**名称**(这里的名称只是形象的说法)

**!!注意!!**
`dependencyManagement`并不会产生继承关系，引用了`dependencyManagement`的新项目的`pom.xml`，仍需要**手动声明**引用的`dependency`，只是不用再写版本号。

如果需要继承的话，就使用`parent`标签，这里不赘述。
```xml
    <parent>
        <artifactId>ahao-all</artifactId>
        <groupId>com.ahao.core</groupId>
        <version>1.0</version>
    </parent>
```

# 参考资料
- [Apache官方文档 Dependency_Management 小节](
http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html#Dependency_Management)
- [differences-between-dependencymanagement-and-dependencies-in-maven](https://stackoverflow.com/questions/2619598)