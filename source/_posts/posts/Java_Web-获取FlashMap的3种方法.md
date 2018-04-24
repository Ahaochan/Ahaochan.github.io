---
title: 获取FlashMap的3种方法
url: How_to_get_FlashMap_in_Spring_MVC
tags:
  - Spring MVC
categories:
  - Java Web
date: 2017-08-30 23:16:36
---
# 前言
`FlashMap` 是传递重定向参数的时候要用到的一个类。
<!-- more -->

# getAttributes(笨重, 不推荐)
在源码 `DispatcherServlet` 的 `doService` 方法中注入了 `FlashMap`
```java
// org.springframework.web.servlet.DispatcherServlet
public class DispatcherServlet extends FrameworkServlet {
    @Override
    protected void doService(HttpServletRequest request, HttpServletResponse response) throws Exception {
        FlashMap inputFlashMap = this.flashMapManager.retrieveAndUpdate(request, response);
        if (inputFlashMap != null) {
            request.setAttribute("org.springframework.web.servlet.DispatcherServlet.INPUT_FLASH_MAP", Collections.unmodifiableMap(inputFlashMap));
        }
        request.setAttribute("org.springframework.web.servlet.DispatcherServlet.OUTPUT_FLASH_MAP", new FlashMap());
        request.setAttribute("org.springframework.web.servlet.DispatcherServlet.FLASH_MAP_MANAGER", this.flashMapManager);
    }
}
```
所以我们可以使用 `getAttributes` 获取
```java
@Controller
public class DemoController {
    @GetMapping("/redirect")
    public String redirect() {
        FlashMap redirectAttributes = (FlashMap) ((ServletRequestAttributes) (RequestContextHolder.getRequestAttributes()))
                .getRequest().getAttribute("org.springframework.web.servlet.DispatcherServlet.OUTPUT_FLASH_MAP");
        redirectAttributes.put("key", "value");
        return "redirect:/demo";
    }
    @GetMapping("/demo")
    public String demo(Model model) {
        return "view.jsp";
    }
}
```

# 通过 RequestContextUtils 获取
`Spring`早已将上面的获取代码封装到 `RequestContextUtils` 中
```java
@Controller
public class DemoController {
    @GetMapping("/redirect")
    public String redirect(HttpServletRequest request) {
        FlashMap redirectAttributes = RequestContextUtils.getOutputFlashMap(request);
        redirectAttributes.put("key", "value");
        return "redirect:/demo";
    }
    @GetMapping("/demo")
    public String demo(Model model) {
        return "view.jsp";
    }
}

// org.springframework.web.servlet.support.RequestContextUtils
public abstract class RequestContextUtils {
    public static FlashMap getOutputFlashMap(HttpServletRequest request) {
		return (FlashMap) request.getAttribute(DispatcherServlet.OUTPUT_FLASH_MAP_ATTRIBUTE);
	}
}
```

# Spring MVC 在 Controller 注入形参
```java
@Controller
public class DemoController {
    @GetMapping("/redirect")
    public String redirect(RedirectAttributes redirectAttributes) {
        // 和上面一样, 保存到 OUTPUT_FLASH_MAP 中
        redirectAttributes.addFlashAttribute("key1", "value2");
        // 不保存到 flashMap 中, 拼接到 url 中
        redirectAttributes.addAttribute("key2", "value2");
        return "redirect:/demo";
    }
    @GetMapping("/demo")
    public String demo(Model model) {
        return "view.jsp";
    }
}
```
