# definitions.volumeMount 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：新增 `K8S.VOLUME_MOUNT` 与 `K8S.VOLUME_MOUNT_SUB_PATH_LIKE` 常量，前者以 `(?i)` 整段匹配并按位置捕获六段，后者整段匹配变量形式；对应 `Decision: 字符串简写由 definitions.volumeMount 解析`、`Decision: 大小写处理`。
- [x] T2 `templates/api-resources/Definitions/_VolumeMount.tpl`：新增 `definitions.volumeMount`，实现 map/string 归一化、`name` 小写规范化、字段约束、递归只读与传播模式校验、大小写敏感值校验，并按 API 顺序渲染；对应 `Decision: 统一归一化后按 API 顺序渲染`、`Decision: 字符串简写由 definitions.volumeMount 解析`、`Decision: 复用 base 校验与渲染能力`、`Decision: 大小写处理`。
- [x] T3 `templates/api-resources/Definitions/_Container.tpl`：仅更新 `volumeMounts` 契约条目、string 简写边界行与字段注释，并为对应 `definitions.container.array` 调用增加 `allowString true`；对应 `Decision: 容器数组启用 string 元素`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效与混合顺序：渲染 `definitions.volumeMount` 的 `name` + `mountPath` map、两段字符串、大写 `name` 的 map 与 string，以及 `definitions.container` 的 map/string 混合 `volumeMounts`；执行 `/opt/homebrew/bin/helm template`，预期字段集合、字段顺序、元素顺序与 `name` 小写输出符合规格。
- [x] V2 `/tmp/sd-kube-chart/` 完整有效：渲染 `name`、`mountPath` 与全部可选字段（`subPath`/`subPathExpr` 分场景）、格式正则大小写不敏感、逗号与空白混合分隔、`readOnly` 省略与显式 `false`、`recursiveReadOnly` 三种枚举、`mountPropagation` 三种枚举及合法跨字段组合；执行 `/opt/homebrew/bin/helm template`，预期全部输出符合规格。
- [x] V3 `/tmp/sd-kube-chart/` 字段约束失败：渲染必填缺失、`name` 规范化后非法、`mountPath` 含 `:`、路径互斥、布尔非法、枚举非法、`TRUE`/`enabled` 等大小写变体、`recursiveReadOnly` 前提不满足及递归只读与传播模式冲突；执行 `/opt/homebrew/bin/helm template`，预期均中断并给出对应错误。
- [x] V4 `/tmp/sd-kube-chart/` 格式与容器数组失败：渲染字符串格式不匹配、`volumeMounts` 非数组及元素类型非法；执行 `/opt/homebrew/bin/helm template`，预期均中断并给出对应错误。
