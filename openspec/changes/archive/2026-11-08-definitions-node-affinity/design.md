# NodeAffinity 共享结构设计

## 技术目标

- capability：`definitions.nodeAffinity`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_NodeAffinity.tpl` 中 `define "definitions.nodeAffinity"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`顶层字段取值与输出顺序`
- choice：新增 `templates/api-resources/Definitions/_NodeAffinity.tpl`，在文件内只定义 `definitions.nodeAffinity`，文件名与结构名对齐并以 `_` 开头。
- rationale：`NodeAffinity` 是 `Affinity` 的嵌套结构，属可跨资源复用的同域共享结构，只能落在 `api-resources/Definitions`；该目录现有 `_Affinity.tpl`、`_LabelSelector.tpl`、`_LabelSelectorRequirement.tpl`、`_ObjectMeta.tpl` 均沿用 `_<结构名>.tpl` 与 `definitions.<能力>` 命名，新增文件与之保持一致。

### Decision: 只读两个规范长键并关闭别名识别

- requirements：`顶层字段取值与输出顺序`
- choice：用 `base.get` 以 `list [上下文, 键名, "", "", false, false]` 读取 `preferredDuringSchedulingIgnoredDuringExecution` 与 `requiredDuringSchedulingIgnoredDuringExecution`，显式把别名开关传 `false`；不读取短键，也不读取其他顶层键。
- rationale：spec 锁定只识别两个规范长键，且短键归一化与外层 `*Alias` 归一化已由父级 `definitions.affinity` 完成；重复识别会与既有契约冲突，因此必须显式关闭而不是依赖默认值。该调用形式与 `_Affinity.tpl` 读取外层键的既有写法一致。

### Decision: 两字段按 array 恢复并按字段闭环

- requirements：`顶层字段取值与输出顺序`、`NodeAffinity 输入失败边界`
- choice：每个字段按“`base.get` 取值 → 空输出直接跳过 → `fromYamlArray` 恢复 → `base.isFromYamlArrayError` 判定 → 非空时进入该字段的归一化与委托 → `base.field` 输出”独立闭环，按 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 顺序排列；两字段都跳过时不产生任何输出。
- rationale：spec 锁定两个字段取值均为 array 且空值不输出；`base.get` 返回 YAML 字符串，`fromYamlArray` 是 array 目标的对应恢复函数，`base.isFromYamlArrayError` 是其唯一错误判定 helper。先判空再解析可避免空输入被恢复为空 list 后误入委托分支，与 `definitions.affinity` 的既有边界一致。

### Decision: preferred 逐项归一化后委托

- requirements：`preferredDuringSchedulingIgnoredDuringExecution 委托`
- choice：对 `preferredDuringSchedulingIgnoredDuringExecution` 的每个元素，先用 `kindIs "map"` 判定元素类型，非 map 直接 `fail`；再以该元素为上下文构造 `dict "weight" $weight "preference" $preference` 并 `include "definitions.preferredSchedulingTerm"`，返回值经 `fromYaml` 与 `base.isFromYamlError` 保护后按原顺序追加到结果 list，最终用 `base.field` 搭配 `base.slice` 输出。
- rationale：spec 锁定每个输入项对应一个输出项且保持顺序，因此逐项委托并顺序累加最直接；`kindIs` 在此处用于判定未经 YAML 恢复的数组元素原始类型，属核心能力规则允许的场景。`base.slice` 承担最终 list 类型门禁，调用方不重复同类检查。

### Decision: weight 只判存在性并按标量传递

- requirements：`preferredDuringSchedulingIgnoredDuringExecution 委托`、`NodeAffinity 输入失败边界`
- choice：以 `base.get` 读取 term 的 `weight`（保持默认别名开关，识别 `weightAlias`），返回值为空输出时 `fail`；再用 `fromYaml` 包裹成 `v: <原值>` 的标量容器还原取值，解析失败或还原结果不是标量时 `fail`；还原后的标量按原样写入传给子模板的 `weight`。
- rationale：`base.get` 已把缺失、`null` 与空字符串统一为空输出，因此“存在且非空”判定只需一次空输出判断，不需要额外的 `hasKey` 分支。`base.get` 只返回 YAML 字符串，直接传入子模板会把数值退化为字符串，因此用项目既有的 `v:` 单键容器还原原始标量类型；容器写法保证整数仍是整数、带引号字符串仍是字符串。范围 1 - 100 与整数类型校验属于依赖层职责，本层不追加任何范围或数值校验。

### Decision: matchExpressions 与 matchFields 归一化后写入目标容器

- requirements：`preferredDuringSchedulingIgnoredDuringExecution 委托`、`requiredDuringSchedulingIgnoredDuringExecution 委托`、`NodeAffinity 输入失败边界`
- choice：对 term 的 `matchExpressions`、`matchFields` 分别用 `base.get` 读取（保持默认别名开关，识别 `*Alias`），空输出时不写入目标 map；非空时用 `fromYamlArray` 恢复并由 `base.isFromYamlArrayError` 判定，判定为错误时 `fail`。`preferred` 分支写入新建的 `$preference`，`required` 分支写入新建的 term map。
- rationale：spec 锁定两个字段按 array 向下传递，别名由 `base.get` 在同级完成归一化后传出的必须是清洗后的数据；数组元素内部结构由依赖层负责，本层只保证容器是 list，不解析元素内的字符串简写与 `NodeSelectorRequirement` 结构。空输出不写入目标 map，因此两者都为空时 `preference` 与 term 仍以空 map 形式传给子模板，与 spec 的“仍委托／仍传递”一致。

### Decision: required 包裹为 nodeSelectorTerms 并整体委托

- requirements：`requiredDuringSchedulingIgnoredDuringExecution 委托`
- choice：按 `preferred` 相同规则逐项校验并构造清洗后的 term map 列表，然后 `include "definitions.nodeSelector" (dict "nodeSelectorTerms" $terms)`，返回值经 `fromYaml` 与 `base.isFromYamlError` 排除解析错误后，非空时用 `base.field` 搭配 `base.map` 以 `requiredDuringSchedulingIgnoredDuringExecution` 键输出。
- rationale：spec 锁定传给 `definitions.nodeSelector` 的 map 只含 `nodeSelectorTerms` 一个键，包裹逻辑必须在本层完成，取值与内部渲染归依赖层。`base.map` 承担最终 map 类型门禁；对空返回值不加输出，避免把无内容结果渲染成 `{}`。

### Decision: 子模板返回值的错误边界

- requirements：`NodeAffinity 输入失败边界`
- choice：`definitions.preferredSchedulingTerm` 单项返回值与 `definitions.nodeSelector` 整体返回值均经 `fromYaml` 恢复到 map，`base.isFromYamlError` 判定为错误形态时 `fail`，消息为 `[definitions.nodeAffinity] <字段路径>: definitions.<子模板> returned invalid YAML`；不校验返回值内部字段与结构。
- rationale：spec 明确本层不校验子模板内部结构，但委托结果必须可嵌入输出；解析失败是本层必须暴露的唯一边界。错误消息保留字段路径，便于在多层委托中定位。

## 依赖契约

### Dependency: `definitions.preferredSchedulingTerm`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，含 `weight`（已还原的标量取值）与 `preference`（map，可含 `matchExpressions`、`matchFields`，两者均为 array）。
- output：可 `fromYaml` 解析为单个 `PreferredSchedulingTerm` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：数组取值、元素类型门禁、`weight` 存在性判定、子项别名归一化、`preference` 组装与委托调用由本层负责；`weight` 的整数类型与 1 - 100 范围校验、`NodeSelectorTerm` 内部结构渲染由依赖层负责。本 change 不实现该模板。

### Dependency: `definitions.nodeSelector`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：`dict`，只含 `nodeSelectorTerms`（array，元素为含 `matchExpressions`、`matchFields` 且已完成别名词清洗的 map）。
- output：可 `fromYaml` 解析为 `NodeSelector` map 的 YAML 字符串；无法解析时由本层中断。
- ownership：term 遍历、元素类型门禁、子项别名归一化与 `nodeSelectorTerms` 包裹由本层负责；`nodeSelectorTerms` 取值与 `NodeSelectorTerm` 内部结构渲染由依赖层负责。本 change 不实现该模板。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两种调用形式：① 读取两个规范长键时 `list [上下文, 键名, "", "", false, false]`，只读单段路径并关闭别名；② 读取 term 的 `weight`、`matchExpressions`、`matchFields` 时 `list [term map, 字段名]`，保持别名默认开启以识别 `weightAlias`、`matchExpressionsAlias`、`matchFieldsAlias`。
- output：可 `fromYaml`、`fromYamlArray` 或 `v:` 容器解析的 YAML 字符串；路径缺失、为 `null` 或为空字符串时为空输出。
- ownership：数据源优先级、别名识别与序列化由依赖层负责；取值形式选择、空输出判定、类型门禁与失败消息由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`，渲染模板分别为 `base.slice` 与 `base.map`。
- output：`key:` 加换行缩进的字段片段；值为空时不输出。
- ownership：序列化、枚举与空值跳过由依赖层负责；字段生效条件、键名与渲染模板选择由本层负责。

### Dependency: `base.slice`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`PreferredSchedulingTerm` 结果 list。
- output：YAML list 字符串；非 list 输入时中断。
- ownership：list 类型门禁与序列化由依赖层负责；结果 list 的构造与顺序由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：`definitions.nodeSelector` 恢复后的 map。
- output：YAML map 字符串；非 map 输入时中断。
- ownership：map 类型门禁与序列化由依赖层负责；字段生效条件与输出键名由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值，用于子模板返回值与 `weight` 标量容器。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；array 类型门禁的失败消息与中断决策由本层负责。

## 代码边界

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`write`
- operations：`add define "definitions.nodeAffinity"`、`add 紧邻 define 之前的中文整体契约注释`
- writable-scopes：`define "definitions.nodeAffinity"` 块及其紧邻契约注释

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`read`
- operations：`consume definitions.affinity 对 nodeAffinity 的委托契约：入参只含两个规范长键且取值已归一化为 array`

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume base.get 的调用形式、别名开关与空输出边界`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume base.field 的调用形式与空值输出行为`

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume base.map 与 base.slice 的类型门禁与序列化行为`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume base.isFromYamlError 与 base.isFromYamlArrayError 的返回形态`

## 验证设计

- 依赖边界：`definitions.preferredSchedulingTerm` 与 `definitions.nodeSelector` 当前不可用，全部验证在 `/tmp/` 最小 application Chart 中以同名 fixture 提供，fixture 原样回显入参。fixture 只证明本模板的取值、归一化、包裹、委托与输出行为，不构成真实依赖集成通过的证据。
- 最小有效输入：只提供一项 `preferredDuringSchedulingIgnoredDuringExecution`（含 `weight` 与 `matchExpressions`），验证输出只含该字段一项，且 fixture 收到 `weight` 与 `preference`。
- 较完整有效输入：两字段同时提供、`preferred` 多项不同 `weight`、`required` 多 term，验证输出顺序、项数与 `nodeSelectorTerms` 包裹形态；另验证 `weightAlias`、`matchExpressionsAlias`、`matchFieldsAlias` 覆盖同名规范键，以及空别名回退规范键。
- 空值与短路输入：两字段均为空 array、只提供 `preferred` 短键、只提供长键 `*Alias` 三种输入，验证输出为空结果。
- 关键失败输入：规范长键为 map、term 为字符串、`weight` 缺失、`weight` 为空字符串、`weight` 为 map、`matchExpressions` 为 map、fixture 返回非 YAML 文本，验证渲染中断且错误信息包含 `[definitions.nodeAffinity]` 与对应字段路径。
- 静态检查：新增文件无冲突标记、无行尾空白、`define` 与 `end` 配平、文件末尾单换行。
