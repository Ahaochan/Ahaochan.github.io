---
title: 什么是Json Web Token
url: What_is_Json_Web_Token?
tags:
  - Java SE
categories:
  - Java SE
date: 2019-07-03 17:03:00
---

# 前言
`Jwt`全称`Json Web Token`, 是一种防篡改的数据格式, 可以明文, 可以加密. 我们可以用来存储简单的鉴权信息在`Jwt`之中.
现在主流的应用场景有单点登录, 替代`Session`, 一次性鉴权.

但是我发现了这篇文章[Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/), 作者说不要用`Jwt`来进行身份认证.
建议看完本文后, 再深入阅读这篇文章.

<!-- more -->

`Jwt`只是一种数据格式, 就像`JSON`一样!
`Jwt`只是一种数据格式, 就像`JSON`一样!
`Jwt`只是一种数据格式, 就像`JSON`一样!
重要的话说`3`遍, 好了往下看.

# 结构组成
```text
eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJKb2UifQ.gG3FV1r3HgYYUd04sTUh2asQbk68SjmkivuaBHCRhLo
```
上面是一个`JWT`, 分为`3`个部分, `header`和`claims`都是用`base64`编码, `3`个部分用`.`连接起来.
1. `header`: 头部, 最少包含了签名算法.
1. `claims`: 内容, 包含了你想要放进去的数据.
1. `signature`: 签名

用`base64`解码`header`和`claims`可得
```text
eyJhbGciOiJIUzI1NiJ9 ----> {"alg":"HS256"}
eyJzdWIiOiJKb2UifQ   ----> {"sub":"Joe"}
```
后面的`gG3FV1r3HgYYUd04sTUh2asQbk68SjmkivuaBHCRhLo`是签名, 是不可读的, 签名算法就是`header`的`alg`字段的值`HS256`.
可以在[`Debugger`工具](https://jwt.io/)测试.

`Q1`: 为什么说`Jwt`是防篡改的?
`A1`: 我们不知道签名的私钥, 不信你在[`Debugger`工具](https://jwt.io/)试试, 用上面的`header`和`claims`, 在不知道私钥的情况下, 你能得到`gG3FV1r3HgYYUd04sTUh2asQbk68SjmkivuaBHCRhLo`吗? 我就告诉你私钥是`123456`了, 你猜的到吗?

`Q2`: `Jwt`能用来替换`Session`吗?
`A2`: 它们应该是组合使用, 而不是对立的. [Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/)

`Q3`: 那我到底要在什么地方用`Jwt`?
`A3`: 一般移动端用的比较多, 移动端不像浏览器有一套透明的`Cookie`方案.

# JJWT 应用
我们先来看一个例子
```java
public class JwtTest {
    @Test
    void verify() {
        long now = System.currentTimeMillis();

        // 1. 生成 jwt
        String key = Base64.getEncoder().encodeToString("signKey".getBytes(StandardCharsets.UTF_8));
        JwtBuilder builder = Jwts.builder()
            .setId("id")                // JWT_ID
            .setAudience("audience")    // 接受者
            .setSubject("subject")      // 主题
            .setIssuer("issuer")        // 签发者
            .addClaims(null)            // 自定义属性
            .setIssuedAt(new Date(now))        // 签发时间
            .setNotBefore(new Date(now - 1))   // 生效时间
            .setExpiration(new Date(now + 1000 * 60 * 60))  // 过期时间
            .signWith(SignatureAlgorithm.HS256, key); // 签名算法以及密匙
        String token = builder.compact();
        System.out.println(token);

        // 2. 解析 jwt
        try {
            Jws<Claims> jws = Jwts.parser()
                .setSigningKey(key)
                .parseClaimsJws(token);
            JwsHeader header = jws.getHeader();
            Claims claims = jws.getBody();

            Assertions.assertEquals(SignatureAlgorithm.HS256.getValue(), header.getAlgorithm());
            Assertions.assertEquals("id", claims.getId());
            Assertions.assertEquals("audience", claims.getAudience());
            Assertions.assertEquals("subject", claims.getSubject());
            Assertions.assertEquals("issuer", claims.getIssuer());
        } catch (ExpiredJwtException e) {
            e.printStackTrace();
        }
    }
}
```
`JwtBuilder`使用`Builder`模式, 构建`header`和`claims`, 最后再调用`signWith`方法添加`signature`签名.
之后我们使用`Jwts.parser()`来解析`token`, 在`parseClaimsJws(token)`会抛出一堆`RuntimeException`, 用来校验`token`是否有效.
得到的`Claims`其实就是一个`Map`, 我们从中获取需要的数据即可.

# 整合 Spring Boot
查看我在`Github`上的一个示例工程.
https://github.com/Ahaochan/project/tree/master/ahao-spring-boot-jwt

# 参考资料
- [JSON Web Token](https://jwt.io/)
- [Stop using JWT for sessions](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/)
- [Stop using JWT for sessions, part 2: Why your solution doesn't work](http://cryto.net/~joepie91/blog/2016/06/19/stop-using-jwt-for-sessions-part-2-why-your-solution-doesnt-work/)
