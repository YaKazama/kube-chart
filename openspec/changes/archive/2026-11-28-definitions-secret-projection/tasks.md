# definitions.secretProjection 任务

## 实施

- [x] T1 `templates/api-resources/definitions/_SecretProjection.tpl`：新增 `definitions.secretProjection`，按 `items`、`name`、`optional` 顺序渲染，`items` 委托 `definitions.keyToPath` 并去重去空；对应 `SecretProjection 字段渲染`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：仅提供 `name`，确认输出仅包含 `name`，真实加载 `definitions.keyToPath` 与 `base.*` 依赖。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：`items` 含重复条目与空结果并配合显式 `optional: false`，确认 `items`、`name`、`optional` 顺序、去重去空和 `false` 输出；空 `items`、空 `optional` 不输出对应字段。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：`items` 非数组、条目非 map、条目 KeyToPath 字段非法、`name` 缺失或非法、`optional` 非法值时分别中断并报错。
