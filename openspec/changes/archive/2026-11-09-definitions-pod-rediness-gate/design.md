# definitions.podReadinessGate 模板设计

## 技术目标

- capability：`definitions.podReadinessGate`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_PodReadinessGate.tpl`

## 设计决策

### Decision: 只消费父级归一化后的单条目上下文

- requirements：`Pod readinessGate 条目渲染`、非目标中的数组职责边界
- choice：模板只接收父级传入的单个 readinessGate map，只处理 `conditionType` 及其同级别名；不解析字符串简写，不处理 `readinessGates` 数组循环、合并与去重。
- rationale：draft 已确认数组职责归父级；`templates/api-resources/Core/_PodSpec.tpl` 现有调用已按单条目传入，且已完成字符串项补齐与去重。

### Decision: 取值委托 `base.get` 并按真实类型中断

- requirements：`Pod readinessGate 条目渲染`
- choice：使用 `base.get` 读取 `conditionType`；原始输出 `trim` 后为空时直接跳过；非空时先以 `fromYaml (printf "v: %s" ...)` 恢复真实类型，非 string 时用本模板前缀 `fail` 中断；通过后使用 `SYS.YAML_QUOTED` 剥离 YAML 标量引号并 `trim`。
- rationale：`base.get` 是工程规则规定的多层字段统一取值入口；该类型判定与去引号顺序与 `definitions.localObjectReference`、`definitions.labelSelectorRequirement` 的现有实现一致，且能区分布尔、数值与同样文本的 string。

### Decision: 归一化结果非空时由 `base.field` 强制加引号输出

- requirements：`Pod readinessGate 条目渲染`
- choice：归一化后的非空 string 通过 `base.field (list "conditionType" $conditionType "quote")` 输出；归一化后为空时静默跳过该字段。
- rationale：draft 要求值强制加引号，`base.field` 的 `quote` 是既有渲染能力；空值跳过由调用方字段生效条件决定，符合工程规则对 `base.field` 的边界要求。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> "conditionType"`；上下文为父级传入的单个 readinessGate map。
- output：YAML 字符串；路径缺失或显式 `null` 时为空输出。
- ownership：本层只负责字段生效与类型判定；数据源优先级、层级路径和别名识别由 `base.get` 承担。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：常量 Map 的 YAML 字符串；本层读取 `SYS.YAML_QUOTED`。
- ownership：常量表达式由 `base.env` 维护，本层不内联或复制该正则。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list "conditionType" <归一化 string> "quote"`。
- output：非空时输出 `conditionType: "<值>"`；空值不输出字段。
- ownership：本层完成取值、类型校验与字段生效判断；引号与 YAML 序列化由 `base.field` 承担。

## 代码边界

### `templates/api-resources/Definitions/_PodReadinessGate.tpl`

- access：`write`
- operations：新增命名模板 `definitions.podReadinessGate`。
- writable-scopes：`definitions.podReadinessGate`

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：确认 `readinessGates` 的既有调用契约（单条目 map 传入、字符串项补齐、去重后以 `base.slice` 输出），本 change 不修改该文件。

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 直接调用 `definitions.podReadinessGate`，传入非空 `conditionType`，预期输出带引号的 `conditionType` 单字段。
- 较完整有效：同一 fixture 覆盖字符串简写带引号、含首尾空白的取值以及 `conditionTypeAlias` 生效路径。
- 关键失败：`conditionType` 传入布尔或数值，预期渲染中断且消息带 `[definitions.podReadinessGate]` 前缀；空值场景预期无输出。
- 依赖边界：三个 `base.*` 依赖均为真实模板，不使用同名 fixture 替代。
