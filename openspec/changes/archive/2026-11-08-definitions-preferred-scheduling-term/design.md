# PreferredSchedulingTerm 共享结构设计

## 技术目标

- capability：`definitions.preferredSchedulingTerm`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl` 中 `define "definitions.preferredSchedulingTerm"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`渲染 PreferredSchedulingTerm 字段片段`
- choice：新增 `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`，文件内只定义 `definitions.preferredSchedulingTerm`，文件名与结构名对齐并以 `_` 开头。
- rationale：`PreferredSchedulingTerm` 是 Kubernetes 官方结构，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_Affinity.tpl`、`_NodeAffinity.tpl`、`_LabelSelector.tpl` 等均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名，新增文件与之保持一致。

### Decision: weight 取值、整数归一化与范围校验

- requirements：`校验 weight`
- choice：先用 `base.get` 以 `list [上下文, "weight", "", "", true]` 必填取值并保留默认别名识别；原始 YAML 经 `SYS.YAML_QUOTED` 去引号后委托 `base.int` 完成整数形态校验，其结果经 `int64` 归一化，再以 `base.int.range` 的 `list [数值, 1, 100]` 校验闭区间；最后以 `base.field` 搭配 `base.int` 输出。
- rationale：必填判定与 `weightAlias` 识别由 `base.get` 承担，调用方不重复 `hasKey` 与别名分支。整数形态校验复用 `base.int` 的 string 分支（内部使用 `TYPES.INT`），调用方不再自行 `mustRegexMatch` 与自定义 `fail`，避免同一校验出现两份实现。`int64` 仅用于把 `base.int` 返回的十进制字符串转为数值以满足 `base.int.range` 的数值入参。范围校验使用既有 `base.int.range`，避免自建比较分支。

### Decision: preference 取值、解析错误保护与空值跳过

- requirements：`渲染 PreferredSchedulingTerm 字段片段`、`委托 preference 到 NodeSelectorTerm`
- choice：`base.get` 以 `list [上下文, "preference"]` 取原始 YAML；空输出直接跳过该字段；非空时 `fromYaml` 恢复并由 `base.isFromYamlError` 判定，判定为错误形态时 `fail`（字段不是 map）；恢复后仍为空的 map 直接跳过，不输出 `preference: {}`。
- rationale：`preference` 非必填，缺失、`null` 与空 map 必须统一按“不输出”处理，而 `base.get` 对空 map 会返回可解析的 YAML 文本，因此必须解析后按恢复值判空，不能对返回字符串做空值比较。`fromYaml` 成功即保证 map，调用方不再重复 `kindIs "map"`。

### Decision: preference 整体委托 nodeSelectorTerm

- requirements：`委托 preference 到 NodeSelectorTerm`
- choice：把恢复后的 `preference` map 直接作为上下文 `include "definitions.nodeSelectorTerm"`，返回值经 `fromYaml` 与 `base.isFromYamlError` 排除解析错误，非空时以 `base.field` 搭配 `base.map` 输出 `preference`。
- rationale：spec 锁定 `preference` 原样透传且本层不解析其内部结构，因此整 map 作为上下文传递，`matchExpressions`、`matchFields` 及其简写解析归依赖层。`base.map` 承担最终 map 类型门禁；返回值解析失败是本层必须暴露的边界，错误消息保留 `[definitions.preferredSchedulingTerm]` 前缀与字段路径。

### Decision: 返回值形态

- requirements：`渲染 PreferredSchedulingTerm 字段片段`
- choice：模板输出由 `weight` 与可选 `preference` 组成的 YAML 字段片段，由调用方 `fromYaml` 回收为 map；字段顺序固定为 `weight`、`preference`。
- rationale：既有调用方 `definitions.nodeAffinity` 已按 `include ... | fromYaml` 消费本能力并把结果作为 `preferredDuringSchedulingIgnoredDuringExecution` 的一项，字段片段形态与其契约一致。

## 依赖契约

### Dependency: `definitions.nodeSelectorTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，即 `preference` 原值，可含 `matchExpressions`、`matchFields`。
- output：可 `fromYaml` 解析为单个 `NodeSelectorTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：`preference` 取值、类型判定、空值跳过与委托调用由本层负责；`NodeSelectorTerm` 内部结构渲染、简写解析与字段校验由依赖层负责。本 change 只引用该模板，不创建实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两种调用形式：① `list [上下文, "weight", "", "", true]`，必填并保持别名默认开启以识别 `weightAlias`；② `list [上下文, "preference"]`，非必填并保持别名默认开启以识别 `preferenceAlias`。
- output：可 `fromYaml` 解析的 YAML 字符串；路径缺失、为 `null` 或为空字符串时为空输出；必填路径为空时中断。
- ownership：数据源优先级、别名识别、必填校验与序列化由依赖层负责；取值形式选择、空输出判定、类型门禁与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `SYS.YAML_QUOTED`。
- ownership：正则常量集中定义由依赖层负责；常量键选择与去引号决策由本层负责。

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
- input：`list [键名, 值, 渲染模板]`，`weight` 使用 `base.int`，`preference` 使用 `base.map`。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化、枚举校验与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`weight` 去引号后的原始文本 string。
- output：合法时原样返回十进制数字字符串；非整数形态时中断渲染。
- ownership：整数形态校验与十进制格式化由依赖层负责；去引号、`int64` 归一化与范围校验由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`definitions.nodeSelectorTerm` 恢复后的 map。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责；字段生效条件与输出键名由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于 `preference` 恢复结果与子模板返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`

- access：`write`
- operations：`add define "definitions.preferredSchedulingTerm"`、`add 紧邻 define 之前的中文整体契约注释`、`add 字段级中文注释`
- writable-scopes：`define "definitions.preferredSchedulingTerm"` 块及其紧邻契约注释

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`read`
- operations：`consume definitions.nodeAffinity 对 definitions.preferredSchedulingTerm 的调用契约：入参为 dict，含 weight 标量与 preference map，返回值为可 fromYaml 解析的单项 map 文本`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、必填语义、别名开关与空输出边界`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume SYS.YAML_QUOTED 常量的运行时表达式`

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume base.int.range 的入参形态与越界失败行为`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式、渲染模板路由与空值输出行为`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.int 与 base.map 的类型门禁与序列化行为`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlError 的返回形态`

## 验证设计

- 依赖边界：`definitions.nodeSelectorTerm` 当前不可用，全部验证在 `/tmp/` 最小 application Chart 中以同名 fixture 提供，fixture 原样回显入参。fixture 只证明本模板的取值、校验、空值跳过、委托与输出行为，不构成真实依赖集成通过的证据。
- 最小有效输入：只提供 `weight: 1`，验证输出只含 `weight: 1`，不输出 `preference`。
- 较完整有效输入：提供 `weight: 100` 与非空 `preference`（含 `matchExpressions`、`matchFields`），验证输出顺序为 `weight` 在前、fixture 收到完整 `preference` map；另验证 `weightAlias` 覆盖 `weight`、空 `preferenceAlias` 回退 `preference`。
- 空值与短路输入：`preference` 为缺失、`null`、空 map，以及 fixture 返回空 map 四种输入，验证输出只含 `weight` 且不出现 `preference: {}`。
- 关键失败输入：`weight` 缺失、`null`、空字符串、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`，`preference` 为字符串或 list，fixture 返回非 YAML 文本，分别验证渲染中断且错误信息包含 `[definitions.preferredSchedulingTerm]` 或对应依赖模板前缀与字段路径。
- 静态检查：新增文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
