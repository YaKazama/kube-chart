# definitions.podResourceClaim 模板设计

## 技术目标

- capability：`definitions.podResourceClaim`
- artifact-type：Helm 命名模板
- target：`templates/api-resources/Definitions/_PodResourceClaim.tpl`

## 设计决策

### Decision: 只消费父级归一化后的单条目上下文

- requirements：`Pod resourceClaim 条目渲染`、非目标中的数组职责边界
- choice：模板只接收父级传入的单个 resourceClaim map，只处理 `name`、`resourceClaimName`、`resourceClaimTemplateName` 及其同级别名；不解析字符串简写，不处理 `resourceClaims` 数组循环、条目合并与去重。
- rationale：`templates/api-resources/Core/_PodSpec.tpl` 的既有 `resourceClaims` 调用已按单条目 map 传入，并已完成字符串项拆分、渲染结果追加与去重。

### Decision: `name` 委托 `base.get` 必填取值并单独收口仅空白

- requirements：`Pod resourceClaim 条目渲染` 中 `name` 的必填与仅空白边界
- choice：使用 `base.get` 的必填模式读取 `name`；原始输出先以 `fromYaml (printf "v: %s" ...)` 还原真实标量类型，非 string 时以本模板前缀中断；再以 `SYS.YAML_QUOTED` 剥离 YAML 标量引号并 `trim`，结果为空时以本模板前缀中断；`name` 只做类型与必填边界，不做 DNS_LABEL 格式校验。
- rationale：必填取值与缺失、`null`、空字符串的失败消息由 `base.get` 统一产出，避免调用方重复实现判空；`base.get` 不识别仅空白，而规格将仅空白等同未设置，故归一化后再补一次字段级中断。类型判定先于去引号的顺序与 `definitions.localObjectReference`、`definitions.podReadinessGate` 一致。

### Decision: 两个引用字段归一化后按恰一个判定

- requirements：`Pod resourceClaim 条目渲染` 中两个引用字段的互斥与缺失边界
- choice：两个引用字段分别以 `base.get` 非必填取值；原始输出为空时视为未设置，非空时先还原标量类型并在非 string 时中断，再剥离 YAML 标量引号并 `trim`，归一化后为空同样视为未设置；最后以 `mustCompact` 去除空值，长度不等于 1 时以本模板前缀中断。
- rationale：规格要求缺失、仅空白与同时设置都中断且必须恰有一个引用成立，合并为一次长度判定可避免两段同义分支；两个字段互为关联，按 API 顺序集中处理符合字段闭环规则对关联字段的允许。

### Decision: 字段按 API 顺序以带引号标量输出

- requirements：`Pod resourceClaim 条目渲染` 的输出字段与顺序
- choice：先输出 `name`，再输出唯一设置的引用字段；三个字段均通过 `base.field` 以 `quote` 渲染。
- rationale：三个字段都是 Kubernetes 对象名，`on`、`yes` 等合法名称在无引号时会被父级 `fromYaml` 解析为布尔值；同层 `definitions.localObjectReference` 与 `definitions.podReadinessGate` 已有相同约定。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`name` 使用 `list <上下文> "name" "" "" true`；两个引用字段使用 `list <上下文> "<字段名>"`；上下文为父级传入的单个 resourceClaim map。
- output：YAML 字符串；非必填路径缺失或显式 `null` 时为空输出，必填路径缺失或为空时中断。
- ownership：本层只负责字段生效、类型判定与互斥判定；数据源优先级、层级路径、别名识别与必填失败消息由 `base.get` 承担。

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
- input：`list "<字段名>" <归一化 string> "quote"`。
- output：非空时输出 `<字段名>: "<值>"` 形式的单行键值对；空值不输出字段。
- ownership：本层完成取值、类型判定、互斥判定与字段顺序；引号与 YAML 序列化由 `base.field` 承担。

## 代码边界

### `templates/api-resources/Definitions/_PodResourceClaim.tpl`

- access：`write`
- operations：新增命名模板 `definitions.podResourceClaim`。
- writable-scopes：`definitions.podResourceClaim`

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：确认 `resourceClaims` 的既有调用契约（单条目 map 传入、字符串项拆分、渲染结果追加与去重后以 `base.slice` 输出），本 change 不修改该文件。

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 直接调用 `definitions.podResourceClaim`，传入 `name` 与 `resourceClaimName`，预期输出按 API 顺序的两个带引号字段。
- 较完整有效：同一 fixture 覆盖仅设置 `resourceClaimTemplateName`、含首尾空白的取值、YAML 引号包裹的 string 以及 `<字段名>Alias` 生效路径。
- 关键失败：`name` 缺失、为 `null`、空字符串、仅空白；两个引用字段都未设置；两个引用字段都设置；任一字段传入布尔、数值、map 或 list；预期 `helm template` 中断并出现定位到对应字段的消息。
- 依赖边界：三个 `base.*` 依赖均为真实模板，不使用同名 fixture 替代。
