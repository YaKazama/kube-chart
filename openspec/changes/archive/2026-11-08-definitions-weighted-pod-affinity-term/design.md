# WeightedPodAffinityTerm 共享结构设计

## 技术目标

- capability：`definitions.weightedPodAffinityTerm`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl` 中 `define "definitions.weightedPodAffinityTerm"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 WeightedPodAffinityTerm 字段片段`
- choice：新增 `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`，文件内只定义 `definitions.weightedPodAffinityTerm`，文件名与结构名对齐并以 `_` 开头。
- rationale：`WeightedPodAffinityTerm` 是 Kubernetes 官方共享结构，只能落在同域共享结构层 `api-resources/Definitions`；该目录现有 `_PodAffinity.tpl`、`_PreferredSchedulingTerm.tpl` 等均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名。

### Decision: weight 取值、整数归一化与范围校验

- requirements：`校验 weight`
- choice：先用 `base.get` 以 `list [上下文, "weight", "", "", true]` 必填取值并保留默认别名识别；原始 YAML 经 `SYS.YAML_QUOTED` 去引号并 `trim` 后委托 `base.int` 校验整数形态，结果以 `int64` 归一化，再以 `base.int.range` 的 `list [数值, 1, 100]` 校验闭区间；最后以 `base.field` 搭配 `base.int` 输出。
- rationale：必填判定与 `weightAlias` 识别由 `base.get` 承担，整数形态与取值上限复用 `base.int`、`base.int.range`，不复刻同域 `definitions.preferredSchedulingTerm` 已实现的同一套校验分支。父级 `definitions.podAffinity` 已前置校验整数形态，但本模板作为公开命名模板必须独立满足规格，重复入口校验属调用契约而非重复实现。

### Decision: podAffinityTerm 必填取值与 map 归一化

- requirements：`校验 podAffinityTerm`
- choice：以 `base.get` 的 `list [上下文, "podAffinityTerm", "", "", true]` 必填取值，缺失、`null` 与空 map 统一由必填校验中断；返回值经 `fromYaml` 恢复，先用 `base.isFromYamlError` 排除解析错误，再用 `kindIs "map"` 拒绝非 map 取值，最后以恢复后的非空 map 作为委托上下文。
- rationale：`base.get` 的必填判定对 map 使用非空计数，正好覆盖规格要求的“缺失、`null`、空 map”三种输入，无需在调用方重复 `hasKey` 与空 map 比较。`fromYaml` 成功只保证不是解析错误，标量取值仍会恢复为 string 或 list，因此保留 `kindIs "map"` 作为多类型输入的分支判定，避免把非 map 上下文传给子模板。

### Decision: podAffinityTerm 整体委托

- requirements：`委托 podAffinityTerm 到 PodAffinityTerm`
- choice：把恢复后的 `podAffinityTerm` map 直接作为上下文 `include "definitions.podAffinityTerm"`，返回值经 `fromYaml` 与 `base.isFromYamlError` 排除解析错误后，以 `base.field` 搭配 `base.map` 输出 `podAffinityTerm`；只读透传该 map，不使用 `mustDeepCopy`。
- rationale：规格锁定整 map 原样透传且本层不解析内部字段，内部结构渲染归依赖层；`base.map` 承担最终 map 类型门禁与序列化。map 只作为 `include` 的只读上下文，本模板不写入任何键，符合状态隔离规则中“只读透传不复制”的约束。

### Decision: 返回值形态与字段顺序

- requirements：`渲染 WeightedPodAffinityTerm 字段片段`
- choice：模板输出由 `weight` 与 `podAffinityTerm` 组成的 YAML 字段片段，调用方以 `fromYaml` 回收为 map；字段顺序按 K8s API 文档字段表固定为 `podAffinityTerm`、`weight`。
- rationale：调用方 `definitions.podAffinity` 已按 `include ... | fromYaml` 消费本能力并取单项 map；字段顺序遵循用户本轮确认的 K8s 官方文档字段表顺序，YAML 键序不影响语义，也不影响调用方按键取值。

## 依赖契约

### Dependency: `definitions.podAffinityTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，即 `podAffinityTerm` 原值，可含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 等术语字段。
- output：可 `fromYaml` 解析为单个 `PodAffinityTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：`podAffinityTerm` 取值、必填与 map 判定、委托调用与错误保护由本层负责；`PodAffinityTerm` 内部字段的取值、校验、归一化与渲染由依赖层负责。本 change 只引用该模板，不创建实现。

### Dependency: `definitions.podAffinity`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinity.tpl`
- operation：`consume`
- input：`preferredDuringSchedulingIgnoredDuringExecution` 的单个数组元素，已由调用方归一化为 `dict`，恒含 `weight` 与 `podAffinityTerm` 两个键。
- output：无，本模板只消费其调用契约。
- ownership：扁平形态到嵌套形态的归一化、`weightAlias` 剥离与合并优先级由调用方负责；本模板只接收已归一化的嵌套上下文。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两种调用形式：① `list [上下文, "weight", "", "", true]`；② `list [上下文, "podAffinityTerm", "", "", true]`；两者均保持别名默认开启以识别同级 `<键名>Alias`。
- output：可 `fromYaml` 解析的 YAML 字符串；路径缺失、为 `null`、为空字符串或为空 map 时按必填失败中断。
- ownership：数据源优先级、别名识别、必填校验与序列化由依赖层负责；取值形式选择、解析错误保护、类型门禁与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `SYS.YAML_QUOTED`。
- ownership：常量集中定义由依赖层负责；常量键选择与去引号决策由本层负责。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`weight` 去引号后的原始文本 string。
- output：合法时原样返回十进制数字字符串；非整数形态时中断渲染。
- ownership：整数形态校验与十进制格式化由依赖层负责；去引号、`int64` 归一化与范围校验由本层负责。

### Dependency: `base.int.range`

- availability：`existing`
- source：`templates/base/_validate.tpl`
- operation：`consume`
- input：`list [weight 的 int64 取值, 1, 100]`。
- output：校验通过的数值；非数值或越界时中断渲染。
- ownership：闭区间比较由依赖层负责；取值范围来源与调用时机由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`，`weight` 使用 `base.int`，`podAffinityTerm` 使用 `base.map`。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化、枚举校验与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`definitions.podAffinityTerm` 的恢复结果。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责；字段生效条件与输出键名由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于 `podAffinityTerm` 恢复结果与子模板返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`

- access：`write`
- operations：`add define "definitions.weightedPodAffinityTerm"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：`define "definitions.weightedPodAffinityTerm"` 块及其紧邻契约注释

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`read`
- operations：`consume definitions.podAffinity 对 definitions.weightedPodAffinityTerm 的调用契约：入参为 dict，恒含 weight 与 podAffinityTerm，返回值为可 fromYaml 解析的单项 map 文本`

### `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`

- access：`read`
- operations：`consume weight 必填取值、整数归一化、范围校验与 base.field 输出的既有实现形态`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、必填语义、别名开关与空输出边界`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume SYS.YAML_QUOTED 常量的运行时表达式`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.int 与 base.map 的类型门禁与序列化行为`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume base.int.range 的入参形态与越界失败行为`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式、渲染模板路由与空值输出行为`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlError 的返回形态`

## 验证设计

- 依赖边界：`definitions.podAffinityTerm` 当前不可用，全部验证在 `/tmp/` 最小 application Chart 中以同名 fixture 提供，fixture 原样回显入参。fixture 只证明本模板的取值、校验、委托与输出行为，不构成真实依赖集成通过的证据。
- 最小有效输入：提供 `weight: 1` 与只含 `topologyKey` 的 `podAffinityTerm`，验证输出同时含 `weight: 1` 与 `podAffinityTerm`，且 `podAffinityTerm` 在前。
- 较完整有效输入：提供 `weight: 100` 与含 `topologyKey`、`labelSelector`、`namespaceSelector`、`matchLabelKeys`、`namespaces` 的 `podAffinityTerm`，验证 fixture 收到与输入逐键一致的 map；另验证 `weightAlias` 覆盖 `weight`、空 `podAffinityTermAlias` 回退 `podAffinityTerm`。
- 关键失败输入：`weight` 为缺失、`null`、空字符串、`"11"`、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`；`podAffinityTerm` 为缺失、`null`、空 map、字符串、list；fixture 返回非 YAML 文本，逐一验证渲染中断并覆盖 `[base.get]`、`[base.int]`、`[base.int.range]` 与 `[definitions.weightedPodAffinityTerm]` 前缀及字段名。
- 静态检查：新增文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
