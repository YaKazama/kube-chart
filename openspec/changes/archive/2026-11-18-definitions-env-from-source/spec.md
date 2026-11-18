---
updated_at: "2026-11-18T05:22:49Z"
---

# definitions.envFromSource 规格

## Purpose

新增共享结构能力 `definitions.envFromSource`，把单个 `EnvFromSource` 上下文按互斥引用字段分发到对应 env 来源子模板，并把引用字符串归一为子模板所需的 map。

## ADDED Requirements

### Requirement: 互斥引用识别与分发

系统 MUST 在 `EnvFromSource` 的 `configMapRef` 与 `secretRef` 中识别实际出现的字段，并只把该字段委托给对应的 env 来源子模板。

- 字段映射为：`configMapRef` → `definitions.configMapEnvSource`；`secretRef` → `definitions.secretEnvSource`。
- 两个字段 MUST 恰好出现一个；同时出现两个或都未出现时 MUST 中断渲染。
- 同时出现两个时，失败消息 MUST 列出实际出现的字段名；都未出现时，失败消息 MUST 指明必须提供其中一个。
- 输出 MUST 只包含一个引用字段，不得同时输出 `configMapRef` 与 `secretRef`。
- 输入中除 `configMapRef`、`prefix`、`secretRef` 之外的键 MUST NOT 产生输出，也不影响分发。

#### Scenario: 单个 configMapRef

- **WHEN** 输入只含 `configMapRef`
- **THEN** 只委托 `definitions.configMapEnvSource`

#### Scenario: 单个 secretRef

- **WHEN** 输入只含 `secretRef`
- **THEN** 只委托 `definitions.secretEnvSource`

#### Scenario: 两个引用字段并存

- **WHEN** 输入同时含 `configMapRef` 与 `secretRef`
- **THEN** 渲染中断，失败消息包含这两个字段名

#### Scenario: 未提供引用字段

- **WHEN** 输入不含 `configMapRef` 与 `secretRef`
- **THEN** 渲染中断，失败消息指明必须提供其中一个

### Requirement: 原生对象透传

系统 MUST 在引用字段值为 map 时把该 map 原样作为对应子模板的上下文，不校验、不补全、不改写其内部字段。

#### Scenario: 两个引用字段分别透传

- **WHEN** 引用字段值为 map，且分别使用 `configMapRef` 与 `secretRef` 两种字段名
- **THEN** 对应子模板收到与输入一致的结构

#### Scenario: 子模板返回空内容

- **WHEN** 对应子模板返回空内容
- **THEN** 输出不含该引用字段

### Requirement: 引用字符串归一

系统 MUST 在引用字段值为 string 时把该字符串按位次归一为子模板所需的 map。

- 归一前 MUST 先去除首尾空白。
- 分隔符 MUST 为一段或多段连续的空白或逗号，且 MUST NOT 作为段内容的一部分。
- 第 1 段 MUST 作为 `name`，第 2 段 MUST 作为 `optional`；两者 MUST 原样作为 string 传递，不做布尔、数值或字符集转换，也 MUST NOT 中断渲染。
- 可选段缺省时 MUST NOT 出现在归一结果中。
- 超出第 2 段的多余段 MUST 被忽略。
- 分隔符产生的空段 MUST 被丢弃，不参与位次映射。
- 切分后没有任何段时 MUST NOT 归一该字段，输出空内容且不中断渲染。
- 归一结果的键 MUST 为官方字段名 `name` 与 `optional`。

#### Scenario: 只含 name

- **WHEN** `configMapRef` 为 `app-config`
- **THEN** 子模板收到只含 `name` 的 map，值为 `app-config`

#### Scenario: name 与 optional

- **WHEN** `secretRef` 为 `db-secret true`
- **THEN** 归一结果为 `name` 与 `optional`，`optional` 为字符串 `true`

#### Scenario: optional 原样传递

- **WHEN** `configMapRef` 为 `app-config notabool`
- **THEN** 渲染不中断，归一结果的 `optional` 为字符串 `notabool`

#### Scenario: 逗号与空白混用

- **WHEN** `configMapRef` 为 `app-config,true` 或 `app-config ,  true`
- **THEN** 均归一为 `name` 与 `optional`

#### Scenario: 多余段忽略

- **WHEN** `secretRef` 为 `db-secret true extra`
- **THEN** 归一结果只含 `name` 与 `optional`，`extra` 被忽略

#### Scenario: 空引用字符串

- **WHEN** `configMapRef` 为空字符串
- **THEN** 不归一该字段，输出空内容，渲染不中断

### Requirement: prefix 输出

系统 MUST 在 `prefix` 非空时把它与引用字段同级输出，且 MUST NOT 校验其内容、长度或字符集。

- `prefix` 缺失、为 `null` 或为空字符串时 MUST NOT 输出该键。
- `prefix` MUST NOT 改变引用字段的归一结果。
- `prefix` 不是 string 时 MUST 中断渲染，不做隐式转换。
- 输出顺序 MUST 符合官方字段顺序 `configMapRef`、`prefix`、`secretRef`：`configMapRef` 存在时 `prefix` 在其后，`secretRef` 存在时 `prefix` 在其前。

#### Scenario: configMapRef 与 prefix

- **WHEN** 输入含 `configMapRef` 与 `prefix`
- **THEN** 输出顺序为 `configMapRef` 在前、`prefix` 在后

#### Scenario: secretRef 与 prefix

- **WHEN** 输入含 `secretRef` 与 `prefix`
- **THEN** 输出顺序为 `prefix` 在前、`secretRef` 在后

#### Scenario: 未提供 prefix

- **WHEN** 输入不含 `prefix`
- **THEN** 输出不含 `prefix` 键

#### Scenario: prefix 不做校验

- **WHEN** `prefix` 为 `X=Y`
- **THEN** 渲染不中断，原样输出该值

### Requirement: 非法值类型中断

系统 MUST 在引用字段值既不是 map 也不是 string 时中断渲染，失败消息 MUST 包含该字段名。

#### Scenario: 数值字段值

- **WHEN** `configMapRef` 为数字
- **THEN** 渲染中断，失败消息包含 `configMapRef`

#### Scenario: null 字段值

- **WHEN** `secretRef` 为 `null`
- **THEN** 渲染中断，失败消息包含 `secretRef`

### Requirement: 子模板委托边界

系统 MUST 只通过 `definitions.configMapEnvSource` 与 `definitions.secretEnvSource` 渲染引用字段内容。

- 两个子模板在当前 change 中 MUST NOT 实现，其可用性与内部字段校验由后续 change 提供。
- 本 change MUST NOT 新增这两个子模板的实现、占位定义或内联替代实现。
- 输出 MUST NOT 包含 `envFrom` 父键或数组包装；父键与数组由调用方负责。

#### Scenario: 委托而非内联

- **WHEN** 引用字段产生有效上下文
- **THEN** 字段内容完全来自对应子模板，本能力不输出 `name`、`optional` 等子模板内部字段

#### Scenario: 输出层级

- **WHEN** 委托返回非空结果
- **THEN** 输出以引用字段名为顶层键，不含 `envFrom`

## 非目标

- 不实现 `definitions.configMapEnvSource` 与 `definitions.secretEnvSource`，不校验 `name`、`optional` 的字符集、长度或布尔语义。
- 不处理 `envFrom` 数组与字符串行解析，该部分属父级 change `fix-definitions-container-env-from`。
- 不校验 `prefix` 的字符集、长度或 `=` 等 Kubernetes 约束。
- 不实现 `envFrom` 数组元素的合并、去重或排序。
