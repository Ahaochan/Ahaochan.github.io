---
title: OkHttp使用
url: how_to_use_OKHttp
date: 2016-07-27 16:39:34
tags: 
  - OKHttp
categories: 
  - Android
---
# 导入gradle
[OkHttp地址](https://github.com/square/okhttp)
<!-- more -->
在gradle中加入
```groovy
dependencies {
    compile fileTree(dir: 'libs', include: ['*.jar'])
    testCompile 'junit:junit:4.12'
    compile 'com.squareup.okhttp3:okhttp:3.4.1'
    compile 'com.squareup.okio:okio:1.9.0'
}
```

# 创建OkHttpClient
```java
OkHttpClient mOkHttpClient = new OkHttpClient();
```

# 创建Request
```java
Request mRequest = new Request.Builder()
                .url("http://www.baidu.com")
                .build();
```

# 创建回调Call并异步执行
```java
Call call = mOkHttpClient.newCall(mRequest);
call.enqueue(new Callback() {
    @Override
    public void onFailure(Call call, IOException e) {
        Log.i(TAG, "失败");
    }

    @Override
    public void onResponse(Call call, Response response) throws IOException {
        Log.i(TAG, "成功"+response.body());
        final String html = response.body().string();
        runOnUiThread(new Runnable() {//在子线程中更新ui
            @Override
            public void run() {
                contentView.setText(html);
            }
        });
    }
});
```
