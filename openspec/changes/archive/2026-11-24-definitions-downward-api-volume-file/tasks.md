# definitions.downwardAPIVolumeFile 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_DownwardAPIVolumeFile.tpl`：新增整体契约注释与 `definitions.downwardAPIVolumeFile`，实现引用互斥与 map/string 类型分派、字符串位次解析、`path`/`mode` 归一化、选择器委托与按 API 顺序渲染；对应 `DownwardAPIVolumeFile 字段渲染`、`字段引用解析与委托`、`path 与 mode 校验`、`引用互斥与空值`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：使用真实 `base.*` 与选择器依赖，以原生 map（`path` + `fieldRef`）执行最小有效渲染，预期 `fieldRef` 后输出 `path`。
- [x] V2 `/tmp/sd-kube-chart/`：使用真实依赖，以原生 map（`path` + `mode` + `resourceFieldRef`）及字符串引用执行较完整有效渲染，预期字段顺序与 `mode` 十进制输出正确。
- [x] V3 `/tmp/sd-kube-chart/`：使用真实依赖，覆盖引用并存、都缺失、为空、引用类型非法、`path` 绝对路径或 `../` 逃逸、`mode` 越界与选择器拒绝等关键失败输入，预期渲染中断且错误包含模板名与字段名。
