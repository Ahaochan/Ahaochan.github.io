---
title: Spring MVC同时支持驼峰和下划线
url: Support_both_snake_case_and_camelCase_in_Spring_MVC
tags:
  - Spring MVC
  - 源码分析
categories:
  - Java Web
date: 2020-07-31 18:44:03
---
# 前言
`PHP`是下划线命名变量, `Java`是驼峰命名变量.
对于前端来说, 服务端有两种命名规则, 这是不合理的, 他们希望有一种统一的命名规则.

<!-- more -->

# 歪路1: 用ObjectMapper在Controller层做转换
为了赶进度, 我直接在`Controller`层做了转换.
```java
@RestController
public class MyController {
    @PostMapping("/post1")
    public Object post1() {
        // 1. 获取数据
        MyObj obj = new MyObj();
        
        // 2. 创建一个 SNAKE_CASE 下划线风格的 ObjectMapper, 转为 Map
        ObjectMapper om = new ObjectMapper();
        om.setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
        Object o = om.convertValue(result, new TypeReference<Map<String, Object>>() {});
        return o;
    }
}
```
问题迎刃而解, 简单粗暴.
但是这里有个待优化的地方
1. 每个方法都要写一套转换代码, 就算转成`AOP`的实现, 也不够优雅
2. 每次都要`new ObjectMapper()`和转换.

# 歪路2: Hack @ResponseBody 处理器
`Jackson`提供了一个`@JsonNaming`的注解, 用于修饰`POJO`的序列化命名方式.
但是这个`@JsonNaming`注解只能修饰在类上, 不能修饰在方法级别.

我们猜测, 可以创建一个`@MyJsonNaming`的注解, 仿照`@ResponseBody`处理器对返回体做处理.
```java
@RestController
public class MyController {
    @PostMapping("/post2")
    @MyJsonNaming(PropertyNamingStrategy.SnakeCaseStrategy.class)
    public Object post2() {
        // 1. 获取数据
        MyObj obj = new MyObj();
        return obj;
    }
}
```
我们看看`Spring MVC`是怎么拦截`@ResponseBody`注解的?
```java
// org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter
public class RequestMappingHandlerAdapter extends AbstractHandlerMethodAdapter implements BeanFactoryAware, InitializingBean {
    @Override
    public void afterPropertiesSet() {
        // 省略其他代码
        if (this.returnValueHandlers == null) {
            // 这里初始化一堆默认的返回值处理器, 其中就包括了 @ResponseBody 的处理器
            List<HandlerMethodReturnValueHandler> handlers = getDefaultReturnValueHandlers();
            this.returnValueHandlers = new HandlerMethodReturnValueHandlerComposite().addHandlers(handlers);
        }
    }
    private List<HandlerMethodReturnValueHandler> getDefaultReturnValueHandlers() {
        List<HandlerMethodReturnValueHandler> handlers = new ArrayList<>();
        // 省略其他代码
        handlers.add(new RequestResponseBodyMethodProcessor(getMessageConverters(), this.contentNegotiationManager, this.requestResponseBodyAdvice));
        // WebMvcConfigurer 自定义处理器
        if (getCustomReturnValueHandlers() != null) {
            handlers.addAll(getCustomReturnValueHandlers());
        }
        return handlers;
    }
}
```
这里就有个问题了, 我通过实现`WebMvcConfigurer`自定义的处理器, 它的优先级永远比`RequestResponseBodyMethodProcessor`处理器的优先级要低.
也就是说, 我如果想使用`@MyJsonNaming`注解覆盖`@ResponseBody`的处理逻辑, 只能这样做.
1. 所有代码里, 不允许使用`@ResponseBody`和`@RestController`, 只允许使用`@MyJsonNaming`. 这是不可能也不允许的事情.
2. 使用`BeanPostProcessor`调整`RequestMappingHandlerAdapter`的`HandlerMethodReturnValueHandler`列表顺序. 看起来可行, 但总感觉走了弯路.

并且这样也有弊端, 如果同一个接口, 前端想用下划线的命名格式, 另一个`Java`服务想用驼峰的命名格式.
使用这种方式也实现不了.

# 正解: 使用Accept请求头决定响应体是驼峰还是下划线
换个思路, `Spring MVC`是支持`xml`和`json`的返回格式的. 
`Spring MVC`里面是怎么做到同一套代码支持不同的返回格式的? 本质上我们这个需求也是不同的返回格式.
我们前面已经知道, `@ResponseBody`的处理类是`RequestResponseBodyMethodProcessor`.
```java
// org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor
public class RequestResponseBodyMethodProcessor extends AbstractMessageConverterMethodProcessor {
    @Override
    public void handleReturnValue(@Nullable Object returnValue, MethodParameter returnType, ModelAndViewContainer mavContainer, NativeWebRequest webRequest) throws IOException, HttpMediaTypeNotAcceptableException, HttpMessageNotWritableException {
        // 调用父类的方法
        super.writeWithMessageConverters(returnValue, returnType, inputMessage, outputMessage);
    }
}
// org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodProcessor
public abstract class AbstractMessageConverterMethodProcessor extends AbstractMessageConverterMethodArgumentResolver implements HandlerMethodReturnValueHandler {
    protected <T> void writeWithMessageConverters(T value, MethodParameter returnType, ServletServerHttpRequest inputMessage, ServletServerHttpResponse outputMessage) throws IOException, HttpMediaTypeNotAcceptableException, HttpMessageNotWritableException {
        // 省略其他代码
        // 1. 获取请求头的 Accept
        MediaType selectedMediaType = null;
        // 2. 遍历 messageConverters, 找到支持该 MediaType 的 HttpMessageConverter 实现
        for (HttpMessageConverter<?> converter : this.messageConverters) {
            GenericHttpMessageConverter genericConverter = (converter instanceof GenericHttpMessageConverter ? (GenericHttpMessageConverter<?>) converter : null);
            if (genericConverter != null ? ((GenericHttpMessageConverter) converter).canWrite(targetType, valueType, selectedMediaType) : converter.canWrite(valueType, selectedMediaType)) {
               if (genericConverter != null) {
                   genericConverter.write(body, targetType, selectedMediaType, outputMessage);
               } else {
                   ((HttpMessageConverter) converter).write(body, selectedMediaType, outputMessage);
               }
                return; // 注意这里!!! 匹配上就直接return
            }
        }
    }
}
```
最终请求头`Accept:application/json`会匹配到`MappingJackson2HttpMessageConverter`.
它支持`application/json`和`application/*+json`, 注意这个通配符, 它会导致下面我的自定义请求头失效. 
因为 `HttpMessageConverter` 匹配到第一个就直接 `return` 了.

| 请求头| 例子 |
|:--------:|:--------:|
|`application/vnd.snake.case+json`| `my_name` |
|`application/vnd.upper.camel.case+json`| `MyName` |
|`application/vnd.lower.camel.case+json`| `myName` |
|`application/vnd.lower.case+json`| `myname` |
|`application/vnd.kebab+json`| `my-name` |
|`application/vnd.lower.dot+json`| `my.name` |

所以我们要做几个事情
1. 修改原有的`MappingJackson2HttpMessageConverter`, 让它只支持`application/json`
2. 在原有的`MappingJackson2HttpMessageConverter`后面追加我的自定义请求体的`MessageConverter`实现类.
3. 在最后添加一个处理`application/*+json`的兜底`MessageConverter`实现类.

```java
// https://github.com/Ahaochan/ahao-common-utils/blob/master/src/main/java/com/ahao/spring/web/config/JacksonHttpMessageConvertersWebMvcConfigurer.java
@Configuration
public class JacksonHttpMessageConvertersWebMvcConfigurer implements WebMvcConfigurer {

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * 覆盖 {@link JacksonHttpMessageConvertersConfiguration} 的配置, 移除 application/*+json 的支持
     * @see JacksonHttpMessageConvertersConfiguration.MappingJackson2HttpMessageConverterConfiguration#mappingJackson2HttpMessageConverter(com.fasterxml.jackson.databind.ObjectMapper)
     */
    @Bean
    public MappingJackson2HttpMessageConverter mappingJackson2HttpMessageConverter(ObjectMapper objectMapper) {
        MappingJackson2HttpMessageConverter converter = new MappingJackson2HttpMessageConverter(objectMapper);
        List<MediaType> mediaTypes = Arrays.asList(
            MediaType.APPLICATION_JSON
            // new MediaType("application", "*+json") // 移除 application/*+json 的支持
        );
        converter.setSupportedMediaTypes(mediaTypes);
        return converter;
    }

    @Override
    public void configureMessageConverters(List<HttpMessageConverter<?>> converters) {
        // 1. 找到插入位置
        List<MediaType> exceptMediaTypes = Collections.singletonList(MediaType.APPLICATION_JSON);
        int index = 0;
        for (int i = 0; i < converters.size(); i++) {
            HttpMessageConverter<?> converter = converters.get(i);
            if (converter instanceof MappingJackson2HttpMessageConverter) {
                index = i;
                List<MediaType> supportedMediaTypes = converter.getSupportedMediaTypes();
                Assert.isTrue(Objects.equals(exceptMediaTypes, supportedMediaTypes), "第 1 个 MappingJackson2HttpMessageConverter 支持的 MediaType:" + supportedMediaTypes + "应为" + exceptMediaTypes);
                break;
            }
        }
        index++;

        // 2. 补充多种 PropertyNamingStrategy
        PropertyNamingStrategy strategy = PropertyNamingStrategy.SNAKE_CASE;
        ObjectMapper clone = objectMapper.copy();
        clone.setPropertyNamingStrategy(strategy);

        MediaType mediaType = ExtMappingJackson2HttpMessageConverter.createMediaType(strategy);
        ExtMappingJackson2HttpMessageConverter converter = new ExtMappingJackson2HttpMessageConverter(clone, mediaType);

        converters.add(index, converter);
    }
}
```
至此, 响应体已经能根据请求头`Accept`来判断返回的数据格式是下划线命名还是驼峰命名了.

# 正解: 使用Content-Type请求头决定请求体是驼峰还是下划线
请求参数也一样可以根据请求头`Content-Type`来判断.
还是`RequestResponseBodyMethodProcessor`这个类来处理.
```java
// org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor
public class RequestResponseBodyMethodProcessor extends AbstractMessageConverterMethodProcessor {
    @Override
    public void handleReturnValue(@Nullable Object returnValue, MethodParameter returnType, ModelAndViewContainer mavContainer, NativeWebRequest webRequest) throws IOException, HttpMediaTypeNotAcceptableException, HttpMessageNotWritableException {
        // 调用父类的方法
        Object arg = readWithMessageConverters(inputMessage, parameter, paramType);
        return arg;
    }
}
// org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodProcessor
public abstract class AbstractMessageConverterMethodProcessor extends AbstractMessageConverterMethodArgumentResolver implements HandlerMethodReturnValueHandler {
    protected <T> Object readWithMessageConverters(HttpInputMessage inputMessage, MethodParameter parameter, Type targetType) throws IOException, HttpMediaTypeNotSupportedException, HttpMessageNotReadableException {
        // 省略其他代码
        // 1. 获取请求头的 Content-Type
        MediaType contentType = inputMessage.getHeaders().getContentType();
       
        // 2. 遍历 messageConverters, 找到支持该 MediaType 的 HttpMessageConverter 实现
        Object body = NO_VALUE;
        EmptyBodyCheckingHttpInputMessage message = new EmptyBodyCheckingHttpInputMessage(inputMessage);
        for (HttpMessageConverter<?> converter : this.messageConverters) {
            Class<HttpMessageConverter<?>> converterType = (Class<HttpMessageConverter<?>>) converter.getClass();
            GenericHttpMessageConverter<?> genericConverter = (converter instanceof GenericHttpMessageConverter ? (GenericHttpMessageConverter<?>) converter : null);
            if (genericConverter != null ? genericConverter.canRead(targetType, contextClass, contentType) : (targetClass != null && converter.canRead(targetClass, contentType))) {
                if (message.hasBody()) {
                    body = (genericConverter != null ? genericConverter.read(targetType, contextClass, msgToUse) : ((HttpMessageConverter<T>) converter).read(targetClass, msgToUse));
                }
                break; // 注意这里!!! 匹配上就直接return
            }
        }
        return body;
    }
}
```
可以看到和响应体的处理逻辑差不多, 也是筛选`MessageConverter`.
那么我们之前的配置, 也可以派上用场了. 直接在请求头`Content-Type`添加自定义的参数即可.

# 自定义 MessageConverter 不能处理的情况
现在的`Web`开发, 基本都是前后端分离的架构, 所以基本每个请求都是用`@ResponseBody`修饰的.
但是请求的话, 不一定都是`application/json`的请求, 也不一定都是`@RequestBody`修饰的请求参数.

对于客户端来说, 它可能会发送`GET`请求过来, 也可能发请求头为`application/x-www-form-urlencoded`的请求过来, 也可能发请求头为`application/json`的请求过来.

## GET 请求如何处理
对于`GET`请求, 会走`RequestParamMethodArgumentResolver`这个参数处理器.
```java
// org.springframework.web.method.annotation.AbstractNamedValueMethodArgumentResolver
public abstract class AbstractNamedValueMethodArgumentResolver implements HandlerMethodArgumentResolver {
    private NamedValueInfo getNamedValueInfo(MethodParameter parameter) {
        // 1. 交给子类实现, 从 @RequestParam 获取参数名
        NamedValueInfo namedValueInfo = createNamedValueInfo(parameter);
        // 2. 如果没有配置 @RequestParam, 就反射获取变量名
        namedValueInfo = updateNamedValueInfo(parameter, namedValueInfo);
        return namedValueInfo;
    }
    private NamedValueInfo updateNamedValueInfo(MethodParameter parameter, NamedValueInfo info) {
        String name = info.name;
        if (info.name.isEmpty()) {
            name = parameter.getParameterName();
            if (name == null) {
                throw new IllegalArgumentException();
            }
        }
        String defaultValue = (ValueConstants.DEFAULT_NONE.equals(info.defaultValue) ? null : info.defaultValue);
        return new NamedValueInfo(name, info.required, defaultValue);
    }
}
// org.springframework.web.method.annotation.RequestParamMethodArgumentResolver
public class RequestParamMethodArgumentResolver extends AbstractNamedValueMethodArgumentResolver implements UriComponentsContributor {
    @Override
    protected NamedValueInfo createNamedValueInfo(MethodParameter parameter) {
        // 从 @RequestParam 获取参数名
        RequestParam ann = parameter.getParameterAnnotation(RequestParam.class);
        return (ann != null ? new RequestParamNamedValueInfo(ann) : new RequestParamNamedValueInfo());
    }
}
```
`GET` 请求并不会根据请求头`Content-Type`的不同而选择不同的命名规则. 代码里写的是什么就是什么.
如果想让`GET`请求也支持根据请求头`Content-Type`选择不同的命名规则, 只能写一个**过滤器**来处理了.
可以参考这个实现: https://gist.github.com/azhawkes/3db84b194b3e47423df2

## Content-Type: application/x-www-form-urlencoded 请求如何处理
`form data`的请求方式会走`ModelAttributeMethodProcessor`这个参数处理器.
同样的也不会受请求头`Content-Type`影响, 代码里写的是什么参数就是什么参数.
同样也只能写一个**过滤器**来处理.

# 总结
从`RequestResponseBodyMethodProcessor`这个处理器的名字也可以看出, 它只支持`@RequestBody`和`@ResponseBody`.
其他格式的请求参数, 就只能用过滤器的形式`Hack`了.

# 参考资料
- [Http Message Converters with the Spring Framework](http://www.baeldung.com/spring-httpmessageconverter-rest)
- [Hot to make jackson to use snake_case / camelCase on demand in a Spring Boot REST API?](https://stackoverflow.com/a/43085405)