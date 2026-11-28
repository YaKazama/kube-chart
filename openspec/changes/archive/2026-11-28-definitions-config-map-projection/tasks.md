# definitions.configMapProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ConfigMapProjection.tpl`：新增 `definitions.configMapProjection` 及紧邻中文契约注释，按官方顺序渲染 `items`、`name`、`optional`，落实 `name` 必填与 RFC1123 Subdomain 校验、`items` 逐项委托 `definitions.keyToPath` 及结果去重去空、`optional` 布尔归一化；对应 `渲染字段与顺序`、`name 必填且为合法 ConfigMap 名称`、`items 委托、去重与去空`、`optional 布尔`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：以 `{name: "app-config"}` 渲染，预期仅输出 `name: "app-config"`。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：以 `{name: "app-config", items: [{key: "LOG_LEVEL", path: "app/config.conf"}, {key: "LOG_LEVEL", path: "app/config.conf"}], optional: false}` 渲染，预期 `items` 去重为一个条目，并输出 `optional: false`，顺序为 `items`、`name`、`optional`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：验证缺失或空白 `name`、非法 `name`、`items` 非 array、条目非 map、条目缺少 `key` 或 `path`、`path` 为绝对路径或逃逸路径、`optional` 非法值时均中断并报告字段错误。
