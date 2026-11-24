# definitions.volume downwardAPI items 格式调整任务

## 实施

- [x] T1 `templates/base/_env.tpl`：将 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 更新为 `<path> [mode] field <fieldPath> [apiVersion]` 的捕获顺序，将 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 更新为 `<path> [mode] resource <resource> [containerName] [divisor]` 的捕获顺序，并同步这两个键的紧邻注释；对应 `Decision: item 段位与捕获组调整`。
- [x] T2 `templates/api-resources/Definitions/_Volume.tpl`：将 `downwardAPI` 分支 item 格式不匹配的失败消息更新为 `<path> [mode] field <fieldPath> [apiVersion]` 与 `<path> [mode] resource <resource> [containerName] [divisor]`；对应 `Decision: 错误消息同步`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效渲染：加载 `templates/base/` 与 `_Volume.tpl`，提供 `definitions.downwardAPIVolumeSource` 回显 fixture，渲染 `downwardAPI: "0644 items (meta 0400 field metadata.name)"`，确认 `defaultMode` 与 `items` 原始值下传；对应 `验证设计` 的最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 较完整有效渲染：覆盖省略 mode 的 field、带 apiVersion 的 field、`meta field metadata.name 0400`、`cpu resource limits.cpu`、`cpu 0644 resource limits.cpu app 1m`、大小写混合关键字与多 item，确认匹配与原始字符串下传；对应 `验证设计` 的较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败渲染：覆盖旧 resource 末尾 mode、缺少 fieldPath、缺少 resource、field 多余段、空 `items ()` 与顶层简写不匹配，确认全部中断且消息使用新段位；对应 `验证设计` 的关键失败项。
