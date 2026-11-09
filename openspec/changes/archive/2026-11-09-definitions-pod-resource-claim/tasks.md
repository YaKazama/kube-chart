# definitions.podResourceClaim 模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodResourceClaim.tpl`：新增命名模板 `definitions.podResourceClaim`，按 `name`、`resourceClaimName`、`resourceClaimTemplateName` 渲染单个 `PodResourceClaim` 条目，并实现必填、仅空白等同未设置与两个引用字段恰一个成立的中断边界；对应 `Pod resourceClaim 条目渲染`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：直接调用 `definitions.podResourceClaim` 并传入 `name` 与 `resourceClaimName`，预期输出按 API 顺序的 `name`、`resourceClaimName` 两个带引号字段。
- [x] V2 `/tmp/` 最小 application Chart：仅设置 `resourceClaimTemplateName`（含首尾空白、YAML 引号包裹的 string 与 `<字段名>Alias` 生效路径），预期输出 `name`、`resourceClaimTemplateName` 两个带引号字段。
- [x] V3 `/tmp/` 最小 application Chart：`name` 缺失、为 `null`、为空字符串、仅空白，预期 `helm template` 中断并出现定位到 `name` 的消息。
- [x] V4 `/tmp/` 最小 application Chart：两个引用字段都未设置、都设置，预期 `helm template` 中断并出现定位到两个引用字段的消息。
- [x] V5 `/tmp/` 最小 application Chart：`name`、`resourceClaimName`、`resourceClaimTemplateName` 分别传入布尔、数值、map、list，预期 `helm template` 中断并出现定位到对应字段的消息。
