# nodeAffinity weight 类型门禁收敛设计

## 技术目标

- capability：`definitions.nodeAffinity`
- artifact-type：Helm 命名模板的局部重构，不新增能力
- target：`templates/api-resources/Definitions/_NodeAffinity.tpl`

## 设计决策

### Decision: 删除父级标量门禁，交由子模板收口

- requirements：`校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`
- choice：删除 `preferredDuringSchedulingIgnoredDuringExecution` 条目中的 `fromYaml (printf "v: %s" ...)` 单值解码、`base.isFromYamlError` 检查与 `kindIs "map"`、`kindIs "slice"` 两个分支，把 `base.get` 的原始文本直接作为 `weight` 值写入待渲染条目。
- rationale：`definitions.preferredSchedulingTerm` 已用 `base.int` 校验整数形态、用 `base.int.range` 校验 1 - 100 闭区间，父级再判定标量形态属重复校验。实测 `kindIs` 两分支只在 `weight` 为 `{}` 或 `[]` 时可达，其余非标量输入会先被 `base.int` 拒绝，因此删除后所有非法输入仍在子模板中断。

### Decision: 保留父级存在性判断

- requirements：`校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`
- choice：保留 `if not $_weightRaw` 判断，缺失、YAML null 与空字符串在 `definitions.nodeAffinity` 层中断，失败消息使用本模板前缀与条目下标。
- rationale：该判断承载「必填」语义而非形态校验，删除后空值会落到子模板的 `base.get` 必填校验，失败消息将失去条目下标，无法区分是哪个 `preferredDuringSchedulingIgnoredDuringExecution` 元素缺项。

### Decision: 接受纯数字字符串失效

- requirements：`校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`
- choice：删除解码后 `weight: "50"` 由可用变为中断，不为此保留中间层解码或调整子模板。
- rationale：父级把 `base.get` 的原始文本作为 string 写入条目后，子模板再次 `base.get` 会对其二次序列化，`SYS.YAML_QUOTED` 只剥离一层引号并残留一层，`base.int` 必然拒绝。若改为保留解码则本变更失去意义；若改子模板则超出本 change 非目标。该取舍由 draft 确认。

### Decision: 失败消息归属实际校验方

- requirements：`校验 preferredDuringSchedulingIgnoredDuringExecution 的 weight`
- choice：删除两处带 `preferredDuringSchedulingIgnoredDuringExecution[%d].weight` 路径的 `fail`，形态与范围失败直接透传 `[base.int]` 与 `[base.int.range]` 消息。
- rationale：这两处 `fail` 只在删除门禁后不再有触发点；保留存在性判断的 `fail` 即可覆盖必填场景。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list <上下文> <点分路径>`，路径为 `weight`。
- output：可 `fromYaml` 解析的 YAML 字符串；标量取首个非空命中值，缺失与显式 null 返回空输出。
- ownership：取值、别名与空值语义由该能力承担；本层只判断空输出并继续传递。

### Dependency: `definitions.preferredSchedulingTerm`

- availability：`existing`
- source：`templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`
- operation：`consume`
- input：上下文 map，含 `weight` 与 `preference`；`weight` 为 `base.get` 的原始文本或数值。
- output：包含 `weight` 与 `preference` 的 YAML 字段片段；`weight` 形态非法时由 `base.int` 中断，超出 1 - 100 时由 `base.int.range` 中断，`preference` 为空或其子模板异常时由本模板前缀中断。
- ownership：`weight` 的整数形态与 1 - 100 区间校验、`preference` 的结构渲染由该能力承担；本层不再重复形态判定。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list <key> <value> [渲染模板]`。
- output：YAML 键值片段；值为空时不输出。
- ownership：渲染格式由该能力承担；本层只负责字段生效判断。

## 代码边界

### `templates/api-resources/Definitions/_NodeAffinity.tpl`

- access：`write`
- operations：`update` `definitions.nodeAffinity` 中 `preferredDuringSchedulingIgnoredDuringExecution` 条目 `weight` 的取值、门禁与条目构造；`update` 该模板的整体契约注释中 `weight` 相关行为与边界描述。
- writable-scopes：`definitions.nodeAffinity` 内 `weight` 处理闭环与文件头契约注释；不含 `requiredDuringSchedulingIgnoredDuringExecution` 分支与 `definitions.nodeAffinity.matchList`。

### `templates/api-resources/Definitions/_PreferredSchedulingTerm.tpl`

- access：`read`
- operations：`consume` `weight` 的整数形态与 1 - 100 区间校验链路。

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get` 的标量空值与别名语义。

### `templates/base/_types.tpl`

- access：`read`
- operations：`consume` `base.int` 的接受范围与失败消息前缀。

### `templates/base/_validate.tpl`

- access：`read`
- operations：`consume` `base.int.range` 的闭区间校验与失败消息前缀。

## 验证设计

- 最小有效：`/tmp/` 最小 application Chart 加载真实 `templates/base/*.tpl` 与 `templates/api-resources/Definitions/*.tpl`，调用 `definitions.nodeAffinity` 并只提供一条 `preferredDuringSchedulingIgnoredDuringExecution` 元素，`weight: 50` 与含单个 `matchExpressions` 的 `preference`，预期输出 `weight: 50` 与 `preference.matchExpressions`。
- 较完整有效：同一 fixture 覆盖 int64 `50` 与 `50.0`，预期均输出 `weight: 50`；覆盖两条 `preferredDuringSchedulingIgnoredDuringExecution` 元素，预期按输入顺序输出。
- 关键失败：`weight: "50"`、`weight: {a: b}`、`weight: [1, 2]`、`weight: abc`、`weight: 1.5`、`weight: true` 预期中断于 `[base.int]`；`weight: 0`、`weight: 101` 预期中断于 `[base.int.range]`；`weight: {}`、`weight: []` 预期中断且消息不以 `[definitions.nodeAffinity]` 开头。
- 必填：`weight` 缺失、为 `null`、为空字符串，预期在 `definitions.nodeAffinity` 层中断，消息包含条目下标与 `weight`。
- 依赖边界：`definitions.nodeSelector` 在仓库中缺失，`requiredDuringSchedulingIgnoredDuringExecution` 分支不在本次验证范围，fixture 不触发该分支；`templates/base/*.tpl` 与 `_PreferredSchedulingTerm.tpl` 使用当前真实实现，不使用同名 fixture 替代。
