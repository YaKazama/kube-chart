# definitions.toleration 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Toleration.tpl`：新增 `definitions.toleration`，先归一 `effect`、`key`、`operator`、`value` 并完成三条互斥校验，再按官方字段顺序渲染五个字段，字符串与枚举字段以引号标量输出，`tolerationSeconds` 交由 `base.int` 渲染；对应 `Toleration 字段片段渲染` 与 `key、operator 与 value 互斥校验`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（加载真实 library Chart）：渲染五字段齐全的输入，断言输出顺序为 `effect`、`key`、`operator`、`tolerationSeconds`、`value`，四个字符串字段为 string、`tolerationSeconds` 为整数；对应 `Toleration 字段片段渲染`。
- [x] V2 同一 Chart：分别渲染仅提供 `key`、全部缺省、`effect`/`key`/`operator`/`value` 为空字符串或纯空白、`operator: Exists` 无 `value`、`operator: Gt` 带 `value`、`tolerationSeconds` 为 `0` 与负数的输入，断言只输出已提供字段、空值不产生键、`0` 与负数原样输出；对应 `Toleration 字段片段渲染` 与 `key、operator 与 value 互斥校验`。
- [x] V3 同一 Chart：渲染 `key` 为空且 `operator` 为 `Equal`、`key` 为空且省略 `operator`、`operator: Exists` 带非空 `value`、`operator: Gt` 无 `value` 的场景，断言渲染中断；对应 `key、operator 与 value 互斥校验`。
- [x] V4 同一 Chart：渲染 `operator` 为 `exists`、`effect` 为 `Noschedule`、字符串字段为 map、`tolerationSeconds` 为字符串与布尔的场景，断言渲染中断；对应 `Toleration 字段片段渲染` 的失败边界。
- [x] V5 同一 Chart：以真实 `core.podSpec` 的 `tolerations` 入口渲染两条容忍规则，断言父模板回收正常且每条规则字段顺序正确；对应 `Toleration 字段片段渲染`。
