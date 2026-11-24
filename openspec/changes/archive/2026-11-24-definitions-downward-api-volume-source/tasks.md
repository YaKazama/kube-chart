# definitions.downwardAPIVolumeSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_DownwardAPIVolumeSource.tpl`：新建 `definitions.downwardAPIVolumeSource` 契约注释与 `define` 块，实现 `defaultMode` 归一化、`items` 数组类型门禁、空白 string 跳过、string 以 `dict "item"` 原样包装、map 原样传递、子模板委托与 `items` 渲染；对应 `Decision: defaultMode 归一化`、`Decision: items 原样委托`、`Decision: 错误消息与输出处理`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效渲染：加载 `templates/base/`、`_DownwardAPIVolumeSource.tpl` 与动态调用入口，提供 `definitions.downwardAPIVolumeFile` 回显 fixture，渲染 `{defaultMode: "0644", items: ["meta 0400 field metadata.name"]}`，确认 `defaultMode: 420` 且子模板收到 `{item: "meta 0400 field metadata.name"}`；对应 `验证设计` 的最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 较完整有效渲染：覆盖 map item 原样传递、map 与 string 混合、空白 string 跳过、空 `items` 与显式 `defaultMode: 0`，确认不构造 `path`/`fieldRef`/`mode` 且顺序不变；对应 `验证设计` 的较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败渲染：覆盖 `items` 非 array、元素类型非法、非法 `defaultMode`，以及子模板输出为空时跳过、输出非法 YAML 或非 map 时中断；对应 `验证设计` 的关键失败项。
