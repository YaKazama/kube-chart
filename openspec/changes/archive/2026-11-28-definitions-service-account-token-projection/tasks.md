# definitions.serviceAccountTokenProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ServiceAccountTokenProjection.tpl`：新增 `definitions.serviceAccountTokenProjection`，按 `audience`、`expirationSeconds`、`path` 顺序渲染，`path` 相对路径与逃逸校验、`expirationSeconds` 最小 600；对应 `ServiceAccountTokenProjection 字段渲染`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：仅提供 `path`，确认输出仅包含 `path`，真实加载 `base.*` 依赖。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：提供 `audience`、`expirationSeconds: 600`、`path`，确认官方顺序；空 `audience`、空 `expirationSeconds` 不输出；`path: a/../b` 归一化为 `b`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：`path` 缺失、绝对路径、归一化后 `..` 或 `../` 开头，`expirationSeconds` 为 599 或非整数，`audience` 非字符串时分别中断并报错。
