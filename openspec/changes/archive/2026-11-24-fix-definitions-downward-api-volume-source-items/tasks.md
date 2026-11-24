# definitions.downwardAPIVolumeSource items 过滤任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_DownwardAPIVolumeSource.tpl`：在 writable scope（文件头契约注释与 `define "definitions.downwardAPIVolumeSource"` 块）内，把 string item 分支改为按 field/resource 形态判定与捕获提取，构造 `{path, [mode], fieldRef|resourceFieldRef: <string>}` 上下文，保留 map item 直传、子模板委托与输出处理；同步更新契约注释与形态不匹配的失败消息；对应 `Decision: string item 形态判定与字段提取`、`Decision: map item 直传`、`Decision: 子模板委托与 items 输出`、`Decision: 失败消息与契约注释`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效渲染：加载 `templates/base/`、`_DownwardAPIVolumeSource.tpl` 与动态调用入口，提供 `definitions.downwardAPIVolumeFile` 回显 fixture，渲染 `{defaultMode: "0644", items: ["  meta 0400 field metadata.name  "]}`，确认 `defaultMode: 420` 且子模板收到 `{path: "meta", mode: "0400", fieldRef: "metadata.name"}`；对应验证设计的最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 较完整有效渲染：覆盖 field 无 mode 带 apiVersion、resource 带 mode/containerName/divisor、map item 原样直传、map 与 string 混合且顺序不变、空白 string 跳过、空 `items`、显式 `defaultMode: 0`；对应验证设计的较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败渲染：覆盖 `items` 非 array、元素类型非法、string 形态不匹配、非法 `defaultMode`、子模板输出为空时跳过、子模板输出非法 YAML 或非 map 时中断；对应验证设计的关键失败项。
