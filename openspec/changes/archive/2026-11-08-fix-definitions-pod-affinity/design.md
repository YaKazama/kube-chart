# PodAffinity weightedPodAffinityTerm 上下文修正设计

## 技术目标

- capability：`definitions.podAffinity`
- artifact-type：命名模板内部上下文构造修正
- target：`templates/api-resources/Definitions/_PodAffinity.tpl` 中 `define "definitions.podAffinity"` 的 `preferredDuringSchedulingIgnoredDuringExecution` 分支

## 设计决策

### Decision: 字段表区分委托形态

- requirements：`委托术语子模板`
- choice：字段表元素增加 `"mode"` 键，`preferredDuringSchedulingIgnoredDuringExecution` 为 `"weighted"`、`requiredDuringSchedulingIgnoredDuringExecution` 为 `"term"`；逐元素先按 `mode` 构造委托上下文，再统一 `include` 表中 `template`。
- rationale：两个字段的取值、解析、元素门禁与输出完全同构，差异只在委托上下文；用 `mode` 表达差异可保持单层循环，写法与 `definitions.nodeAffinity` 的 `mode` 一致，避免为 preferred 再复制一份取值与错误保护代码。

### Decision: weight 取值与整数校验

- requirements：`校验 preferred 元素的 weight`
- choice：仅 `mode` 为 `weighted` 时，以元素为上下文调用 `base.get (list $_term "weight")` 并保持默认别名识别；`trim` 后为空即中断；否则用 `base.env` 的 `TYPES.INT` 直接匹配未剥离引号的原始 YAML 文本，不匹配即中断，通过后以 `int64` 转换取值。错误消息统一为 `[definitions.podAffinity] <字段>[<下标>].weight: ...`。
- rationale：Helm 4.2.2 的 `fromYaml` 经 JSON 解码会把所有整数还原为 `float64`，故不能用 `kindIs "int"` 判定，也不能靠“是否解析为整数”区分整数与浮点；直接复用 `TYPES.INT`（`^[+-]?\d+$`）匹配原始文本可同时满足“只接受 integer”和“带引号数字中断”，因为带引号字符串、布尔、浮点、map 与 list 都不匹配该锚定表达式；保持默认别名识别即满足 `weightAlias` 参与取值，本层不额外编写别名分支；范围校验按规格交给子模板。

### Decision: podAffinityTerm 构造与合并优先级

- requirements：`委托术语子模板`
- choice：对元素执行 `mustDeepCopy`；读取 `podAffinityTerm` 时显式关闭别名并按 `trim` 判空，非空时 `fromYaml` 并用 `base.isFromYamlError` 排除错误、用 `kindIs "map"` 确认 map，任一失败即中断；随后从副本 `unset` `weight`、`weightAlias`、`podAffinityTerm`；最终以已有 `podAffinityTerm`（缺失时为 `dict`）为 `mustMerge` 的目标，把副本并入。
- rationale：`mustDeepCopy` 保证不修改调用方传入的元素 map；`fromYaml` 成功只保证不是解析错误，标量取值仍可能返回 string，故保留 `kindIs "map"` 判定；`mustMerge` 的目标优先，正好表达“以已有 `podAffinityTerm` 为主”的冲突规则；先 `unset` 三个键可保证 `weightAlias` 不进入 `podAffinityTerm`、`podAffinityTerm` 自身不被嵌套复制。

### Decision: podAffinityTerm 必填与非空归一

- requirements：`委托术语子模板`
- choice：`podAffinityTerm` 缺失时以 `dict` 作为合并起点；`podAffinityTerm: {}` 经 `base.get` 得到非空 YAML 文本，解析后为空 map，按 map 继续合并；`podAffinityTerm: null` 解析为空 map，同样按 map 处理；合并完成后 `podAffinityTerm` 为空 map 时 `fail`。
- rationale：三种输入在 Helm 恢复后语义一致，统一按 map 起点处理即可区分“类型非法”与“取值为空”；必填约束在合并完成后统一判定，避免在缺失、空 map、`null` 三处重复写同一校验，且能同时覆盖“元素只含 `weight`”与“元素只含 `weight` 与空 `podAffinityTerm`”两种输入。

### Decision: required 分支与输出不变

- requirements：`委托术语子模板`
- choice：`mode` 为 `term` 时直接把元素原样作为子模板上下文；收集、`fromYaml` 错误保护、`base.field` 搭配 `base.slice` 的输出逻辑保持现状。
- rationale：规格明确 required 分支透传行为不变，本次只替换 preferred 的委托上下文；输出层不感知上下文构造差异，不做多余改动。

## 依赖契约

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：恒含 `weight` 与 `podAffinityTerm` 两个键的 map；`weight` 为 integer，`podAffinityTerm` 为非空 map。
- output：可 `fromYaml` 解析为单个 `WeightedPodAffinityTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：`podAffinityTerm` 内部术语字段的取值、校验、归一化与渲染由依赖层负责；委托上下文构造、`weight` 类型校验与错误保护由本层负责。本 change 只引用该模板，不创建实现。

### Dependency: `definitions.podAffinityTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`requiredDuringSchedulingIgnoredDuringExecution` 的元素 map，原样传入，可包含任意术语字段。
- output：可 `fromYaml` 解析为单个 `PodAffinityTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：元素内部字段的取值、校验、归一化与渲染由依赖层负责；本层只负责透传、错误保护与收集。本 change 只引用该模板，不创建实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, "preferredDuringSchedulingIgnoredDuringExecution" 或 "requiredDuringSchedulingIgnoredDuringExecution", "", "", false, false]`、`list [元素, "weight"]`（默认别名）、`list [元素, "podAffinityTerm", "", "", false, false]`（关闭别名）。
- output：可 `fromYaml`/`fromYamlArray` 解析的 YAML 字符串；路径缺失或空值时为空输出。
- ownership：数据源优先级、别名识别与序列化由依赖层负责；空输出判定、文本匹配、类型门禁与失败消息由本层负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`。
- output：可由 `fromYaml` 解析的常量 Map；本模板只读取 `TYPES.INT`。
- ownership：常量集中定义与结构有效性由依赖层负责；是否匹配、失败消息与中断决策由本层负责。本 change 不修改 `_env.tpl`。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 的返回值，用于字段数组。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值，用于 `podAffinityTerm` 取值与子模板输出。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；中断决策与失败消息由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, 子模板输出 map 列表, "base.slice"]`。
- output：`key:` 加换行缩进的字段片段；空值时不输出。
- ownership：序列化与目标类型门禁由依赖层负责；字段生效条件与输出顺序由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：由 `base.field` 传入的 map 列表。
- output：YAML 列表字符串；非 slice 时中断。
- ownership：列表序列化与类型门禁由依赖层负责；列表内容与顺序由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`write`
- operations：`update define "definitions.podAffinity" 中 $fields 字段表`、`update preferred 分支的委托上下文构造`、`update 整体契约注释中 preferred 字段的行为与边界描述`
- writable-scopes：`$fields` 字段表与整体契约注释中的 preferred 相关描述、`range $_field := $fields` 内逐元素处理段

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`read`
- operations：消费 `definitions.podAffinity` 的既有调用契约；不修改

### `templates/base/_get.tpl`

- access：`read`
- operations：消费 `base.get`

### `templates/base/_env.tpl`

- access：`read`
- operations：消费 `base.env` 中的 `TYPES.INT`

### `templates/base/_convert.tpl`

- access：`read`
- operations：消费 `base.isFromYamlError`、`base.isFromYamlArrayError`

### `templates/base/_field.tpl`

- access：`read`
- operations：消费 `base.field`

### `templates/base/_types.tpl`

- access：`read`
- operations：消费 `base.slice`

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart，两个 unavailable 子模板使用同名回显 fixture；`preferredDuringSchedulingIgnoredDuringExecution` 单元素含 `weight: 11` 与 `topologyKey`，验证 fixture 收到的上下文只有 `weight` 与 `podAffinityTerm` 两键，且 `podAffinityTerm` 内含 `topologyKey`。
- 较完整有效：同一 fixture 下提供 `weightAlias: 22`、`namespaceSelector`、`labelSelector`、`matchLabelKeys`、`namespaces`，验证别名取值、术语字段原样透传、`weightAlias` 不出现在 `podAffinityTerm` 下。
- 合并行为：元素含 `podAffinityTerm` 且同时含同名 `topologyKey`，验证冲突取 `podAffinityTerm` 内的值、层级不增加；再验证 `podAffinityTerm: {}` 与缺失但存在其他术语字段时均能正确合并。
- 空值必填：元素只含 `weight`、以及只含 `weight` 与 `podAffinityTerm: {}`，验证两者均中断并报错。
- 关键失败：`weight` 缺失、`null`、`""`、`"11"`、`1.5`、`true`、`{}`、`[]`，以及非 map 的 `podAffinityTerm`、fixture 返回非法 YAML，逐一验证渲染中断且错误信息含 `[definitions.podAffinity]`、字段名与元素下标。
- 不受影响：`requiredDuringSchedulingIgnoredDuringExecution` 元素仍原样传给 fixture；`weight` 超出 1-100 时正常渲染。
- 依赖边界：两个子模板当前不可用，全部验证以同名 fixture 提供，fixture 原样回显上下文；只证明本模板的取值、上下文构造、合并与失败边界，不构成真实依赖集成通过的证据。
