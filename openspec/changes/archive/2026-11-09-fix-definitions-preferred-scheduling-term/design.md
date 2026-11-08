# PreferredSchedulingTerm preference 必填设计

## 技术目标

- capability：`definitions.preferredSchedulingTerm`、`definitions.nodeAffinity`
- artifact-type：Kubernetes 共享结构命名模板行为修正
- target：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl` 中的 `define "definitions.preferredSchedulingTerm"`；`templates/api-resources/Definitions/_NodeAffinity.tpl` 中的 `define "definitions.nodeAffinity"` 的 preferredDuringSchedulingIgnoredDuringExecution 处理段

## 设计决策

### Decision: preference 必填取值与 map 门禁

- requirements：`委托 preference 到 NodeSelectorTerm`
- choice：`base.get` 由 `list [上下文, "preference"]` 改为 `list [上下文, "preference", "", "", true]`，必填校验委托既有必填取值能力完成；`fromYaml` 后用 `base.isFromYamlError` 排除解析错误，再用 `kindIs "map"` 拒绝非 map 取值。
- rationale：必填判定、`preferenceAlias` 识别与失败消息统一由 `base.get` 承担，与同模板 `weight` 的必填取值方式完全一致，不重复编写 `hasKey`、`trim` 判空与别名分支，也不在调用层复制一份必填失败消息。`base.get` 的必填校验对 map 使用非空计数，因此 `null`、空字符串与空 map 均由依赖层中断，本层只需处理“不是 map”与“解析失败”两种剩余边界。`fromYaml` 成功只保证不是解析错误，标量取值仍会恢复为 string 或 list，故保留 `kindIs "map"` 作为多类型输入的分支判定。

### Decision: 子模板返回空内容改为中断

- requirements：`委托 preference 到 NodeSelectorTerm`
- choice：删除现有 `{{- if $_preferenceRendered }}` 的“空内容则跳过”分支，改为在 `base.isFromYamlError` 之后直接以 `base.field` 搭配 `base.map` 输出；`base.field` 遇空渲染结果本就不输出，因此在输出前显式判定空内容并 `fail`。
- rationale：`preference` 已成为必填字段，其渲染结果为空意味着下游无法产出有效 `NodeSelectorTerm`，继续静默跳过会输出缺少 `preference` 的非法 `PreferredSchedulingTerm`。失败消息沿用 `[definitions.preferredSchedulingTerm] preference:` 形式，与既有消息风格及消息归属要求一致。

### Decision: 保留 weight 与字段顺序不动

- requirements：`校验 weight`、`渲染 PreferredSchedulingTerm 字段片段`
- choice：`weight` 的取值、`base.int` 整数形态校验、`base.int.range` 范围校验与 `base.field` 输出完全保留；字段输出顺序仍为 `weight` 在前、`preference` 在后。
- rationale：本次只改变 `preference` 的必填性，任何对 `weight` 或顺序的改动都会使既有归档规格失效并超出 draft 意图。

### Decision: nodeAffinity preferred 段新增空匹配条件中断

- requirements：`preferredDuringSchedulingIgnoredDuringExecution 委托`
- choice：在 preferred 段的每个元素处理中，`matchExpressions` 与 `matchFields` 归一化完成后判断 `$preference` 是否为空；为空时 `fail`，消息为 `[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[<下标>].preference: required field is missing or empty`。
- rationale：`definitions.preferredSchedulingTerm` 的 `preference` 已必填，若本层继续向它传递空 map，失败会发生在子模板且消息指向子模板字段路径，调用方难以定位到 `nodeAffinity` 的哪个元素。在本层前置中断可使错误信息携带元素下标，符合 `definitions.nodeAffinity` 既有的“字段路径 + 元素下标”消息风格。判断位置放在两个 `matchList` 调用之后，使“`matchExpressions` 非 array”等既有失败仍优先触发，不改变原有失败顺序。

### Decision: nodeAffinity 其余分支不动

- requirements：`preferredDuringSchedulingIgnoredDuringExecution 委托`
- choice：长键识别与关闭别名、元素 `kindIs "map"` 门禁、`weight` 存在性与标量校验、required 分支的 `nodeSelectorTerms` 包裹与 `definitions.nodeSelector` 委托、输出顺序与既有失败消息全部保留。
- rationale：draft 的「非目标」与「约束」明确只处理 `preference` 必填性；required 分支与 `preference` 无关，任何改动都会扩张影响面。

## 依赖契约

### Dependency: `definitions.nodeSelectorTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeSelectorTerm.tpl`
- operation：`consume`
- input：`dict`，即 `preference` 原值 map，可含 `matchExpressions`、`matchFields` 及其同级别名。
- output：可 `fromYaml` 解析为 `NodeSelectorTerm` map 的 YAML 字符串；无法解析时本层中断；返回空内容时本层中断。
- ownership：`preference` 取值、必填与 map 判定、空内容判定、委托调用与错误保护由本层负责；`NodeSelectorTerm` 内部结构渲染与字段校验由依赖层负责。

### Dependency: `definitions.nodeSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，含 `nodeSelectorTerms` 数组。
- output：可 `fromYaml` 解析为 `NodeSelector` map 的 YAML 字符串。
- ownership：`definitions.nodeAffinity` 只负责包裹与委托；本 change 不实现该模板，验证时使用同名 fixture。

### Dependency: `definitions.preferredSchedulingTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`
- operation：`consume`
- input：`dict`，恒含 `weight` 与非空 `preference`。
- output：可 `fromYaml` 解析为单项 map 的 YAML 字符串。
- ownership：`definitions.nodeAffinity` 只负责构造非空 `preference` 上下文、必填前置判定与错误保护。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "weight", "", "", true]`（保持不变）、`list [上下文, "preference", "", "", true]`（由非必填改为必填）、`list [上下文, "preferredDuringSchedulingIgnoredDuringExecution", "", "", false, false]`（保持不变）、`list [元素, "matchExpressions" 或 "matchFields"]`（由 `definitions.nodeAffinity.matchList` 调用，保持不变）。
- output：可 `fromYaml` / `fromYamlArray` 解析的 YAML 字符串；必填路径缺失、为 `null`、为空字符串或为空 map 时中断。
- ownership：数据源优先级、别名识别、必填校验与序列化由依赖层负责；取值形式选择、解析错误保护、类型门禁与本模板自有失败消息由本层负责。`preference` 与 `weight` 的必填失败消息由依赖层产出，本层不重复实现必填判定。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：可由 `fromYaml` 解析的常量 Map，本模板读取 `SYS.YAML_QUOTED`。
- ownership：常量定义由依赖层负责；常量键选择与调用时机由本层负责。

### Dependency: `base.int`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`weight` 去引号后的原始文本 string。
- output：合法时返回十进制数字字符串；非整数形态时中断渲染。
- ownership：整数形态校验与格式化由依赖层负责；去引号与 `int64` 归一化由本层负责。

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
- input：`list ["weight", 值, "base.int"]` 与 `list ["preference", 恢复后的 map, "base.map"]`。
- output：`key:` 加换行缩进的字段片段；渲染结果为空时不输出。
- ownership：序列化与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`definitions.nodeSelectorTerm` 的恢复结果。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于 `preference` 恢复结果与子模板返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值，用于 preferred 段与 `definitions.nodeAffinity.matchList` 的数组恢复。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `definitions.nodeAffinity.matchList`

- availability：`existing`
- source：`templates/api-resources/Definitions/_NodeAffinity.tpl`
- operation：`consume`
- input：`list [元素 map, 子结构名, 字段名, 下标]`。
- output：可 `fromYamlArray` 解析的数组文本，或空字符串。
- ownership：本 change 不改变其契约，仅在调用后追加 `$preference` 空判定。

## 代码边界

### `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`

- access：`write`
- operations：`update preference 取值与输出分支`：`base.get` 改为必填、删除“空内容跳过”分支、空内容时 `fail`；更新整体契约注释与 `preference` 字段注释中“可选”相关表述
- writable-scopes：`preference（NodeSelectorTerm, 可选）` 注释至 `{{- end }}` 之间的 `preference` 处理块，以及该 `define` 之外紧邻的整体契约注释中涉及 `preference` 可选性与“只输出 weight”的句子

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`write`
- operations：`update preferred 段`：在构造 `$preference` 后新增空 map 中断判定；更新 preferred 段的字段注释与整体契约注释中“空匹配条件仍委托”的表述
- writable-scopes：`define "definitions.nodeAffinity"` 块内 preferred 段的 `matchExpressions` / `matchFields` 归一化之后至 `$terms = mustAppend` 之前的判定区段，以及紧邻该段的注释

### `templates/api-resources/Definitions/_NodeSelectorTerm.tpl`

- access：`read`
- operations：`consume definitions.nodeSelectorTerm 的入参边界与返回值形态`

### `templates/base/_get.tpl`、`_env.tpl`、`_types.tpl`、`_validate.tpl`、`_field.tpl`、`_convert.tpl`

- access：`read`
- operations：`consume 上述依赖契约记录的调用形式与返回边界`

## 验证设计

- 依赖边界：`definitions.nodeSelector` 当前不可用，验证在 `/tmp/` 最小 application Chart 中提供同名 fixture，原样回显入参；`definitions.nodeSelectorTerm`、`definitions.preferredSchedulingTerm` 使用工作区真实实现。fixture 只证明本层调用与分支行为，不构成真实依赖集成通过的证据。
- `definitions.preferredSchedulingTerm` 合法路径：`weight: 1` + `preference` 含 `matchExpressions` 与 `matchFields`，验证输出顺序为 `weight` 在前、`preference` 在后；另验证 `weightAlias` 覆盖 `weight`、空 `preferenceAlias` 回退 `preference`。
- `definitions.preferredSchedulingTerm` 必填失败：`preference` 分别为缺失、`null`、空 map、字符串、list，逐一验证中断并断言错误信息含 `[definitions.preferredSchedulingTerm]` 与 `preference`；fixture 返回空内容与非法 YAML 两种边界。
- `definitions.preferredSchedulingTerm` 回归：`weight` 缺失、`null`、空字符串、`abc`、`true`、map、list、`1.5`、`0`、`-1`、`101`，验证失败边界与消息与改造前一致。
- `definitions.nodeAffinity` 新增中断：preferred 元素只含 `weight`、或 `matchExpressions` 与 `matchFields` 均为空 array，验证中断且错误信息含 `preferredDuringSchedulingIgnoredDuringExecution[<下标>]`。
- `definitions.nodeAffinity` 回归：仅 `matchFields` 非空、仅 `matchExpressions` 非空、两者都非空、多项顺序、`weight` 为 `101` 时仍委托、子项别名优先级、required 分支包裹 `nodeSelectorTerms`、长键非 array 中断、元素非 map 中断。
- 静态检查：两个写入文件无冲突标记、无行尾空白、`define` 与 `end` 配平、契约注释位于 `define` 之前、字段注释紧邻对应处理闭环、文件末尾单换行。
