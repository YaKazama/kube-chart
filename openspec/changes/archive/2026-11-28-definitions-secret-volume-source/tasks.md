# definitions.secretVolumeSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_SecretVolumeSource.tpl`：新增 `definitions.secretVolumeSource`，按 `defaultMode`、`items`、`optional`、`secretName` 顺序渲染；items 支持 map/string 混合并清洗、去重去空，secretName 按 `1123sub` 校验；对应 `SecretVolumeSource 字段渲染`、`items 解析、委托与去重`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：仅提供 `secretName`，确认输出仅包含 `secretName`，真实加载 `definitions.keyToPath` 与 `base.*` 依赖。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：提供 `defaultMode: "0644"`、string 与 map 混合 items、`optional: false`、合法 `secretName`，确认官方顺序、string 清洗、去重去空与 `false` 输出；空 items、空 `defaultMode`/`optional` 不输出对应字段。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：`secretName` 缺失或非法、`items` 非数组、元素类型非法、string 格式非法、KeyToPath 字段非法、`optional` 非法值时分别中断并报错。
