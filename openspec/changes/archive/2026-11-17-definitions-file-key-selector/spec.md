---
updated_at: "2026-11-17T16:21:08Z"
---

# definitions.fileKeySelector 规格

## Purpose

新增共享结构能力 `definitions.fileKeySelector`，把单个 map 上下文渲染为 Kubernetes `FileKeySelector` 字段片段，供 `definitions.envVarSource` 的 `fileKeyRef` 分支使用。

## ADDED Requirements

### Requirement: 字段渲染顺序与类型

系统 MUST 按官方字段顺序渲染 `FileKeySelector` 的 `key`、`optional`、`path`、`volumeName` 四个字段。

- `key`、`path`、`volumeName` MUST 以双引号字符串输出。
- `optional` MUST 以布尔值输出，不加引号。
- `optional` 缺省时不输出该字段。
- 输入中除这四个字段之外的键静默忽略。

#### Scenario: 四个字段齐全

- **WHEN** 输入为 `key: LOG_LEVEL`、`optional: true`、`path: app.log`、`volumeName: env-vol`
- **THEN** 输出依次为 `key: "LOG_LEVEL"`、`optional: true`、`path: "app.log"`、`volumeName: "env-vol"`

#### Scenario: optional 缺省

- **WHEN** 输入只含 `key`、`path`、`volumeName`
- **THEN** 只输出这三个字段，不含 `optional`

#### Scenario: optional 为 false

- **WHEN** `optional` 为原生 `false`
- **THEN** 输出 `optional: false`

#### Scenario: 额外键忽略

- **WHEN** 输入含四个官方字段与未定义键 `foo`
- **THEN** 输出不含 `foo`

### Requirement: 三个必填字段校验

系统 MUST 要求 `volumeName`、`path`、`key` 均非空，并在不满足时中断渲染。

- 任一字段缺失或为空白时中断，失败消息 MUST 包含该字段名。

#### Scenario: volumeName 缺失

- **WHEN** 输入只有 `path` 与 `key`
- **THEN** 渲染中断，失败消息包含 `volumeName`

#### Scenario: path 缺失

- **WHEN** 输入只有 `volumeName` 与 `key`
- **THEN** 渲染中断，失败消息包含 `path`

#### Scenario: key 缺失

- **WHEN** 输入只有 `volumeName` 与 `path`
- **THEN** 渲染中断，失败消息包含 `key`

#### Scenario: 空白值

- **WHEN** `path` 或 `key` 或 `volumeName` 为只含空白的字符串
- **THEN** 渲染中断，失败消息包含对应字段名

### Requirement: path 相对路径归一化

系统 MUST 在 `path` 非空后通过公共路径能力以相对路径模式归一化，并输出归一化结果而非原始输入。

- `path` 为绝对路径时 MUST 中断渲染，失败消息由公共路径能力输出并保留其自身前缀。
- `path` 归一化结果等于 `..` 或以 `../` 开头时 MUST 中断渲染，失败消息 MUST 包含归一化结果。
- `path` 归一化结果等于 `.` 时 MUST 中断渲染，失败消息 MUST 包含归一化结果。
- `path` 中的 `.` 与 `..` 段 MUST 被归一化消解，例如 `logs/./app` 输出为 `logs/app`，`a/../b` 输出为 `b`。
- `path` 为空白时 MUST NOT 进入归一化，直接按必填校验中断。

#### Scenario: 点段归一化

- **WHEN** `path` 为 `logs/./app.log`
- **THEN** 输出 `path: "logs/app.log"`

#### Scenario: 内部双点归一化

- **WHEN** `path` 为 `a/../b`
- **THEN** 输出 `path: "b"`

#### Scenario: 绝对路径

- **WHEN** `path` 为 `/etc/app.log`
- **THEN** 渲染中断，失败消息来自公共路径能力并标明不是相对路径

#### Scenario: 根目录逃逸

- **WHEN** `path` 为 `../app.log` 或 `..`
- **THEN** 渲染中断，失败消息包含归一化结果

#### Scenario: 归一化为当前目录

- **WHEN** `path` 为 `.` 或 `a/..`
- **THEN** 渲染中断，失败消息包含 `"."`

### Requirement: optional 只接受原生布尔值

系统 MUST 只接受原生布尔值作为 `optional`。

- `optional` 为字符串（包括 `"true"`、`"false"`）时中断渲染，失败消息 MUST 包含 `optional`。
- `optional` 为其他非布尔类型时中断渲染。

#### Scenario: 字符串布尔值

- **WHEN** `optional` 为字符串 `"true"`
- **THEN** 渲染中断，失败消息包含 `optional`

#### Scenario: 数字

- **WHEN** `optional` 为数字 `1`
- **THEN** 渲染中断，失败消息包含 `optional`

### Requirement: 父级必需段数修正

系统 MUST 使 `definitions.envVarSource` 的 `fileKeyRef` 字符串形态在少于三段时不再组装，以匹配 `volumeName`、`path`、`key` 同时必填。

- 段数不足时 MUST 不组装该字段并输出空内容，不中断渲染。

#### Scenario: 两段不再组装

- **WHEN** `definitions.envVarSource` 收到 `fileKeyRef: "env-vol app.log"`
- **THEN** 不组装该字段，输出空内容

#### Scenario: 三段可组装

- **WHEN** `definitions.envVarSource` 收到 `fileKeyRef: "env-vol app.log LOG_LEVEL"`
- **THEN** 组装为 `volumeName`、`path`、`key` 并委托本能力

#### Scenario: 四段含 optional

- **WHEN** `definitions.envVarSource` 收到 `fileKeyRef: "env-vol app.log LOG_LEVEL true"`
- **THEN** 组装四个字段并委托本能力；由于第 4 段为字符串 `"true"`，本能力中断

## 非目标

- 不渲染 `EnvVarSource` 的其他字段。
- 不实现 `definitions.envVarSource` 的分发逻辑。
- 不校验 `path` 归一化后指向的卷内文件是否真实存在。
- 不校验 `key` 的字符集与 128 字符上限。
- 不处理 `EnvFiles` 特性门禁。
- 不对 `path` 原文中的内部 `..` 段做额外检查，只接受归一化结果。
- 不在 `definitions.envVarSource` 层把字符串 `optional` 转换为布尔；该类型缺口由后续 change 处理。
