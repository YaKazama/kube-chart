---
updated_at: "2026-11-11T16:07:50Z"
---

# definitions.resourceRequirements 规格

## Purpose

为 Kubernetes `ResourceRequirements` 提供可复用的共享结构渲染能力，统一 `claims`、`limits`、`requests` 的取值、类型归一化、量值校验与失败边界，供 Pod 级与容器级 `resources` 复用。

## ADDED Requirements

### Requirement: resources 字段渲染

系统 MUST 按 `claims`、`limits`、`requests` 的 API 字段顺序渲染 `definitions.resourceRequirements` 片段，且只输出本层字段。

- `claims`、`limits`、`requests` 均为可选。
- 三者均未设置或归一化后为空时，MUST 输出空内容，不输出 `resources` 父键。
- 未列出的输入字段 MUST 静默忽略。

#### Scenario: 三个字段全部省略

- **WHEN** 上下文不包含 `claims`、`limits`、`requests`
- **THEN** 模板输出空内容

#### Scenario: 只设置 limits

- **WHEN** 上下文只包含 `limits: {cpu: 500m}`
- **THEN** 输出只包含 `limits` 字段

### Requirement: limits 与 requests 的 object 形式

`limits` 与 `requests` MUST 接受 map 形式，每个键为资源名，值为 IntOrString 量值。

- 资源键 MUST 限定为 `cpu`、`memory`、`ephemeral-storage`、`hugepages-<size>`；其他键（含扩展资源键）MUST 静默丢弃，不渲染也不报错。
- 量值为数值或字符串 `0` 时 MUST 视为未设置，且该判断先于其他校验。
- `memory`、`ephemeral-storage` 与 `hugepages-<size>` 的量值 MUST 通过公共 `base.quantity` 校验；合法时 MUST 原样输出，不做单位换算。
- `cpu` MUST 接受整数核数、最多 3 位小数的核数与 `<正整数>m` 形式的毫核数。
- `cpu` 为整数核数或整数毫核数时 MUST 原样输出；为小数核数时 MUST 换算为毫核（1 cpu = 1000m）。
- `cpu` 小数位超过 3 位，或毫核形式带小数（如 `1.5m`）时 MUST 中断渲染。
- `cpu` 换算后小于 `1m` 且不为 `0` 时 MUST 中断渲染。
- 输入既不是 map 也不是字符串简写时 MUST 中断渲染。

#### Scenario: 扩展资源键被丢弃

- **WHEN** `limits` 包含 `nvidia.com/gpu: 1`
- **THEN** 输出不包含该键，且渲染不中断

#### Scenario: cpu 小数换算

- **WHEN** `limits` 为 `{cpu: 0.5}` 或 `{cpu: 0.005}`
- **THEN** 输出分别为 `cpu: 500m` 与 `cpu: 5m`

#### Scenario: cpu 整数与毫核原样输出

- **WHEN** `limits` 为 `{cpu: 1}` 或 `{cpu: 500m}`
- **THEN** 输出分别为 `cpu: 1` 与 `cpu: 500m`

#### Scenario: cpu 非法精度

- **WHEN** `limits` 为 `{cpu: 1.5m}` 或 `{cpu: 0.0005}`
- **THEN** 渲染中断

#### Scenario: cpu 零值

- **WHEN** `limits` 为 `{cpu: 0}` 或 `{cpu: 0m}`
- **THEN** 输出不包含 `cpu`

#### Scenario: hugepages 合法

- **WHEN** `limits` 为 `{hugepages-2Mi: 1024Mi}`
- **THEN** 输出 `hugepages-2Mi: 1024Mi`

#### Scenario: hugepages 非法

- **WHEN** `limits` 为 `{hugepages-2Mi: 1Gi}`、`{hugepages-2Mi: 3Mi}`、`{hugepages-2Mi: 2Mi}` 或 `{hugepages-abc: 1Mi}`
- **THEN** 渲染中断，原因分别为单位不同、非整数倍、`max` 不大于 `size`、`<size>` 无法解析

### Requirement: hugepages 量值约束

`hugepages-<size>` 的量值 MUST 满足以下约束，任一不满足即中断渲染。

- `hugepages-<size>` 的 `<size>` 与作为值的 `hugepages-max` MUST 可解析为数值加可选二进制单位（`Ki`、`Mi`、`Gi`、`Ti`、`Pi`、`Ei`）。
- 两者单位 MUST 相同；两者均无单位时视为相同。
- 校验时 MUST 换算为字节数；`hugepages-max` MUST 大于 `hugepages-size`，且 MUST 是 `hugepages-size` 的整数倍（余数为 `0`）。
- 渲染时 MUST 保持 `<size>` 与 `hugepages-max` 的原始表达，且只校验上述关系，不校验页大小是否为硬件标准值。

#### Scenario: 不同单位但数值等价

- **WHEN** `limits` 为 `{hugepages-2Mi: 1Gi}`
- **THEN** 渲染中断，因为单位不同

#### Scenario: 渲染保持原样

- **WHEN** `limits` 为 `{hugepages-2Mi: 1024Mi}`
- **THEN** 输出键为 `hugepages-2Mi`、值为 `1024Mi`，不换算为字节数

### Requirement: limits 与 requests 的 string 简写

`limits` 与 `requests` MUST 接受字符串形式，按 `[cpu] [memory] [ephemeral-storage] ([hugepages-size] [hugepages-max])` 的位置顺序解析。

- 分隔符 MUST 为空格或逗号。
- 每个位置对应一个分段；跳过某位置时 MUST 使用 `""`、`''` 或 `0` 占位，占位分段视为未设置。
- `""` 与 `''` MUST 等价：两者一律按占位处理，不得只识别其中一种，也不得把它们当作量值参与校验。
- 缺少占位时，靠前的分段按位置顺序占用，未提供的尾部位置视为未设置。
- 括注内的 `hugepages-size` 与 `hugepages-max` MUST 成对出现；只给一个、括号不成对或括号内分段数不为 2 时 MUST 中断渲染。
- 括号外的分段数超过 3 时 MUST 中断渲染。
- string 形式与 object 形式 MUST 产生相同的量值校验、零值处理和输出结果。

#### Scenario: 完整字符串

- **WHEN** `limits` 为 `"500m 512Mi 1Gi (2Mi 1024Mi)"`
- **THEN** 输出 `cpu: 500m`、`memory: 512Mi`、`ephemeral-storage: 1Gi`、`hugepages-2Mi: 1024Mi`

#### Scenario: 使用占位跳过 cpu

- **WHEN** `limits` 为 `"" 512Mi 1Gi` 或 `'' 512Mi 1Gi`
- **THEN** 输出只包含 `memory: 512Mi` 与 `ephemeral-storage: 1Gi`

#### Scenario: 连续占位跳过多个位置

- **WHEN** `limits` 为 `'' '' 1Gi`
- **THEN** 输出只包含 `ephemeral-storage: 1Gi`

#### Scenario: 零值占位

- **WHEN** `limits` 为 `0 512Mi 1Gi`
- **THEN** 输出只包含 `memory: 512Mi` 与 `ephemeral-storage: 1Gi`，且不中断渲染

#### Scenario: 括号不成对

- **WHEN** `limits` 为 `"500m 512Mi 1Gi (2Mi"` 或 `"500m 512Mi 1Gi (2Mi 1024Mi 2048Mi)"`
- **THEN** 渲染中断

### Requirement: claims 数组

`claims` MUST 接受 ResourceClaim 数组，元素可为 string 或 map，且 MUST 允许同一数组内混用。

- string 元素 MUST 为 `<name> [request]`；分隔符为空格或逗号；名称 MUST 非空，否则中断渲染。
- string 元素分段数超过 2 时 MUST 中断渲染。
- map 元素 MUST 作为原生 `ResourceClaim` 传递，不在本层校验其字段。
- 非 string 且非 map 的元素 MUST 中断渲染。
- 每个元素 MUST 归一化为 map 后委托 `definitions.resourceClaim`，并按数组顺序回收结果。
- 委托结果为空、无法解析为非空 map 时 MUST 剔除该条目；全部条目被剔除时 MUST 不输出 `claims`。
- `claims` 不是数组时 MUST 中断渲染。

#### Scenario: string 与 map 混用

- **WHEN** `claims` 为 `["gpu", {name: "nic", request: "rx"}]`
- **THEN** 两个条目分别以 map 上下文委托 `definitions.resourceClaim`

#### Scenario: 结果全部为空

- **WHEN** 所有委托结果为空
- **THEN** 输出不包含 `claims`，且不中断渲染

#### Scenario: 委托模板不可用

- **WHEN** 真实 Chart 中不存在 `definitions.resourceClaim` 且 `claims` 非空
- **THEN** 渲染中断

### Requirement: Pod 级 resources 限制

`core.podSpec` 传递的 Pod 级 `resources` MUST 与容器级区分，并应用更窄的资源键范围。

- Pod 级 `resources` 的资源键 MUST 限定为 `cpu`、`memory`、`hugepages-<size>`；`ephemeral-storage` 与其他键 MUST 静默丢弃。
- Pod 级 `resources` 的 `claims` MUST 静默忽略，不渲染也不报错。
- string 简写在 Pod 级下 MUST 同样丢弃第三个位置（`ephemeral-storage`）。
- 非 Pod 级调用 MUST 保留 `ephemeral-storage` 与 `claims` 的完整行为。

#### Scenario: Pod 级 claims 被忽略

- **WHEN** Pod 级 `resources` 包含 `claims`
- **THEN** 输出不包含 `claims`，且不中断渲染

#### Scenario: Pod 级 ephemeral-storage 被丢弃

- **WHEN** Pod 级 `resources` 的 `limits` 为 `{cpu: 500m, ephemeral-storage: 1Gi}`
- **THEN** 输出只包含 `limits.cpu`

### Requirement: core.podSpec 的 resources 透传

`core.podSpec` 在 `resources` 字段 MUST 把完整上下文透传给 `definitions.resourceRequirements`，不再按固定键裁剪。

- 透传的子上下文 MUST 携带 Pod 级标识，且 MUST 不修改父级上下文。
- 透传 MUST 使 `claims`、`limits`、`requests` 的同级 `*Alias` 生效。
- `resources` 缺失或为空时 MUST 不调用子模板、不输出字段。

#### Scenario: 别名生效

- **WHEN** Pod 级 `resources` 提供 `limitsAlias`
- **THEN** 输出包含对应 `limits` 内容

#### Scenario: 空 resources

- **WHEN** `resources` 为空 map
- **THEN** 输出不包含 `resources`

## 非目标

- 不创建 `definitions.resourceClaim`，非空 `claims` 的真实渲染由后续 change 补齐。
- 不修改 `base.quantity` 的既有校验规则与失败信息。
- 不渲染 `core.podSpec` 中 `resources` 之外的字段。
