---
updated_at: "2026-11-19T16:28:17Z"
---

# definitions.containerResizePolicy 规格

## Purpose

新增命名模板 `definitions.containerResizePolicy`，把原生 map 或单行字符串解析并渲染为可嵌入 `containers[].resizePolicy` 的 `ContainerResizePolicy` YAML 字段片段，并使 `definitions.container` 的 `resizePolicy` 接受该简写。

## ADDED Requirements

### Requirement: 输入形态与位置解析

系统 MUST 接受 string 或 map 两种上下文，并 MUST 拒绝其他类型。string 上下文 MUST 形如 `resourceName [restartPolicy]`，分隔符 MUST 使用项目既有 `SPLIT.SPACE_COMMA` 的匹配范围，即逗号与空白可混用、连续分隔符合并为一个分隔符、两侧空白不产生额外段。拆分结果 MUST 按位置取值：第 1 段为 `resourceName`，第 2 段为 `restartPolicy`。

系统 MUST NOT 剔除拆分结果中的空段，空段按其位置参与后续必填与可选项判断。拆分结果多于 2 段时格式不合法，系统 MUST 中断渲染。

#### Scenario: 仅资源名

- **WHEN** string 上下文为 `cpu`
- **THEN** 解析出 `resourceName` 为 `cpu`，不解析 `restartPolicy`

#### Scenario: 逗号分隔

- **WHEN** string 上下文为 `cpu,NotRequired`
- **THEN** 解析出 `resourceName` 为 `cpu`、`restartPolicy` 为 `NotRequired`

#### Scenario: 空白分隔

- **WHEN** string 上下文为 `memory RestartContainer`
- **THEN** 解析出 `resourceName` 为 `memory`、`restartPolicy` 为 `RestartContainer`

#### Scenario: 连续分隔符与两侧空白

- **WHEN** string 上下文为 `  cpu,, NotRequired  `
- **THEN** 仍解析出 `resourceName` 为 `cpu`、`restartPolicy` 为 `NotRequired`

#### Scenario: 额外段

- **WHEN** string 上下文为 `cpu NotRequired extra`
- **THEN** 渲染中断

#### Scenario: 末段为空

- **WHEN** string 上下文为 `cpu,`
- **THEN** 第 2 段为空字符串，`restartPolicy` 按未提供处理，只输出 `resourceName`

#### Scenario: 首段为空

- **WHEN** string 上下文为 `,cpu`
- **THEN** 第 1 段为空字符串，`resourceName` 必填校验失败，渲染中断

#### Scenario: 非法上下文类型

- **WHEN** 上下文既不是 string 也不是 map
- **THEN** 渲染中断

### Requirement: map 上下文

系统 MUST 接受 map 上下文，只从其中读取 `resourceName`（必填）与 `restartPolicy`（可选）两个键。map 中其他键 MUST 不参与校验和输出，也 MUST NOT 导致中断。同级 `<键>Alias` MUST 按 `base.get` 的别名语义与规范键等效。

`resourceName` 缺失、为 null 或为空时 MUST 中断渲染；`restartPolicy` 缺失、为 null 或为空时 MUST 省略。

#### Scenario: map 完整输入

- **WHEN** 上下文为 `{resourceName: memory, restartPolicy: RestartContainer}`
- **THEN** 输出与等价 string 上下文一致

#### Scenario: map 忽略其他键

- **WHEN** 上下文为 `{resourceName: cpu, note: anything}`
- **THEN** 只输出 `resourceName`，不输出 `note`，也不中断

#### Scenario: map 缺少必填字段

- **WHEN** map 缺少 `resourceName`，或 `resourceName` 为 null、空字符串
- **THEN** 渲染中断

### Requirement: 字段类型与枚举校验

`resourceName` 与 `restartPolicy` MUST 为 string 类型，非 string 类型 MUST 中断渲染。

`resourceName` MUST 取值 `cpu` 或 `memory`，比较 MUST 大小写敏感；其他取值 MUST 中断渲染。

`restartPolicy` MUST 取值 `NotRequired` 或 `RestartContainer`，比较 MUST 大小写敏感；其他取值 MUST 中断渲染。

两个字段 MUST 以带引号字符串输出。

#### Scenario: 合法取值

- **WHEN** `resourceName` 为 `cpu` 或 `memory`，`restartPolicy` 为 `NotRequired` 或 `RestartContainer`
- **THEN** 校验通过并以带引号字符串输出

#### Scenario: resourceName 非法

- **WHEN** `resourceName` 为 `CPU`、`Memory`、`gpu`、`storage` 或非 string 类型
- **THEN** 渲染中断

#### Scenario: restartPolicy 非法

- **WHEN** `restartPolicy` 为 `notrequired`、`restartcontainer`、`Always` 或非 string 类型
- **THEN** 渲染中断

### Requirement: 输出字段与顺序

输出 MUST 只包含已解析出的字段，并按 `resourceName`、`restartPolicy` 的官方字段顺序渲染。未解析出 `restartPolicy` 时 MUST 不输出该字段，交由 API 默认值 `NotRequired` 生效。

#### Scenario: 最小输出

- **WHEN** string 上下文为 `cpu`
- **THEN** 输出只含 `resourceName: "cpu"`

#### Scenario: 完整输出

- **WHEN** string 上下文为 `memory,RestartContainer`
- **THEN** 输出依次为 `resourceName: "memory"`、`restartPolicy: "RestartContainer"`

### Requirement: definitions.container 的 resizePolicy 集成

`definitions.container` 的 `resizePolicy` MUST 接受 string 简写元素与 map 元素。两种元素 MUST 都按 `definitions.containerResizePolicy` 渲染，其他类型元素 MUST 中断渲染。

#### Scenario: 简写元素

- **WHEN** `resizePolicy` 为 `["cpu", "memory RestartContainer"]`
- **THEN** 渲染出两个完整 `ContainerResizePolicy` 字段片段

#### Scenario: 简写与 map 混用

- **WHEN** `resizePolicy` 为 `["cpu", {resourceName: memory, restartPolicy: RestartContainer}]`
- **THEN** 两项均渲染为 `ContainerResizePolicy` 字段片段，顺序与输入一致

#### Scenario: 非法元素类型

- **WHEN** `resizePolicy` 的元素既不是 string 也不是 map
- **THEN** 渲染中断

## 非目标

- 不新增 `definitions.containerResizePolicy` 与 `resizePolicy` 集成以外的模板或字段。
- 不校验 `resourceName` 在容器内是否重复。
- 不为 string 简写新增独立分隔符常量。
- 数组级去重与空项剔除由父模板负责，不在本模板职责内。
