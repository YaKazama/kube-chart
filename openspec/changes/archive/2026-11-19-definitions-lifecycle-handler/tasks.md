# definitions.lifecycleHandler 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 writable scope `K8S.LIFECYCLE_HANDLER` 子树内新增 `K8S.LIFECYCLE_HANDLER.HTTP_GET` 与 `K8S.LIFECYCLE_HANDLER.TCP_SOCKET` 两个位置捕获正则；对应 `Decision: 抽象字段解析`。
- [x] T2 `templates/api-resources/Definitions/_LifecycleHandler.tpl`：在 writable scope 整个新文件内新增 `definitions.lifecycleHandler`，实现单动作检测、原生与抽象分支、字段解析及子模板委托；对应 `Decision: 单动作检测与分派`、`Decision: 原生与抽象按运行时类型分支`、`Decision: 抽象字段解析`、`Decision: 子模板委托与错误保护`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：以子模板 stub 渲染原生 `sleep` 与 host 缺省的抽象 `tcpSocket`，预期动作键、map 上下文及空字符串位置正确。
- [x] V2 `/tmp/` 最小 application Chart：渲染完整有效场景，覆盖原生四动作、抽象 `exec`、完整 `httpGet`、完整 `tcpSocket`、空格与逗号混合的 headers、尾部位置缺省、`httpHeaders` 直传与构造及 `sleep: 0`，预期 `helm template` 成功且输出符合设计。
- [x] V3 `/tmp/` 最小 application Chart：执行零动作、多动作、错误类型、逗号组内奇数 header token 和子模板非法 YAML 场景，预期 `helm template` 非零退出并命中对应错误。
