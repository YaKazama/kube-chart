# PodAffinity 与 PodAntiAffinity 二级模板失败消息前缀设计

## 技术目标

- capability：`definitions.podAffinity` 与 `definitions.podAntiAffinity` 两个结构族下 6 个二级命名模板的失败消息前缀
- artifact-type：Helm 命名模板失败消息修正
- target：`templates/api-resources/Definitions/_PodAffinity.tpl` 与 `templates/api-resources/Definitions/_PodAntiAffinity.tpl` 中 6 个二级 `define` 内的全部 `fail` 语句

## 设计决策

### Decision: 逐处替换前缀字面量

- requirements：`二级模板失败消息使用自身模板名`
- choice：在每个 `fail` 语句的现有格式串中，把方括号内的模板名原地替换为该语句所属二级模板的完整名；`printf` 的参数列表、`%s`/`%d` 占位符、字段路径、元素下标参数与错误原因文本全部保持原样。
- rationale：`helm-templates.md` 要求失败消息统一为 `[模板名] 字段路径: 错误原因`，模板名指产生消息的命名模板；项目现有全部 `fail` 语句均使用字面量前缀（如 `[base.get]`、`[definitions.podAffinityTerm]`），原地替换保持同一表达风格，并使模板名可被 grep 直接定位。引入 `$name` 变量会为 3–5 条消息增加一次间接寻址，却不能消除占位符与消息体差异，反而降低审阅时的一致性。

### Decision: 不改变任何判定与输出路径

- requirements：`二级模板失败消息使用自身模板名`
- choice：只修改字符串字面量，`if` 条件、`range`、`include`、`fromYaml`/`fromYamlArray`、`base.get` 入参、`must*` 调用与 `base.field` 输出全部不动；不新增、不删除、不重排语句。
- rationale：draft 已确认「只修改失败消息前缀，不改变任何取值、类型门禁、元素跳过、委托或输出行为」。字面量替换是唯一能同时满足「前缀正确」与「成功输出逐字节一致」的改动形态，也让失败条件与判定顺序在差异对比中保持零变化。

### Decision: 主模板契约注释同步修正

- requirements：`二级模板失败消息使用自身模板名`
- choice：`_PodAntiAffinity.tpl` 主模板契约注释中的「本层失败消息统一使用 `[definitions.podAntiAffinity]` 前缀」改为「本层及其私有辅助模板的失败消息使用各自模板名，委托子模板的失败消息原样传播」；两个文件内其余三处二级模板契约注释与 `_PodAffinity.tpl` 主模板契约注释中不含前缀表述的部分不改。
- rationale：`helm-templates.md` 要求命名模板注释与实现一致；该句在修正后会与实现直接冲突，属本次写入范围内的必要同步。`_PodAffinity.tpl` 主模板注释未描述前缀，无需改动。

### Decision: 一级模板不含可改项

- requirements：`二级模板失败消息使用自身模板名`
- choice：`definitions.podAffinity` 与 `definitions.podAntiAffinity` 两个一级 `define` 块内没有 `fail` 语句，本次不新增降级包装或错误转发逻辑。
- rationale：当前文件中 11 条 `fail` 语句分别落在 `termList`（3）、`weightedTermList`（3）、`weightedTerm`（5）内。一级模板仅通过 `include` 串联，`fail` 会自然向上传播；人为捕获并重写前缀会违反「不加过度防御」与「不改写依赖消息」约束。

### Decision: 失败消息归属按语句所在模板判定

- requirements：`二级模板失败消息使用自身模板名`
- choice：前缀取值只看 `fail` 语句所处的 `define` 块：`termList` 块内 3 条用 `definitions.<族>.termList`，`weightedTermList` 块内 3 条用 `definitions.<族>.weightedTermList`，`weightedTerm` 块内 5 条用 `definitions.<族>.weightedTerm`；`<族>` 为 `podAffinity` 或 `podAntiAffinity`。
- rationale：与 spec 的「使用产生该消息的命名模板名」一一对应；按块归属判定可避免把被委托模板名（`$termTemplate`）误当作消息来源，`$termTemplate` 只出现在「委托模板返回非法 YAML」消息体的参数位置，不作为前缀。

## 依赖契约

### Dependency: `definitions.weightedPodAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`
- operation：`consume`
- input：`dict`，由 `weightedTermList` 归一化后传入，恒含 `weight` 与 `podAffinityTerm`。
- output：可 `fromYaml` 解析的 YAML 字段片段；自身失败消息使用 `[definitions.weightedPodAffinityTerm]` 与 `[base.int.range]`、`[base.get]` 前缀。
- ownership：本 change 不改变该依赖的入参、返回值与失败消息；只在本层保留其原样传播路径。

### Dependency: `definitions.podAffinityTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PodAffinityTerm.tpl`
- operation：`consume`
- input：`termList` 委托时传入的单个元素 map。
- output：可 `fromYaml` 解析的 YAML 字段片段；自身失败消息使用 `[definitions.podAffinityTerm]` 与 `[base.*]` 前缀。
- ownership：本 change 不改变该依赖的入参、返回值与失败消息。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两个二级列表模板的 `list [上下文, 字段名, "", "", false, false]` 与 `weightedTerm` 的两处标量取值。
- output：YAML 字符串；必填或类型失败时以 `[base.get]` 前缀中断。
- ownership：取值、别名与必填语义由依赖层负责；本 change 不改变调用形式与失败消息归属。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`consume`
- input：`""`
- output：常量 Map；本 change 只涉及其中 `TYPES.INT` 的既有使用。
- ownership：常量定义由依赖层负责；本 change 不修改 `_env.tpl`，也不新增常量键。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；本 change 只修改识别为真后 `fail` 消息的前缀。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；本 change 只修改识别为真后 `fail` 消息的前缀。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [字段名, 已渲染元素列表, "base.slice"]`。
- output：`字段名:` 加缩进的 YAML 列表片段；渲染结果为空时不输出。
- ownership：序列化与空值跳过由依赖层负责；本 change 不改变调用点与渲染模板选择。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`base.field` 传入的非空元素列表。
- output：YAML 列表字符串；非 slice 输入时中断。
- ownership：类型门禁与序列化由依赖层负责；本 change 不改变调用点。

## 代码边界

### `templates/api-resources/Definitions/_PodAffinity.tpl`

- access：`write`
- operations：`update define "definitions.podAffinity.termList" 内 3 条 fail 消息前缀`、`update define "definitions.podAffinity.weightedTermList" 内 3 条 fail 消息前缀`、`update define "definitions.podAffinity.weightedTerm" 内 5 条 fail 消息前缀`
- writable-scopes：上述三个 `define` 块内 `fail` 语句的方括号模板名字面量；块内其他语句、一级 `define`、全部契约注释均不可修改

### `templates/api-resources/Definitions/_PodAntiAffinity.tpl`

- access：`write`
- operations：`update define "definitions.podAntiAffinity.termList" 内 3 条 fail 消息前缀`、`update define "definitions.podAntiAffinity.weightedTermList" 内 3 条 fail 消息前缀`、`update define "definitions.podAntiAffinity.weightedTerm" 内 5 条 fail 消息前缀`、`update 主模板契约注释中描述失败消息前缀的句子`
- writable-scopes：上述三个 `define` 块内 `fail` 语句的方括号模板名字面量；`define "definitions.podAntiAffinity"` 之前契约注释中「本层失败消息」所在句子；其余内容不可修改

### `templates/api-resources/Definitions/_WeightedPodAffinityTerm.tpl`

- access：`read`
- operations：`consume 其入参键与失败消息前缀，用于确认依赖层消息不被改写`

### `templates/api-resources/Definitions/_PodAffinityTerm.tpl`

- access：`read`
- operations：`consume 其入参边界与失败消息前缀，用于确认依赖层消息不被改写`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、必填语义与 `[base.get]` 失败前缀`

### `templates/base/_env.tpl`

- access：`read`
- operations：`consume TYPES.INT 的存在性`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlError、base.isFromYamlArrayError 的返回形态`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式与空值输出行为`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.slice 的类型门禁与序列化行为`

## 验证设计

- 依赖边界：`definitions.weightedPodAffinityTerm`、`definitions.podAffinityTerm` 与全部 `base.*` 均为当前工作区真实实现，验证在 `/tmp/` 最小 application Chart 中装载真实模板文件，不使用同名 fixture。
- 最小有效输入：对 `definitions.podAffinity` 与 `definitions.podAntiAffinity` 分别提供单个 `required` 元素 `topologyKey: zone`，断言输出与修正前的固定期望值逐字节一致，并断言 `fromYaml` 可回收。
- 较完整有效输入：按已归档 change 的六字段输入同时提供两个字段，断言字段顺序、条目数、`namespaces` 拆分、`preferred` 元素归一化为两键与加权术语输出均与固定期望值一致；另经 `definitions.affinity` 的短键调用断言 `podAffinity`、`podAntiAffinity` 键输出不变。
- 关键失败输入：对 6 个二级模板逐一触发其全部失败分支（字段非 array、元素非 map、委托模板返回非法 YAML、`weight` 缺失/`null`/空字符串/`"11"`/`1.5`/bool/map/array、`podAffinityTerm` 非 map/为空/缺失），断言错误前缀等于该语句所属二级模板完整名，且字段名、元素下标与原因文本与修正前一致。
- 依赖层边界：`base.get` 必填缺失、`base.int.range` 超范围、`definitions.podAffinityTerm`、`definitions.weightedPodAffinityTerm` 的失败消息前缀保持各自模板名，不被本层改写。
- 静态检查：两个写入文件内不再存在以一级模板名作前缀的 `fail` 消息；`define` 与 `end` 配平、契约注释位置不变、无行尾空白、文件末尾单换行；`git diff` 只包含两个文件的 `fail` 字面量与 `_PodAntiAffinity.tpl` 的注释句子。
