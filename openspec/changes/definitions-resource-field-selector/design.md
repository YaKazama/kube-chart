# definitions.resourceFieldSelector 设计

## 技术目标

- capability：`definitions.resourceFieldSelector`
- artifact-type：Kubernetes 原生 API 同域共享结构模板（`ResourceFieldSelector`）
- target：`templates/api-resources/Definitions/_ResourceFieldSelector.tpl`

## 设计决策

### Decision: 单文件承载并按官方字段顺序输出

- requirements：`字段渲染顺序与类型`、`resource 必填与支持列表校验`、`divisor 单位与资源类型匹配`
- choice：新建 `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`，只包含 `definitions.resourceFieldSelector` 一个 define，按 `containerName` → `divisor` → `resource` 的官方顺序输出。
- rationale：共享结构文件围绕与文件名对应的主模板组织；三个字段各自独立，无需拆分辅助模板。

### Decision: containerName 与 resource 各自独立取值

- requirements：`字段渲染顺序与类型`、`resource 必填与支持列表校验`
- choice：`containerName` 以 `base.get` 取值、`base.string.normalize` 解码并 `trim`，非空时以 `quote` 输出；`resource` 同链路取值后自判空，再按新增的 `K8S.RESOURCE_FIELD` 常量校验，输出调用推迟到 `divisor` 之后。
- rationale：`containerName` 是纯可选字符串，无需额外校验；`resource` 必填且需枚举校验，两条链路前半段同构但后半段不同，合并会引入条件分支而不减少重复；`base.get` 的必填参数消息前缀为 `[base.get]`，无法满足失败消息统一为 `[模板名] 字段路径: 错误原因`，故必填由本层判定。

### Decision: divisor 归一后按资源类型分流校验形态

- requirements：`divisor 单位与资源类型匹配`
- choice：`divisor` 以 `base.get` 取值并 `trim`；非空时先用 `SYS.YAML_QUOTED` 剥离外层引号得到校验文本，再按 `hasSuffix ".cpu"` 分流：命中则用 `K8S.DIVISOR_CPU`（`^(?:(\d+)m|(\d+)(?:\.(\d{1,3}))?)$`，依次捕获整数毫核、整数核值与小数部分）校验，否则用 `K8S.DIVISOR_SIZE`（`^\d+(\.\d{1,3})?(?:Ki|Mi|Gi|Ti|Pi|Ei|k|M|G|T|P|E)$`）校验。
- rationale：cpu 的 divisor 可以是核值或毫核，毫核必须是整数，小数只能表示核值；memory 与 ephemeral-storage 的 divisor 必须用字节单位声明输出倍数，无单位取值没有实际意义。两个正则的匹配集均为 `K8S.QUANTITY` 的真子集，后续 `base.quantity` 调用不会产生新的失败边界，因此白名单命中后无需再单独做一次 Quantity 校验。

### Decision: cpu 小数核值换算为毫核后统一交给 base.quantity 渲染

- requirements：`字段渲染顺序与类型`
- choice：cpu 命中 `K8S.DIVISOR_CPU` 后先判定形态：以 `m` 结尾为整数毫核，含小数点为小数核值，其余为整数核值。小数核值用捕获组 `$2`、`$3` 取整数与小数部分，小数部分右补零到三位后换算为整数毫核字符串。所有形态统一以 `base.field` 的 `base.quantity` 渲染模板输出，不再按形态选择不同渲染模板。
- rationale：`base.quantity` 作为渲染模板返回原值，使无单位整数以数字标量输出、带单位取值以字符串标量输出，无需调用方自行选择渲染模板。`1.5` 核与 `1500m` 等价，但小数核值经过父级的 `fromYaml` 往返后会变成浮点类型，换算为整数毫核后语义与类型都稳定；`base.int` 会四舍五入所以不能用于小数核值。已实测无单位形态经 `fromYaml` 回读为字符串，引号有无不影响下游类型。

### Decision: 先取 resource 再处理 divisor，输出顺序仍按官方字段表

- requirements：`divisor 单位与资源类型匹配`
- choice：处理顺序为 `containerName` 取值并输出 → `resource` 取值与校验（暂不输出）→ `divisor` 校验并输出 → `resource` 输出。
- rationale：官方字段表描述的是 YAML 输出顺序，不是内部处理顺序；`divisor` 的允许集合依赖 `resource` 的类型后缀，必须先得到已归一化的 `$resource`；将 `resource` 的 `base.field` 调用推迟到 `divisor` 之后，同时满足依赖与输出顺序两个约束。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [上下文, 点分路径]`；本能力使用 `containerName`、`divisor`、`resource` 三条单层路径，不传强制类型与必填参数。
- output：YAML 字符串；路径缺失时为空输出。
- ownership：取值与别名识别由 `base.get` 负责；必填判空与失败消息由本能力负责。

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 的原始输出，不得预先 trim。
- output：解码后的 string；空输入返回空字符串；非 string 标量中断。
- ownership：YAML 标量还原与类型失败由该模板负责；本能力只消费结果并判空。

### Dependency: `base.quantity`

- availability：`existing`
- source：`templates/base/_k8s.tpl`
- operation：`consume`
- input：形态白名单校验通过的 `divisor` 文本，作为 `base.field` 的渲染模板参数传入，不单独调用。
- output：校验通过返回原值；非法时中断，失败消息使用 `[base.quantity]` 前缀。
- ownership：Quantity 格式门禁由该模板负责；因白名单匹配集为其真子集，本依赖不产生额外的可观察失败边界。

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [键名, 值, 渲染模板]`；`containerName` 与 `resource` 使用 `quote`，`divisor` 统一使用 `base.quantity`。
- output：单字段 YAML 片段，空值不输出。
- ownership：渲染格式与引号由该模板负责；字段生效判断由本能力负责。

### Dependency: `base.env`

- availability：`existing`
- source：`templates/base/_env.tpl`
- operation：`update`
- input：占位空字符串，经 `fromYaml` 恢复常量 Map。
- output：常量 Map；本能力读取新增的 `K8S.RESOURCE_FIELD`、`K8S.DIVISOR_CPU`、`K8S.DIVISOR_SIZE` 与既有的 `SYS.YAML_QUOTED`。
- ownership：常量定义与结构有效性由该模板负责；本 change 只新增三个键，不改动其他键。

## 代码边界

### `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`

- access：`write`
- operations：add `definitions.resourceFieldSelector`
- writable-scopes：整个新建文件

### `templates/base/_env.tpl`

- access：`write`
- operations：add `K8S.RESOURCE_FIELD`、`K8S.DIVISOR_CPU`、`K8S.DIVISOR_SIZE`
- writable-scopes：`K8S` 映射下新增的三行键

## 验证设计

- 最小有效：真实 `templates/base/` 与 `_ResourceFieldSelector.tpl` 加载到 `/tmp/` 最小 application Chart，输入 `resource: limits.cpu`，断言只输出 `resource` 且为双引号字符串。
- 较完整有效：三字段齐全时按 `containerName`、`divisor`、`resource` 顺序输出；六个资源名全部通过；`divisor` 的 `1`、`2` 输出不带引号数字，`1.5`、`0.05` 换算为 `1500m`、`50m`，`1m`、`500m`、`2Mi`、`128Mi`、`1Ti` 输出字符串标量；含额外键时只输出三个官方字段。
- 关键失败：`resource` 缺失、`resource` 为空白、`resource` 为 `metadata.name`、`resource` 为 `limits.gpu`、`.cpu` 下 `divisor` 为 `1Ki`、`2Mi`、`1.5m`、`.memory` 下 `divisor` 为 `1`、`1m`、`500m`、`divisor` 为 `1Xi`，均中断且消息含对应字段名或实际取值。
- 忽略边界：只有 `resource` 时不输出 `containerName` 与 `divisor`；`divisor` 为空白时不输出。
- 正则常量：验证必须加载真实 `templates/base/_env.tpl`，不得用同名 fixture 替代被新增的四个常量。
