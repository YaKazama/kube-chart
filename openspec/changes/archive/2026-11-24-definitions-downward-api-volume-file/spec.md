---
updated_at: "2026-11-24T15:04:30Z"
---

# definitions.downwardAPIVolumeFile 规格

## Purpose

为 Kubernetes `DownwardAPIVolumeFile` 提供可复用的字段片段渲染能力，使调用方可以用原生 map 或父模板清洗后的字符串引用生成单个 `items` 元素。

## ADDED Requirements

### Requirement: DownwardAPIVolumeFile 字段渲染

系统 MUST 仅渲染 `fieldRef`、`mode`、`path` 与 `resourceFieldRef`，并按 `fieldRef`、`mode`、`path`、`resourceFieldRef` 的顺序输出已生效字段；其他输入字段 MUST 静默忽略。

#### Scenario: 渲染原生 map 字段

- **WHEN** 输入为 `{"path": "meta/name", "fieldRef": {"fieldPath": "metadata.name"}, "mode": "0400"}`
- **THEN** 输出依次包含 `fieldRef`、`mode: 256` 与 `path: "meta/name"`，不包含其他字段。

#### Scenario: 渲染 resourceFieldRef 字段

- **WHEN** 输入为 `{"path": "cpu", "resourceFieldRef": {"resource": "limits.cpu"}}`
- **THEN** 输出依次包含 `path: "cpu"` 与 `resourceFieldRef`，不包含 `fieldRef` 或 `mode`。

#### Scenario: 忽略未声明字段

- **WHEN** 输入包含 `path`、`fieldRef` 与未声明的 `extra`
- **THEN** 输出不包含 `extra`。

### Requirement: 字段引用解析与委托

系统 MUST 接受 `fieldRef` 与 `resourceFieldRef` 的 map 或 string 值，并委托 `definitions.objectFieldSelector` 或 `definitions.resourceFieldSelector` 完成对应字段的校验与渲染。map 值 MUST 原样传递。string 值 MUST 按一个或多个空格切分并忽略首尾空白；`fieldRef` 第 1 段为 `fieldPath`（必填）、第 2 段为 `apiVersion`（可选）；`resourceFieldRef` 第 1 段为 `resource`（必填）、第 2 段为 `containerName`（可选）、第 3 段为 `divisor`（可选）；超出位次的段 MUST 忽略。必需段缺失或值既非 map 也非 string 时 MUST 中断。

#### Scenario: 传递 map 引用

- **WHEN** 输入为 `{"path": "meta", "fieldRef": {"fieldPath": "metadata.name", "apiVersion": "v1"}}`
- **THEN** 输出包含 `fieldRef`，其下包含 `apiVersion: "v1"` 与 `fieldPath: "metadata.name"`。

#### Scenario: 解析字符串 fieldRef

- **WHEN** 输入为 `{"path": "meta", "fieldRef": "metadata.name v1"}`
- **THEN** 输出包含 `fieldRef`，其下包含 `apiVersion: "v1"` 与 `fieldPath: "metadata.name"`。

#### Scenario: 解析带可选段的字符串 resourceFieldRef

- **WHEN** 输入为 `{"path": "cpu", "resourceFieldRef": "limits.cpu app 1m"}`
- **THEN** 输出包含 `resourceFieldRef`，其下包含 `containerName: "app"`、`divisor: "1m"` 与 `resource: "limits.cpu"`。

#### Scenario: 解析仅含必填段的字符串 resourceFieldRef

- **WHEN** 输入为 `{"path": "cpu", "resourceFieldRef": "limits.cpu"}`
- **THEN** 输出包含 `resourceFieldRef`，其下只包含 `resource: "limits.cpu"`。

#### Scenario: 委托选择器拒绝不支持的引用

- **WHEN** 输入为 `{"path": "meta", "fieldRef": "spec.containers"}`
- **THEN** 渲染中断并报告不受支持的字段路径。

#### Scenario: 拒绝非法引用类型

- **WHEN** 输入为 `{"path": "meta", "fieldRef": ["metadata.name"]}`
- **THEN** 渲染中断并报告引用值必须为 map 或 string。

### Requirement: path 与 mode 校验

`path` MUST 必填；系统 MUST 按 YAML 标量语义解码后 trim，并按相对路径规则归一化 `.` 与 `..` 段。空值、绝对路径、归一化结果为 `..` 或以 `../` 开头的路径 MUST 中断；生效的 `path` MUST 以带引号字符串输出。

`mode` MUST 可选；系统 MUST 接受八进制 0000-0777 或十进制 0-511 的数值或字符串，并以十进制整数输出；空值 MUST 省略；越界或非法形态 MUST 中断。

#### Scenario: 归一化 path

- **WHEN** 输入包含 `path: "meta/./name"` 或 `path: "meta/../name"`
- **THEN** 输出分别为 `path: "meta/name"` 与 `path: "name"`。

#### Scenario: 拒绝路径逃逸

- **WHEN** 输入包含 `path: "../name"` 或 `path: "a/../../name"`
- **THEN** 渲染中断并报告路径不得以 `..` 开头。

#### Scenario: 拒绝绝对路径

- **WHEN** 输入包含 `path: "/meta/name"`
- **THEN** 渲染中断并报告路径必须为相对路径。

#### Scenario: 拒绝缺失 path

- **WHEN** 输入只包含合法的 `fieldRef`，不含 `path`
- **THEN** 渲染中断并报告 `path` 必填。

#### Scenario: 归一化 mode

- **WHEN** 输入包含 `mode: "0400"` 或 `mode: 420`
- **THEN** 输出分别为 `mode: 256` 与 `mode: 420`。

#### Scenario: 拒绝非法 mode

- **WHEN** 输入包含 `mode: "512"` 或 `mode: "0999"`
- **THEN** 渲染中断并报告文件模式非法。

#### Scenario: 省略空 mode

- **WHEN** 输入包含 `path` 与合法 `fieldRef`，且 `mode` 缺失或为空
- **THEN** 输出不包含 `mode`。

### Requirement: 引用互斥与空值

系统 MUST 要求 `fieldRef` 与 `resourceFieldRef` 中恰好存在一个字段，且其值非空。两个字段同时存在、都不存在，或唯一存在的字段为空 string 或空 map 时 MUST 中断。

#### Scenario: 拒绝同时存在的引用

- **WHEN** 输入同时包含 `fieldRef` 与 `resourceFieldRef`
- **THEN** 渲染中断并报告两个引用字段互斥。

#### Scenario: 拒绝都缺失的引用

- **WHEN** 输入包含 `path`，但 `fieldRef` 与 `resourceFieldRef` 都未提供
- **THEN** 渲染中断并报告必须提供其中一个引用字段。

#### Scenario: 拒绝空引用

- **WHEN** 输入包含 `path` 与 `fieldRef: ""`，或包含 `path` 与 `fieldRef: {}`
- **THEN** 渲染中断并报告引用值不得为空。

## 非目标

- 不修改 `definitions.downwardAPIVolumeSource` 的 string item 过滤与组装逻辑。
- 不实现 `definitions.objectFieldSelector` 与 `definitions.resourceFieldSelector` 的内部校验，仅委托调用。
