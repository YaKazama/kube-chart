---
updated_at: "2026-11-28T08:35:14Z"
---

# definitions.volumeProjection 规格

## Purpose

为 Kubernetes `VolumeProjection` 提供共享渲染能力，供 `definitions.projectedVolumeSource` 的 `sources` 条目委托使用。

## ADDED Requirements

### Requirement: 渲染 VolumeProjection 字段片段

系统 MUST 从原生 map 上下文读取恰好一个官方字段 `clusterTrustBundle`、`configMap`、`downwardAPI`、`podCertificate`、`secret` 或 `serviceAccountToken`，委托对应子模板渲染，并以该字段名为顶层键输出；其他输入字段不参与互斥判定。

#### Scenario: 单个字段委托渲染

- **WHEN** 输入恰好包含六个官方字段中的一个非空原生 map
- **THEN** 输出仅包含该字段键，字段名与官方定义一致
- **AND** 字段值由映射的子模板渲染，且输出为 map

#### Scenario: 字段数量非法

- **WHEN** 六个官方字段均未出现
- **THEN** 渲染中断并报错
- **WHEN** 两个及以上官方字段键出现
- **THEN** 渲染中断并报错

#### Scenario: 字段值或子模板输出非法

- **WHEN** 唯一出现的字段在取值后不是非空原生 map
- **THEN** 渲染中断并报错
- **AND** 子模板输出非法 YAML 或为空内容时同样中断

## 非目标

- 不创建 `definitions.clusterTrustBundleProjection`、`definitions.configMapProjection`、`definitions.downwardAPIProjection`、`definitions.podCertificateProjection`、`definitions.secretProjection`、`definitions.serviceAccountTokenProjection`，其字段识别、校验与渲染不属于本 change。
