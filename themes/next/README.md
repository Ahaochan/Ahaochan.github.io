# <div align="center"><a title="Go to homepage" href="https://github.com/iissnan/hexo-theme-next"><img align="center" width="56" height="56" src="../../blob/master/source/images/logo.svg"></a> e x T</div>

<div align="right">Language: :us:
<a title="Chinese" href="docs/zh-CN/README.md">:cn:</a>
<a title="Russian" href="docs/ru/README.md">:ru:</a></div>

<p align="center">NexT 是一个优雅的高质量的 <a href="http://hexo.io">Hexo</a> 主题. </p>
<p align="center">文档略有改动, 原版请看<a href="docs/zh-CN/README.md">Origin</a></p>


[![gitter-image]][gitter-url]
[![mnt-image]][commits-url]
[![travis-image]][travis-url]
[![rel-image]][releases-url]
[![hexo-image]][hexo-url]
[![lic-image]](LICENSE)

## 1. 预览

* :heart_decoration: Muse 模式: [LEAFERx](https://leaferx.online) | [XiaMo](https://notes.wanghao.work) | [OAwan](https://oawan.me)
* :six_pointed_star: Mist 模式: [Jeff](https://blog.zzbd.org) | [uchuhimo](http://uchuhimo.me) | [xirong](http://www.ixirong.com)
* :pisces: Pisces 模式: [Vi](http://notes.iissnan.com) | [Acris](https://acris.me) | [Rainy](https://rainylog.com)
* :gemini: Gemini 模式: [Ivan.Nginx](https://almostover.ru) | [Raincal](https://raincal.com) | [Dandy](https://dandyxu.me)

更多的 NexT 模板 [在这里](https://github.com/iissnan/hexo-theme-next/issues/119).

## 2. 安装
**2.1.** 安装环境
- [Node.js](https://nodejs.org/zh-cn/)
- [Git](https://git-for-windows.github.io/)
- [GitHub账号](https://github.com/)
- [Hexo](https://hexo.io/zh-cn/index.html)

**2.2.** 进入 **hexo** 根目录. 目录下必须包括 `node_modules`, `source`, `themes` 和其他文件夹:
```sh
   $ mkdir hexo                             # 创建hexo文件夹
   $ cd hexo                                # 进入hexo文件夹
   $ ls
   _config.yml  node_modules  package.json  public  scaffolds  source  themes
   $ npm install -g hexo-cli                # 全局安装hexo, 在nodejs/node_modules下
   $ hexo init                              # 初始化hexo模板
   $ npm install                            #
   $ hexo g                                 # 生成文件
   $ hexo s                                 # 部署到本地http://localhost:4000/上, 用浏览器打开即可。
```

**3.** 从 GitHub 获取 NexT 主题:

   可能是 **不稳定**, 但是包含了最新功能. 适合开发人员使用.
   
   [![git-image]][git-url]

   ```sh
   $  git clone -b master https://github.com/Ahaochan/hexo-theme-next.git themes/next
   ```

## 3. 更新

```sh
$ cd themes/next
$ git pull
```

## 4. 配置
使用`next.yml`取代`hexo/_config.yml`和`next/_config.yml`。
具体看[Hexo Data Files](https://hexo.io/zh-cn/docs/data-files.html)、[#328](https://github.com/iissnan/hexo-theme-next/issues/328)、[#445](https://github.com/iissnan/hexo-theme-next/issues/445)。

> 优先级: next.yml > 主题配置 > 站点配置

### 使用

1. 确保你使用 Hexo 3 (或更高)
2. 创建`hexo/source/_data/next.yml`文件
3. **复制** `hexo/_config.yml` 和 `next/_config.yml` 进 `source/_data_next.yml`.
4. 使用 `--config source/_data/next.yml` 参数去启动服务器(start server), 渲染(generate) 或 部署(deploy).\
   例如: `hexo clean --config source/_data/next.yml && hexo g --config source/_data/next.yml`.
