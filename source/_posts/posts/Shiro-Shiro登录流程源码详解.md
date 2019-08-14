---
title: Shiro登录流程源码详解
url: Shiro_login_process_source_code_explain
tags:
  - Shiro
categories:
  - Shiro
date: 2019-08-14 17:09:07
---
# 前言
本文假设读者能正常使用`Shiro`, 并对知道相关类是做什么用的.
这里截取部分代码来追踪, 为了尽可能的简单, 这里没有使用`Spring`等其他框架, 纯粹的`Shiro`代码.
本文使用`ini`配置, 但不解析`IniRealm`内部逻辑.

<!-- more -->

# 单元测试例子
具体可以看[`IniRealmTest`](https://github.com/Ahaochan/project/blob/master/ahao-spring-boot-shiro/src/test/java/com/ahao/spring/boot/shiro/IniRealmTest.java)
```java
public class IniRealmTest {
    @Test
    public void test() {
        // 1. 加载 ini 配置, 初始化 SecurityManager
        Factory<SecurityManager> factory = new IniSecurityManagerFactory("classpath:shiro.ini");
        SecurityManager securityManager = factory.getInstance();
        SecurityUtils.setSecurityManager(securityManager);

        // 2. 获取 Subject
        Subject subject = SecurityUtils.getSubject();
        
        // 3. 使用帐号密码登录, 并创建 Session
        UsernamePasswordToken trueToken = new UsernamePasswordToken("username", "password");
        try {
            subject.login(trueToken);
        } catch (AuthenticationException e) {
            Assertions.fail();
        }

        // 4. 角色判断
        Assertions.assertTrue(subject.hasRole("role1"));

        // 5. 权限判断
        Assertions.assertTrue(subject.isPermitted("permission1"));

        // 6. 登出注销
        subject.logout();
    }
}
```
```ini
[users]
username = password,role1,role2

[roles]
role1=permission1,permission2
role2=permission3,permission4
```
登录逻辑就分为上述的六个步骤, 接下来一个个拆解.

# 获取安全管理器 SecurityManager
首先我们看`SecurityManager`的获取方法`factory.getInstance();`.
![IniSecurityManagerFactory继承树](https://yuml.me/diagram/nofunky;dir:LR/class/[IniSecurityManagerFactory]->[IniFactorySupport],[IniFactorySupport]->[AbstractFactory],[AbstractFactory]->[<<Factory>>])

以下代码省略部分代码, 保留核心逻辑.
```java
public abstract class AbstractFactory<T> implements Factory<T> {
    private T singletonInstance;
    public T getInstance() {
        // 1. 交由子类实现代码
        singletonInstance = createInstance();
        return singletonInstance;
    }
    protected abstract T createInstance();
}
public abstract class IniFactorySupport<T> extends AbstractFactory<T> {
    public static final String DEFAULT_INI_RESOURCE_PATH = "classpath:shiro.ini";
    public T createInstance() {
        // 1. 从 classpath:shiro.ini 获取 ini 配置
        Ini ini = resolveIni();
        // 2. 根据 ini 配置初始化 SecurityManager
        T instance = createInstance(ini);
        return instance;
    }
    protected abstract T createInstance(Ini ini);
}
public class IniSecurityManagerFactory extends IniFactorySupport<SecurityManager> {
    public static final String MAIN_SECTION_NAME = "main";
    public static final String SECURITY_MANAGER_NAME = "securityManager";
    public static final String INI_REALM_NAME = "iniRealm";
    
    protected SecurityManager createInstance(Ini ini) {
        SecurityManager securityManager = createSecurityManager(ini);
        return securityManager;
    }
    private SecurityManager createSecurityManager(Ini ini) {
        Ini.Section mainSection = ini.getSection(MAIN_SECTION_NAME);
        if (CollectionUtils.isEmpty(mainSection)) {
            mainSection = ini.getSection(Ini.DEFAULT_SECTION_NAME);
        }
        return createSecurityManager(ini, mainSection);
    }
    private SecurityManager createSecurityManager(Ini ini, Ini.Section mainSection) {
        // 1. 创建默认的 DefaultSecurityManager 和 IniRealm, 保存到这个 Map 里
        Map<String, ?> defaults = createDefaults(ini, mainSection);
        // 2. 初始化 ReflectionBuilder, 并往 Map 里塞了一个 DefaultEventBus
        Map<String, ?> objects = buildInstances(mainSection, defaults);
    
        // 3. 获取上面创建的 DefaultSecurityManager
        SecurityManager securityManager = getSecurityManagerBean();
    
        // 4. 获取上面的 IniRealm 注入到 DefaultSecurityManager 中
        Collection<Realm> realms = getRealms(objects);
        ((RealmSecurityManager) securityManager).setRealms(realms);
    
        return securityManager;
    }
}
```
可以看到, 创建`SecurityManager`的过程主要做了三件事
1. 创建默认的`DefaultSecurityManager`
2. 根据`shiro.ini`配置文件, 初始化`IniRealm`
3. 将`IniRealm`注入到`DefaultSecurityManager`中.

# 获取当前主体 Subject
接下来获取`Subject`
```java
public abstract class SecurityUtils {
    private static SecurityManager securityManager;
    public static Subject getSubject() {
        // 1. 从 ThreadLocal 获取 Subject, 第一次肯定获取不到, 需要去创建
        Subject subject = ThreadContext.getSubject();
        if (subject == null) {
            // 2. 初始化 Subject
            subject = (new Subject.Builder()).buildSubject();
            // 3. 缓存到 ThreadLocal 中
            ThreadContext.bind(subject);
        }
        return subject;
    }
}
public interface Subject {
    public static class Builder {
         SubjectContext subjectContext = new DefaultSubjectContext();
         public Subject buildSubject() {
             return SecurityUtils.securityManager.createSubject(this.subjectContext);
         }
    }
}
```
第一次我们肯定获取不到`Subject`, 所以需要创建, 跟踪源码可以看到调用了安全管理器`SecurityManager`的`createSubject`方法.
```java
public class DefaultSecurityManager extends SessionsSecurityManager {
    public Subject createSubject(SubjectContext subjectContext) {
        SubjectContext context = new DefaultSubjectContext(subjectContext);
        Subject subject = subjectFactory.createSubject(context);
        return subject;
    }
}
public class DefaultSubjectFactory implements SubjectFactory {
    public Subject createSubject(SubjectContext context) {
//        return new DelegatingSubject(principals, authenticated, host, session, sessionCreationEnabled, securityManager);
        return new DelegatingSubject(null, false, null, null, true, securityManager);
    }
}
```
找到最后, 是调用了一个`DefaultSubjectFactory`工厂, 来创建`DelegatingSubject`.
因为我们什么高大上的配置都没填, 所以就直接`null`和`false`来填充所需字段了.

# 重头戏身份认证 login
全部准备就绪了, 就开始登录吧`subject.login(trueToken)`.
```java
public class DelegatingSubject implements Subject {
    public void login(AuthenticationToken token) throws AuthenticationException {
        // 调用 SecurityManager
        Subject subject = securityManager.login(this, token);
    }
}
public class DefaultSecurityManager extends SessionsSecurityManager {
    private Authenticator authenticator = new ModularRealmAuthenticator();
    public Subject login(Subject subject, AuthenticationToken token) throws AuthenticationException {
        AuthenticationInfo info = authenticate(token);
        // 省略部分代码
        return loggedIn;
    }
    public AuthenticationInfo authenticate(AuthenticationToken token) throws AuthenticationException {
        // 调用 ModularRealmAuthenticator 认证器
        return this.authenticator.authenticate(token);
    }
}
```
我们可以看到`login()`方法实际上是调用了`ModularRealmAuthenticator`类的`authenticate()`方法.
`ModularRealmAuthenticator`认证器默认内置了`AtLeastOneSuccessfulStrategy`的认证策略.
看名字可以猜到, 只要有一个`Realm`验证通过, 那就验证通过了. 我们目前只有一个`IniRealm`, 所以不用管这个认证策略.
```java
public abstract class AbstractAuthenticator implements Authenticator, LogoutAware {
    public final AuthenticationInfo authenticate(AuthenticationToken token) throws AuthenticationException {
        // 交由 ModularRealmAuthenticator 实现
        AuthenticationInfo info = doAuthenticate(token);
        return info;
    }
}
public class ModularRealmAuthenticator extends AbstractAuthenticator {
    protected AuthenticationInfo doAuthenticate(AuthenticationToken authenticationToken) throws AuthenticationException {
        Collection<Realm> realms = getRealms();
        if (realms.size() == 1) {
            // 我们目前只有一个 IniRealm 
            return doSingleRealmAuthentication(realms.iterator().next(), authenticationToken);
        } else {
            return doMultiRealmAuthentication(realms, authenticationToken);
        }
    }
    protected AuthenticationInfo doSingleRealmAuthentication(Realm realm, AuthenticationToken token) {
        if (!realm.supports(token)) {
            throw new UnsupportedTokenException(msg);
        }
        // !!!! 注意这里 !!!!
        AuthenticationInfo info = realm.getAuthenticationInfo(token);
        if (info == null) {
            throw new UnknownAccountException(msg);
        }
        return info;
    }
}
```
可以看到我们调用了`Realm`的`getAuthenticationInfo()`方法, 但是这个方法和我们平常开发时重写的`doGetAuthenticationInfo()`方法不同.
`getAuthenticationInfo()`内部肯定是调用了`doGetAuthenticationInfo()`方法. 我们继续往里面.
```java
public abstract class AuthenticatingRealm extends CachingRealm implements Initializable {
    public final AuthenticationInfo getAuthenticationInfo(AuthenticationToken token) throws AuthenticationException {
        // 1. 获取缓存中的 Authentication, 第一次肯定获取不到
        AuthenticationInfo info = getCachedAuthenticationInfo(token);
        if (info == null) {
            // 2. 自定义 Realm 的实现
            info = doGetAuthenticationInfo(token);
        }
        // 3. 用户输入的密码和数据库中的密码进行比较, 可以在这里做加盐加密
        if (info != null) {
            assertCredentialsMatch(token, info);
        }
        return info;
    }
    protected abstract AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) throws AuthenticationException;
    
    protected void assertCredentialsMatch(AuthenticationToken token, AuthenticationInfo info) throws AuthenticationException {
        // 默认实现类 SimpleCredentialsMatcher
        CredentialsMatcher cm = getCredentialsMatcher();
        if (!cm.doCredentialsMatch(token, info)) {
            throw new IncorrectCredentialsException("错误");
        }
    }
}
```
`doGetAuthenticationInfo()`就是我们自定义`Realm`要实现的方法.
至此, 整个身份验证流程就走通了.
![Subject.Login()调用链](https://yuml.me/diagram/nofunky;dir:LR/class/[DelegatingSubject.login()]->[DefaultSecurityManager.login()],[DefaultSecurityManager.login()]->[ModularRealmAuthenticator.authenticate()],[ModularRealmAuthenticator.doAuthenticate()]->[AuthenticatingRealm.doGetAuthenticationInfo()])

# 权限认证
我们重写`Realm`除了`doGetAuthenticationInfo()`还要重写`doGetAuthorizationInfo()`.
但是我们上面身份认证只执行了`doGetAuthenticationInfo()`. 可以很容易猜到, `Shiro`使用了懒加载的方式去加载角色权限.
还是老办法看源码, 看`subject.hasRole()`方法.
```java
public class DelegatingSubject implements Subject {
    public boolean hasRole(String roleIdentifier) {
        // 又是调用 SecurityManager
        return hasPrincipals() && securityManager.hasRole(getPrincipals(), roleIdentifier);
    }
}
public abstract class AuthorizingSecurityManager extends AuthenticatingSecurityManager {
    public boolean hasRole(PrincipalCollection principals, String roleIdentifier) {
        // 又是调用 ModularRealmAuthenticator, 然后调用 AuthorizingRealm
        return this.authorizer.hasRole(principals, roleIdentifier);
    }
}
public abstract class AuthorizingRealm extends AuthenticatingRealm implements Authorizer, Initializable, PermissionResolverAware, RolePermissionResolverAware {
    public boolean hasRole(PrincipalCollection principal, String roleIdentifier) {
        // !!!! 注意这里 !!!!
        AuthorizationInfo info = getAuthorizationInfo(principal);
        return hasRole(roleIdentifier, info);
    }
    protected boolean hasRole(String roleIdentifier, AuthorizationInfo info) {
        // 获取权限完毕后, 就判断有没有所需权限
        return info != null && info.getRoles() != null && info.getRoles().contains(roleIdentifier);
    }
}
```
鉴权就比较简单了, 我们直接一撸到底, 方法调来调去, 最后就是调用到`Realm`的`getAuthorizationInfo()`方法.
和之前一样, 内部肯定也是调用了`doGetAuthorizationInfo()`方法.
```java
public abstract class AuthorizingRealm extends AuthenticatingRealm implements Authorizer, Initializable, PermissionResolverAware, RolePermissionResolverAware {
    protected AuthorizationInfo getAuthorizationInfo(PrincipalCollection principals) {
        AuthorizationInfo info = null;

        // 1. 从缓存中获取, 第一次肯定没有
        Cache<Object, AuthorizationInfo> cache = getAvailableAuthorizationCache();
        info = cache.get(key);

        // 2. 调用 自定义 Realm 的 doGetAuthorizationInfo(), 然后缓存
        if (info == null) {
            info = doGetAuthorizationInfo(principals);
        }
        return info;
    }
}
```

# 注销 logout
注销也很简单, 就是把之前初始化的数据都清空就好了. 调用`Subject.logout()`注销.
```java
public class DelegatingSubject implements Subject {
    public void logout() {
        try {
            clearRunAsIdentitiesInternal();
            this.securityManager.logout(this);
        } finally {
            this.session = null;
            this.principals = null;
            this.authenticated = false;
            //https://issues.apache.org/jira/browse/JSEC-22
            //this.securityManager = null;
        }
    }
}
public class DefaultSecurityManager extends SessionsSecurityManager {
    public void logout(Subject subject) {
        // 1. 删除 remember me
        beforeLogout(subject);

        // 2. 清除缓存
        PrincipalCollection principals = subject.getPrincipals();
        if (principals != null && !principals.isEmpty()) {
            Authenticator authc = getAuthenticator();
            if (authc instanceof LogoutAware) {
                ((LogoutAware) authc).onLogout(principals);
            }
        }
        // 3. 从持久层删除 subject
        delete(subject);
        // 4. 停止 session
        stopSession(subject);
    }
}
```

# 总结
还有一些高级特性, 比如多`Realm`登陆, 单点登录, `Redis`持久化`Session`. 这里就不说了.
`Shrio`源码比起`Spring`的简单多了, 用久了其实都知道的七七八八, 阅读源码也就是个查缺补漏.