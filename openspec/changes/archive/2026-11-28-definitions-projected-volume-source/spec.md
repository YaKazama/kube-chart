---
updated_at: "2026-11-28T08:05:53Z"
---

# definitions.projectedVolumeSource 规格

## Purpose

为 Kubernetes `Volume.projected` 提供 `ProjectedVolumeSource` 的共享渲染能力，供 `definitions.volume` 委托使用。

## ADDED Requirements

### Requirement: 渲染 ProjectedVolumeSource 字段片段

系统 MUST 从原生 map 上下文读取 `defaultMode` 与 `sources`，按官方字段顺序输出，并忽略其他输入字段。

#### Scenario: 渲染 defaultMode 与 sources

- **WHEN** 输入同时包含 `defaultMode` 与 `sources` 原生 map 条目
- **THEN** 先输出 `defaultMode`，再输出 `sources`
- **AND** `defaultMode` 接受八进制 `0000`–`0777` 或十进制 `0`–`511` 的数值或字符串，归一化为十进制整数输出；显式 `0` 有效
- **AND** 每个 `sources` 条目委托 `definitions.volumeProjection` 渲染；空渲染结果被剔除，完全相同的结果只保留首个，其余按输入顺序输出

#### Scenario: 可选字段为空

- **WHEN** `defaultMode` 缺省或为空字符串，或 `sources` 缺省、为空数组、全部条目渲染为空
- **THEN** 不输出对应键，渲染正常完成

#### Scenario: 非法输入中断

- **WHEN** `defaultMode` 不是合法文件模式，或 `sources` 不是数组，或任一条目不是原生 map
- **THEN** 渲染中断并报错
- **AND** `definitions.volumeProjection` 返回非法 YAML 时同样中断

## 非目标

- 不创建 `definitions.volumeProjection`，其字段识别、校验与渲染不属于本 change。
- 不处理 `defaultMode`、`sources` 之外的输入字段。
- 不修改 `definitions.volume` 对 `projected` 的既有委托关系。
