---
updated_at: "2026-11-17T15:31:07Z"
---

# definitions.envVarSource 规格

## Purpose

新增共享结构能力 `definitions.envVarSource`，把单个 `EnvVarSource` 上下文按互斥字段分发到对应选择器子模板，并把紧凑字符串写法归一为选择器 map。

## ADDED Requirements

### Requirement: 互斥字段识别与分发

系统 MUST 在 `EnvVarSource` 的 `configMapKeyRef`、`fieldRef`、`fileKeyRef`、`resourceFieldRef`、`secretKeyRef` 中识别实际出现的字段，并只委托该字段对应的选择器子模板。

- 字段映射为：`configMapKeyRef` → `definitions.configMapKeySelector`；`fieldRef` → `definitions.objectFieldSelector`；`fileKeyRef` → `definitions.fileKeySelector`；`resourceFieldRef` → `definitions.resourceFieldSelector`；`secretKeyRef` → `definitions.secretKeySelector`。
- 同时出现两个及以上字段时中断渲染，失败消息必须列出实际出现的字段名。
- 未出现任何字段时输出空内容，不中断渲染。
- 输入中除上述五个字段之外的键不产生输出，也不影响分发。

#### Scenario: 单字段分发

- **WHEN** 输入只含 `secretKeyRef`
- **THEN** 只委托 `definitions.secretKeySelector`

#### Scenario: 多字段并存

- **WHEN** 输入同时含 `configMapKeyRef` 与 `secretKeyRef`
- **THEN** 渲染中断，失败消息包含这两个字段名

#### Scenario: 无字段

- **WHEN** 输入不含任何上述字段
- **THEN** 输出空内容，渲染不中断

### Requirement: 原生对象透传

系统 MUST 在字段值为 map 时把该 map 原样作为对应选择器子模板的上下文，不校验、不补全、不改写其内部字段。

#### Scenario: 五个字段分别透传

- **WHEN** 字段值为 map，且分别使用五个字段名
- **THEN** 对应选择器子模板收到同一结构

#### Scenario: 子模板无结果

- **WHEN** 选择器子模板返回空内容
- **THEN** 输出不含该 `*Ref` 字段

### Requirement: 紧凑字符串归一

系统 MUST 在字段值为 string 时按空白或逗号切分为段，并按固定位次映射为选择器字段名。

- 位次映射为：`configMapKeyRef` → `<name> [key] [optional]`；`fieldRef` → `<fieldPath> [apiVersion]`；`fileKeyRef` → `<volumeName> <path> [key] [optional]`；`resourceFieldRef` → `<resource> [containerName] [divisor]`；`secretKeyRef` → `<name> [key] [optional]`。
- 组装的键 MUST 为上述官方字段名，可选段的字面量 MUST 原样传递为字符串，不做布尔或数值转换。
- 可选段缺省时 MUST NOT 出现在组装结果中。
- 段数少于该字段必需段数时 MUST NOT 组装该字段，输出空内容且不中断渲染；必需段数为 `configMapKeyRef` 1 段、`fieldRef` 1 段、`fileKeyRef` 2 段、`resourceFieldRef` 1 段、`secretKeyRef` 1 段。
- 超出可选段数量的多余段 MUST 被忽略。
- 分隔符产生的空段 MUST 被丢弃，不参与位次映射。

#### Scenario: 位次组装

- **WHEN** `configMapKeyRef` 为 `app-config LOG_LEVEL`
- **THEN** 选择器子模板收到 `name` 与 `key` 两个字段，值分别为 `app-config` 与 `LOG_LEVEL`

#### Scenario: 可选段原样传递

- **WHEN** `secretKeyRef` 为 `db-creds password true`
- **THEN** 组装结果为 `name`、`key`、`optional`，`optional` 为字符串 `true`

#### Scenario: 逗号与空白混用

- **WHEN** `fieldRef` 为 `metadata.name, v1`
- **THEN** 组装结果为 `fieldPath` 与 `apiVersion`，值分别为 `metadata.name` 与 `v1`

#### Scenario: 段数不足

- **WHEN** `fileKeyRef` 为 `only-volume`
- **THEN** 不组装该字段，输出空内容，渲染不中断

#### Scenario: 多余段忽略

- **WHEN** `resourceFieldRef` 为 `limits.cpu api 1 extra`
- **THEN** 组装结果只含 `resource`、`containerName`、`divisor`，`extra` 被忽略

### Requirement: 非法值类型中断

系统 MUST 在字段值既不是 map 也不是 string 时中断渲染，失败消息必须包含该字段名。

#### Scenario: 数值字段值

- **WHEN** `configMapKeyRef` 为数字
- **THEN** 渲染中断，失败消息包含 `configMapKeyRef`

#### Scenario: null 字段值

- **WHEN** `fieldRef` 为 `null`
- **THEN** 渲染中断，失败消息包含 `fieldRef`

### Requirement: 子模板委托边界

系统 MUST 只通过五个选择器子模板渲染字段内容，并输出单键的 `*Ref` 字段片段。

- 五个选择器子模板在当前 change 中不实现，其可用性与内部字段校验由后续 change 提供。
- 本 change MUST NOT 新增这些子模板的实现、占位定义或内联替代实现。
- 输出 MUST NOT 包含 `valueFrom` 父键；该父键由调用方添加。

#### Scenario: 委托而非内联

- **WHEN** 任一字段产生有效上下文
- **THEN** 字段内容完全来自对应选择器子模板，本能力不输出选择器对象内部字段

#### Scenario: 输出层级

- **WHEN** 委托返回非空结果
- **THEN** 输出以字段名（如 `configMapKeyRef`）为顶层键，不含 `valueFrom`

## 非目标

- 不实现五个选择器子模板，不输出选择器对象内部字段的校验、类型转换与缺省处理。
- 不处理 `definitions.envVar` 层的关键字识别与第一层字符串拆解。
- 不校验字段值的 Kubernetes 名称、路径或资源格式。
