# definitions.topologySpreadConstraint 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_TopologySpreadConstraint.tpl`：新增 `definitions.topologySpreadConstraint`，按官方字段顺序逐字段完成取值、校验与输出闭环，其中 `labelSelector` 委托 `definitions.labelSelector` 并在回收后以 `base.map` 输出、`matchLabelKeys` 在同一闭环内完成依赖 `labelSelector` 的校验、`maxSkew` 与 `minDomains` 以 `base.int` 与 `base.int.range` 完成整数与下限校验；对应 `TopologySpreadConstraint 字段片段渲染`、`maxSkew 与 minDomains 数值边界` 与 `matchLabelKeys 与 labelSelector 的依赖关系`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（加载真实 library Chart）：渲染八字段齐全的输入，断言输出顺序为 `labelSelector`、`matchLabelKeys`、`maxSkew`、`minDomains`、`nodeAffinityPolicy`、`nodeTaintsPolicy`、`topologyKey`、`whenUnsatisfiable`，且 `labelSelector` 为对象、`matchLabelKeys` 元素为字符串、两个数值字段为整数；对应 `TopologySpreadConstraint 字段片段渲染`。
- [x] V2 同一 Chart：渲染只提供三个必填字段的输入，断言输出只含 `maxSkew`、`topologyKey`、`whenUnsatisfiable` 且顺序正确；对应 `TopologySpreadConstraint 字段片段渲染`。
- [x] V3 同一 Chart：渲染 `DoNotSchedule`、`ScheduleAnyway`、`Honor`、`Ignore` 与 `nodeAffinityPolicy` 为空字符串的输入，断言枚举取值正常输出、空值不产生键；渲染 `donotschedule`、`honor`、`Noschedule` 断言中断并给出合法范围；对应 `TopologySpreadConstraint 字段片段渲染`。
- [x] V4 同一 Chart：渲染 `maxSkew` 为 `1` 与 `0`、`minDomains` 为 `1`、`0`、`-1` 与缺省的输入，断言 `1` 正常输出、`0` 与负数中断、缺省不产生键；对应 `maxSkew 与 minDomains 数值边界`。
- [x] V5 同一 Chart：渲染 `labelSelector` 与 `matchLabelKeys` 同时提供、仅 `matchLabelKeys`、`matchLabelKeys` 含空项、含重复项、含数值元素与为字符串的输入，断言依赖校验、剔空、去重与类型中断符合预期；对应 `matchLabelKeys 与 labelSelector 的依赖关系`。
- [x] V6 同一 Chart：渲染 `topologyKey` 为 `topology.kubernetes.io/zone`、`a/b/c`、`-zone` 与缺失的输入，断言首个通过、其余中断且 `a/b/c` 的失败消息携带 `definitions.topologySpreadConstraint` 与 `topologyKey`；对应 `TopologySpreadConstraint 字段片段渲染`。
- [x] V7 同一 Chart：以真实 `core.podSpec` 的 `topologySpreadConstraints` 入口渲染两条约束，断言父模板回收正常且每条字段顺序正确；对应 `TopologySpreadConstraint 字段片段渲染`。
