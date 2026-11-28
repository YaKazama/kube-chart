# definitions.downwardAPIProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_DownwardAPIProjection.tpl`：新增 `definitions.downwardAPIProjection` 及紧邻中文契约注释，渲染 `items` 并逐项委托 `definitions.downwardAPIVolumeFile`，落实空结果剔除、结果去重与空输出省略；对应 `渲染 items 字段`、`items 委托、去重与去空`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：分别以 `{}`、`{items: []}` 与 `{items: [{path: "meta/name", fieldRef: "metadata.name"}]}` 渲染，预期前两者输出为空，最后一个输出一个 `items` 条目。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart：以两个完全相同的 DownwardAPIVolumeFile 渲染，预期 `items` 去重为一个条目。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：验证 `items` 非 array、条目非 map、条目缺少 `fieldRef`/`resourceFieldRef`、`path` 为绝对路径或逃逸路径、`fieldRef` 类型非法时均中断并报告字段错误。
