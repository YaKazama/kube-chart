# Affinity 共享结构设计

## 技术目标

- capability：`definitions.affinity`
- artifact-type：Kubernetes 共享结构命名模板
- target：`templates/api-resources/Definitions/_Affinity.tpl` 中 `define "definitions.affinity"`

## 设计决策

### Decision: 目标文件与命名模板归属

- requirements：`子结构取值与规范键输出`
- choice：新增 `templates/api-resources/Definitions/_Affinity.tpl`，定义 `definitions.affinity`，文件名与结构名对齐，文件名以 `_` 开头。
- rationale：`Affinity` 属 `api-resources/<APIGroup>` 可跨资源复用的同域共享结构，按分层规则只能落在 `api-resources/Definitions`；该目录现存 `_LabelSelector.tpl`、`_LabelSelectorRequirement.tpl`、`_ObjectMeta.tpl`，文件名与 `definitions.*` 命名空间与既有事实一致。

### Decision: 顶层键集合固定为三类子结构

- requirements：`子结构取值与规范键输出`
- choice：以固定列表 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 驱动取值与委托，不读取 `Affinity` 之外的其他键；取值时把 `base.get` 的别名开关显式传 `false`，不识别 `*Alias` 形式的外层别名。
- rationale：v1.36 `Affinity` 只有这三个字段；`_PodSpec.tpl` 已在本层之前完成合并与 `*Alias` 归一化，重复识别外层别名会与既有契约冲突，因此必须关闭 `base.get` 的默认别名行为而非依赖其默认值。

### Decision: 子结构取值与类型门禁

- requirements：`Affinity 输入失败边界`
- choice：每类子结构用 `base.get` 取值，取值为空字符串时直接跳过该子结构；非空时经 `fromYaml` 恢复后用 `base.isFromYamlError` 判定，判定为解析错误时 `fail` 并输出 `[definitions.affinity] <子结构>: must be map type`。
- rationale：`base.get` 返回 YAML 字符串，标量或顶层序列经 `fromYaml` 均产生错误形态，而 `fromYaml` 成功即已保证结果是 map，因此不需要追加 `kindIs` 类型判断（按核心能力规则属重复检查）。空字符串必须先跳过，否则会被 `fromYaml` 恢复为空 map 而误进入委托流程。该写法与 `_PodSpec.tpl` 处理 `affinity.<key>` 的既有失败边界一致。

### Decision: 短键与长键按 array 取值并退化

- requirements：`规范长键输出与短键归一化`
- choice：在已恢复的子结构 map 上，用 `base.get` 以短键叶子名取值（`preferred`、`required`），再以长键叶子名取值（`preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution`），两次返回值均交给 `fromYamlArray` 恢复为 list；用 `base.isFromYamlArrayError` 判定非 array 输入，判定为错误形态时 `fail` 并输出 `[definitions.affinity] <子结构>.<字段名>: must be array type`；取值结果用 `default $长期值 $短期值` 实现“短键非空时取短键、为空时退化长键”。不对短键与长键做非空互斥判定。
- rationale：draft 锁定两侧类型均为 array，且确认短键是长键的显式别名、自身仍继承自身叶子的 `*Alias`；因为 `base.get` 的别名识别基于叶子名，以短键叶子名取值即自然得到“短键同级别名 > 短键”两档，以长键叶子名取值得到“长键同级别名 > 长键”两档，再用 `default` 拼接，恰好形成“短键别名 > 短键 > 长键别名 > 长键”四档优先级，与 `base.get` 的别名优先级约束一致，不需要额外映射或互斥校验。`fromYamlArray` 是 array 目标的对应恢复函数，`base.isFromYamlArrayError` 是其唯一错误判定 helper；`default` 的“首项非空即返回”语义与“非空短键优先、空短键退化长键”完全同构，避免引入额外分支和深拷贝。`nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` 在本层只是下层数据抽象后的统一形态，本层按 array 处理即可，与 v1.36 原生 `NodeSelector` 对象的差异由依赖层负责。

### Decision: 只输出两个规范长键并丢弃其余字段

- requirements：`规范长键输出与短键归一化`
- choice：新建 `$normalized` 空 dict，只把非空的 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 两个规范长键写入；不复制、不遍历、不传递子结构的其他字段，也不使用 `unset` 或 `omit`。
- rationale：draft 确认其余字段丢弃，且“只要不构建就不传递”是丢弃的最小表达；不复制入参 map 因此不需要 `mustDeepCopy`，同时自然满足状态隔离要求。两个规范键都为空时不进入委托。

### Decision: 子模板委托与输出形态

- requirements：`子结构取值与规范键输出`
- choice：在同一个子结构循环内完成“取值 → 归一化 → 委托 → 输出”闭环：两个规范键至少一个非空时 `include` 对应子模板，返回值经 `fromYaml` 恢复并以 `base.isFromYamlError` 排除解析错误后，非空时直接以 `base.field` 搭配 `base.map` 按规范键输出；三类子结构均无输出时不产生任何内容。
- rationale：spec 锁定输出为可 `fromYaml` 解析的单个 map YAML 且无内容时输出空结果；`base.field` + `base.map` 是本项目渲染 map 字段片段的既定组合，`base.map` 承担最终类型门禁，调用方不重复 `kindIs`。输出顺序由固定子结构列表保证，不需要 `$result` 之类的跨循环暂存容器，单字段闭环也符合字段处理顺序规则。实测该组合在只提供部分子结构、子结构为空、全部缺失三种输入下均得到符合 spec 的结果。

### Decision: 子模板返回值的错误边界

- requirements：`Affinity 输入失败边界`
- choice：子模板返回值 `fromYaml` 后若为解析错误形态，`fail` 并输出 `[definitions.affinity] <子结构>: definitions.<子模板> returned invalid YAML`；不做任何内部字段与结构校验。
- rationale：spec 明确本层不校验子模板返回值内部结构，但委托结果必须可嵌入 output；解析失败属于本层必须暴露的边界。

## 依赖契约

### Dependency: `definitions.nodeAffinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只含 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 的 map，合法时每个键必为 array；不包含子结构中的其他原始字段。
- output：可 `fromYaml` 解析的 YAML 字符串，内容为 `NodeAffinity` 结构。
- ownership：短键归一化、空值退化与委托调用由本层负责；`PreferredSchedulingTerm`、`NodeSelector` 等内部结构由依赖层负责。本 change 不实现。

### Dependency: `definitions.podAffinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只含 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 的 map，合法时每个键必为 array；不包含子结构中的其他原始字段。
- output：可 `fromYaml` 解析的 YAML 字符串，内容为 `PodAffinity` 结构。
- ownership：短键归一化、空值退化与委托调用由本层负责；`WeightedPodAffinityTerm`、`PodAffinityTerm` 等内部结构由依赖层负责。本 change 不实现。

### Dependency: `definitions.podAntiAffinity`

- availability：`unavailable`
- source：无
- operation：`consume`
- input：只含 `preferredDuringSchedulingIgnoredDuringExecution`、`requiredDuringSchedulingIgnoredDuringExecution` 的 map，合法时每个键必为 array；不包含子结构中的其他原始字段。
- output：可 `fromYaml` 解析的 YAML 字符串，内容为 `PodAntiAffinity` 结构。
- ownership：短键归一化、空值退化与委托调用由本层负责；`WeightedPodAffinityTerm`、`PodAffinityTerm` 等内部结构由依赖层负责。本 change 不实现。

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：两种调用形式：① 读取三类子结构时 `list [上下文, 子结构名, "", "", false, false]`，只读顶层单段路径并关闭别名；② 读取子结构内短键与规范长键时 `list [子结构 map, 字段名]`，保持别名默认开启以识别 `preferredAlias`、`requiredDuringSchedulingIgnoredDuringExecutionAlias` 等同级叶子别名。
- output：可 `fromYaml` 或 `fromYamlArray` 解析的 YAML 字符串；路径全部缺失时为空输出。
- ownership：数据源优先级与序列化由依赖层负责；别名开关取值、返回值类型门禁与失败消息由本层负责。

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 返回值。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；失败消息与中断决策由本层负责。

### Dependency: `base.isFromYamlArrayError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYamlArray` 返回值（slice）。
- output：布尔字符串 `"true"` / `"false"`。
- ownership：错误形态识别由依赖层负责；array 类型门禁的失败消息与中断决策由本层负责。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`，渲染模板为 `base.map`。
- output：`key:` 加换行缩进的字段片段；值为空时不输出。
- ownership：键值对输出格式与枚举校验由依赖层负责；键名、生效判断与类型门禁选择由本层负责。

### Dependency: `base.map`

- availability：`existing`
- source：`templates/base/_types.tpl`
- operation：`consume`
- input：map。
- output：YAML map 文本；非 map 输入中断渲染。
- ownership：最终类型门禁与序列化由依赖层负责。

## 代码边界

### `templates/api-resources/Definitions/_Affinity.tpl`

- access：`write`
- operations：`add` `define "definitions.affinity"` 及其紧邻的中文契约注释，内容包含三类子结构取值、类型门禁、短键归一化、子模板委托与规范键输出。
- writable-scopes：新建文件整体；`define "definitions.affinity"` 块与紧邻其前的契约注释。

### `templates/base/_get.tpl`

- access：`read`
- operations：读取 `base.get` 的入参、数据源优先级与返回值形态契约。

### `templates/base/_convert.tpl`

- access：`read`
- operations：读取 `base.isFromYamlError` 与 `base.isFromYamlArrayError` 的错误形态识别契约。

### `templates/base/_field.tpl`

- access：`read`
- operations：读取 `base.field` 的输出格式与复杂类型换行缩进契约。

### `templates/base/_types.tpl`

- access：`read`
- operations：读取 `base.map` 的类型门禁契约。

### `templates/api-resources/Core/_PodSpec.tpl`

- access：`read`
- operations：读取既有 `include "definitions.affinity"` 的调用上下文与返回值消费方式，确认输出必须为可 `fromYaml` 解析的单个 map。

### `templates/api-resources/Definitions/_LabelSelector.tpl`

- access：`read`
- operations：读取同层共享结构的契约注释、`base.get` 取值与 `base.field` 输出写法。

## 验证设计

- 最小有效输入：`/tmp/` 最小 application Chart（`definitions.nodeAffinity`、`definitions.podAffinity`、`definitions.podAntiAffinity` 为同名 fixture），只提供 `podAffinity.required`，验证输出只含 `podAffinity` 且内部键为 `requiredDuringSchedulingIgnoredDuringExecution`。
- 较完整有效输入：三类子结构同时提供且每类都同时包含短键与规范长键，验证三个规范键齐全、短键不出现、短键值生效。
- 短键优先：同一子结构同时提供 `preferred` 与非空 `preferredDuringSchedulingIgnoredDuringExecution`，验证传给 fixture 的值取 `preferred`。
- 回退：`preferred` 为空集合而长键非空，验证取长键值。
- 双空：`required` 与 `requiredDuringSchedulingIgnoredDuringExecution` 都为空集合，验证该键不出现在传递 map 中。
- 同级别名：`podAffinity` 提供 `preferredAlias`，`nodeAffinity` 提供 `requiredDuringSchedulingIgnoredDuringExecutionAlias`，验证别名取值生效。
- 四档优先级：同一子结构同时提供 `preferredAlias`、`preferred`、`preferredDuringSchedulingIgnoredDuringExecutionAlias`、`preferredDuringSchedulingIgnoredDuringExecution` 四个非空值时，验证取 `preferredAlias`；去掉 `preferredAlias` 后验证取 `preferred`；去掉短键两档后验证取长键别名；只留规范长键时验证取长键。同一组递进关系在 `requiredAlias`、`required`、`requiredDuringSchedulingIgnoredDuringExecutionAlias`、`requiredDuringSchedulingIgnoredDuringExecution` 上重复一次。
- 不互斥：`preferred` 与 `preferredDuringSchedulingIgnoredDuringExecution` 同时非空时，验证渲染不中断且取短键值。
- 其余字段丢弃：子结构额外提供 `mismatchLabelKeys` 等字段，验证 fixture 收到的 map 不含这些字段。
- 未提供的子结构：只提供 `podAntiAffinity`，验证另外两个 fixture 未被调用且输出不含这两个键。
- 空子结构：`podAffinity: {}`，验证输出不含 `podAffinity`。
- 全部缺失：入参为不含三类子结构的空 map，验证输出为空结果而不是 `{}`。
- 关键失败：`podAntiAffinity` 取值为字符串，验证渲染中断且错误信息包含 `[definitions.affinity]` 与 `podAntiAffinity`。
- 关键失败：`podAffinity.preferred` 取值为 map，验证渲染中断且错误信息包含 `[definitions.affinity]` 与 `podAffinity.preferred`。
- 关键失败：`nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution` 取值为字符串，验证渲染中断且错误信息包含 `[definitions.affinity]` 与完整字段路径。
- 关键失败：fixture 子模板返回非 YAML 文本，验证渲染中断且错误信息包含 `[definitions.affinity]` 与字段名。
- 静态检查：目标文件无冲突标记、无行尾空白、`define` 与 `end` 配平、末尾单换行。
- fixture 边界：三个子模板均为 `unavailable`，使用 `/tmp/` 同名最小 fixture，结论只证明 `definitions.affinity` 自身行为，不代表真实依赖集成通过。
