---
updated_at: "2026-11-21T15:29:31Z"
---

# 新增 definitions.volumeDevice 模板规格

## Purpose

为 Container 的 `volumeDevices` 字段提供单个 VolumeDevice 渲染能力，支持 map 与 `<name> <devicePath>` string 简写，并由父级完成归一化、去空与去重。

## ADDED Requirements

### Requirement: VolumeDevice 字段渲染

系统 MUST 将单个 VolumeDevice 渲染为 `devicePath`、`name` 顺序的 YAML 字段片段，两个字段均为 string。

#### Scenario: map 输入

- **WHEN** 输入为包含 `name` 与 `devicePath` 的 map
- **THEN** 输出先 `devicePath` 后 `name`

#### Scenario: 绝对路径归一化

- **WHEN** `devicePath` 为包含 `.` 或 `..` 段的绝对路径
- **THEN** 输出归一化后的绝对路径

#### Scenario: 相对路径失败

- **WHEN** `devicePath` 不是绝对路径
- **THEN** 渲染中断并报告非绝对路径错误

#### Scenario: 非 string 字段值

- **WHEN** `name` 或 `devicePath` 为数字、布尔等非 string 标量
- **THEN** 渲染中断并报告类型错误

### Requirement: VolumeDevice 字符串简写

系统 MUST 接受 `<name> <devicePath>` 形式的 string，分隔符为空格和逗号，允许连续出现与混用，解析前忽略首尾空白。

#### Scenario: 空格、逗号与混合分隔

- **WHEN** string 为 `"data /dev/xvda"`、`"data, /dev/xvda"` 或 `"data , /dev/xvda"`
- **THEN** 解析为 `name: data` 与 `devicePath: /dev/xvda` 并按字段顺序输出

#### Scenario: 首尾与连续分隔符

- **WHEN** string 前后或中间存在一个或多个空格或逗号
- **THEN** 空段被忽略，仍按最多两个非空段提取

#### Scenario: 仅分隔符

- **WHEN** string 为空或仅由空格和逗号组成
- **THEN** 不输出任何字段

#### Scenario: 单字段缺失

- **WHEN** string 只有一个非空段，或 map 只包含 `name` 与 `devicePath` 之一，或其中一个为空且另一个非空
- **THEN** 渲染中断并报告必填字段缺失

#### Scenario: 两个以上非空段

- **WHEN** string 包含超过两个非空段
- **THEN** 渲染中断并报告格式错误

### Requirement: name 校验

系统 MUST 使用 RFC1123 Label 校验 `name`，最长 63 字符。

#### Scenario: 合法名称

- **WHEN** `name` 由小写字母、数字和中间连字符组成且不超过 63 字符
- **THEN** 正常输出

#### Scenario: 非法名称

- **WHEN** `name` 为空、包含大写字母或下划线、以连字符开头或结尾，或超过 63 字符
- **THEN** 渲染中断并报告 RFC1123 Label 错误

### Requirement: volumeDevices 数组归一化、去空与去重

系统 MUST 支持 `volumeDevices` 数组元素为 map 或 string，并在父级把 string 归一化为 map、剔除空结果、按渲染结果整项去重。

#### Scenario: string array 与混合数组

- **WHEN** `volumeDevices` 为 string、map 或两者混合的数组
- **THEN** 每个有效元素按相同规则渲染

#### Scenario: 去空

- **WHEN** 数组元素为空 map、空 string 或仅分隔符 string
- **THEN** 该项被剔除，其他项继续输出

#### Scenario: 完全重复项

- **WHEN** 两个元素渲染结果完全相同，或 string 与等价 map 产生相同结果
- **THEN** 只保留首个，数组只输出一项

#### Scenario: 非完全重复项

- **WHEN** 两个元素仅 `name` 或 `devicePath` 不同
- **THEN** 两项均保留，冲突交给 Kubernetes 处理

#### Scenario: 全部为空

- **WHEN** 所有元素均为空
- **THEN** 不输出 `volumeDevices` 字段

#### Scenario: 非数组

- **WHEN** `volumeDevices` 不是数组
- **THEN** 渲染中断并报告数组类型错误

#### Scenario: 非法元素类型

- **WHEN** 数组元素既不是 map 也不是 string
- **THEN** 渲染中断并报告元素类型错误

### Requirement: 直接调用 volumeDevice

系统 MUST 允许直接以 map 或 string 调用 `definitions.volumeDevice`，其字段值与输出顺序与父级数组中的单个元素一致。

#### Scenario: 直接 map 与 string

- **WHEN** 以等价 map 和 string 直接调用
- **THEN** 两者输出相同

#### Scenario: 直接空输入

- **WHEN** 直接以空 map、空 string 或仅分隔符 string 调用
- **THEN** 输出为空

#### Scenario: 非法上下文类型

- **WHEN** 直接调用时上下文不是 map 或 string
- **THEN** 渲染中断并报告类型错误

#### Scenario: map 别名

- **WHEN** map 含 `nameAlias` 或 `devicePathAlias`
- **THEN** 按既有别名规则优先于规范键

## 非目标

- 不按 `devicePath` 合并或覆盖重复项；非完全重复的冲突交给 Kubernetes。
- 不改变 `volumeDevices` 之外的 Container 字段行为。
