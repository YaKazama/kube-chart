---
updated_at: "2026-11-03T10:54:24Z"
---

# Definitions LabelSelectorRequirement 规格

## Purpose

新增共享结构能力 `definitions.labelSelectorRequirement`，把调用方已归一化的单个 LabelSelectorRequirement 输入渲染为符合 Kubernetes API 的字段片段，并对 `key` 执行标签键语法校验。

## ADDED Requirements

### Requirement: 输入契约与失败消息归属

系统 MUST 接受 object（map）输入，只读取 `key`、`operator` 和可选 `values`。

`key` 缺失 MUST 失败；`key` 存在但不是 string MUST 失败。`operator` 缺失 MUST 失败；`operator` 存在但不是 string MUST 失败。

本模板主动产生的失败消息 MUST 以 `[definitions.labelSelectorRequirement]` 开头，并指明具体字段路径。`operator` 的枚举校验 MUST 委托既有渲染能力完成，其失败消息 MUST 保留该能力自身的前缀。

#### Scenario: 合法最小输入

- **WHEN** 输入为 `{key: app, operator: Exists}`
- **THEN** 渲染成功，输出包含 `key` 与 `operator`

#### Scenario: key 缺失

- **WHEN** 输入缺少 `key`
- **THEN** 失败并终止渲染，失败消息以 `[definitions.labelSelectorRequirement]` 开头并指明 `key`

#### Scenario: key 类型非法

- **WHEN** `key` 不是 string
- **THEN** 失败并终止渲染，失败消息指明 `key`

#### Scenario: operator 缺失或类型非法

- **WHEN** 输入缺少 `operator`，或 `operator` 不是 string
- **THEN** 失败并终止渲染，失败消息指明 `operator`

#### Scenario: 委托失败保留前缀

- **WHEN** `operator` 不是合法枚举值
- **THEN** 失败并终止渲染，失败消息保留委托渲染能力自身的失败前缀

### Requirement: key 标签键语法

系统 MUST 按 Kubernetes 标签键语法对完整 `key` 做全量匹配校验。

`key` MUST 由可选的 `<前缀>` 与必填的 `<名称>` 组成，两段之间由单个 `/` 分隔。`key` 中出现多个 `/` 时 MUST 失败，该失败消息 MUST 归属整体 `key`。

`<名称>` MUST 全量匹配以下范围：长度 1–63 个字符，首字符与末字符 MUST 为 `[A-Za-z0-9]`，中间字符只允许 `[A-Za-z0-9]`、`-`、`_`、`.`。

`<前缀>` 为可选；存在时 MUST 全量匹配以下范围：由单个 `.` 分隔的 DNS 标签序列，每段长度 1–63 个字符，每段首尾 MUST 为 `[a-z0-9]`，每段中间只允许 `[a-z0-9]` 与 `-`；`<前缀>` 总长 MUST 不超过 253 个字符。

前缀段失败消息 MUST 归属 `key.prefix`，名称段失败消息 MUST 归属 `key.name`。显式空前缀（如 `/name`）归属 `key.prefix`，空名称（如 `prefix/`）归属 `key.name`。

#### Scenario: 仅名称段

- **WHEN** `key` 为 `app` 或 `app.kubernetes.io`
- **THEN** 通过校验并按原值输出

#### Scenario: 名称段边界长度

- **WHEN** `key` 的名称段为 63 个字母数字字符
- **THEN** 通过校验

#### Scenario: 前缀与名称段

- **WHEN** `key` 为 `example/name` 或 `app.kubernetes.io/name`
- **THEN** 前缀段与名称段均通过校验，并按原值输出

#### Scenario: 名称段非法

- **WHEN** 名称段以 `-` 开头或结尾、含空格、长度为 64，或含其他非法字符
- **THEN** 失败并终止渲染，失败消息归属 `key.name`

#### Scenario: 前缀段非法

- **WHEN** 前缀段含大写字母、含连续 `.`、任一 DNS 标签长度为 64，或前缀段总长超过 253 个字符
- **THEN** 失败并终止渲染，失败消息归属 `key.prefix`

#### Scenario: 斜杠缺段

- **WHEN** `key` 为 `/name` 或 `prefix/`
- **THEN** 分别失败并终止渲染，失败消息归属 `key.prefix` 与 `key.name`

#### Scenario: 多个斜杠

- **WHEN** `key` 为 `a/b/c`
- **THEN** 失败并终止渲染，失败消息归属整体 `key`

### Requirement: operator 枚举

系统 MUST 只接受 `In`、`NotIn`、`Exists`、`DoesNotExist`。

枚举匹配 MUST 大小写敏感，MUST NOT 归一化输入。其他取值 MUST 失败并终止渲染，失败消息 MUST 给出合法取值列表。枚举校验 MUST 由既有字段渲染能力在输出前完成。

#### Scenario: 合法枚举

- **WHEN** `operator` 为 `In`、`NotIn`、`Exists` 或 `DoesNotExist`
- **THEN** 按原值输出

#### Scenario: 大小写不一致

- **WHEN** `operator` 为 `in`、`exist`、`doesnotexist` 或其他大小写变体
- **THEN** 失败并终止渲染，MUST NOT 归一化为合法值

#### Scenario: 未知取值

- **WHEN** `operator` 为 `Other`
- **THEN** 失败并终止渲染，失败消息包含 `In`、`NotIn`、`Exists`、`DoesNotExist`

### Requirement: 渲染顺序与 values 生效

系统 MUST 按 `key`、`operator`、`values` 的官方字段顺序输出。

`values` 缺失或为空 array 时 MUST 不输出 `values` 字段；`values` 非空时 MUST 以 string array 序列化输出。

`values` 的元素类型 MUST NOT 由本模板校验或转换，string 元素由调用方归一化保证。本模板 MUST NOT 自行执行 `values` 的类型校验或转换；类型门禁 MUST 由委托的集合渲染能力在渲染时执行，非 array 的非空输入 MUST 在该能力处失败并保留其自身失败前缀。

`values` 是否生效 MUST 只取决于其是否为空，MUST NOT 取决于 `operator`：本模板 MUST NOT 判断 `In`、`NotIn` 是否提供 `values`，MUST NOT 拦截 `Exists`、`DoesNotExist` 携带的非空 `values`。

系统 MUST NOT 输出 `status` 或其他字段。

#### Scenario: 字段顺序

- **WHEN** 输入为 `{key: app.kubernetes.io/name, operator: In, values: [web, api]}`
- **THEN** 输出依次包含 `key`、`operator`、`values`，且 `values` 为 `[web, api]`

#### Scenario: 空 values 不输出

- **WHEN** `values` 为空 array 或缺失
- **THEN** 输出不包含 `values` 字段

#### Scenario: values 类型非法

- **WHEN** `values` 存在且非空但不是 array
- **THEN** 失败并终止渲染，失败消息由委托的集合渲染能力产生并保留其自身前缀

#### Scenario: values 与 operator 无关

- **WHEN** `operator` 为 `Exists` 且 `values` 非空
- **THEN** 输出包含 `values`，本模板不拦截

#### Scenario: In 缺失 values 不由本模板失败

- **WHEN** `operator` 为 `In` 且 `values` 缺失
- **THEN** 输出包含 `key` 与 `operator`，本模板不因缺少 `values` 失败

## 非目标

- 不解析 `matchExpressions` 的字符串简写。
- 不承担 `matchLabels` 到 requirement 的构造路径。
- 不为 `values` 中的空字符串项添加清理或过滤逻辑。
- 不判断 `values` 对 `In`、`NotIn`、`Exists`、`DoesNotExist` 的适用性。
- 不收紧 `definitions.labelSelector` 字符串简写中 `key` 的匹配范围；严格格式校验只在本能力执行。
- 不输出 `status`。
