# definitions.podReadinessGate 模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PodReadinessGate.tpl`：新增命名模板 `definitions.podReadinessGate`，按 `conditionType` 渲染单个 `PodReadinessGate` 条目并在空值时不输出；对应 `Pod readinessGate 条目渲染`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：直接调用 `definitions.podReadinessGate` 并传入非空 `conditionType`（含首尾空白、YAML 引号包裹的 string 与 `conditionTypeAlias` 生效路径），预期输出唯一 `conditionType` 字段且值为带引号标量。
- [x] V2 `/tmp/` 最小 application Chart：`conditionType` 缺失、为 `null`、为空字符串，预期模板无输出。
- [x] V3 `/tmp/` 最小 application Chart：`conditionType` 传入布尔与数值，预期 `helm template` 中断且消息带 `[definitions.podReadinessGate]` 前缀。
