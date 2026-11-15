---
updated_at: "2026-11-15T09:12:16Z"
---

# definitions.resourceClaim 模板规格

## Purpose

把父级清洗后的单个资源声明描述渲染为容器 `resources.claims` 数组元素，供 `definitions.resourceRequirements` 逐项委托。

## ADDED Requirements

### Requirement: 渲染单个 ResourceClaim 片段

系统 MUST 把入参 map 的 `name` 与 `request` 渲染为资源声明数组元素；输出 MUST 为可被父级按 map 解析的 YAML 片段；字段顺序 MUST 为 `name`、`request`；`request` 未设置时 MUST NOT 输出该字段；`name`、`request` 之外的入参键 MUST NOT 出现在输出中，也 MUST NOT 改变这两个字段的渲染结果。

#### Scenario: 仅设置 name

- **WHEN** 入参 map 含非空 `name` 且未设置 `request`
- **THEN** 输出仅含 `name` 的元素片段

#### Scenario: 同时设置 name 与 request

- **WHEN** 入参 map 含非空 `name` 与非空 `request`
- **THEN** 输出依 `name`、`request` 顺序排列的两个字段

#### Scenario: 入参含额外键

- **WHEN** 入参 map 含有 `name`、`request` 以外的键
- **THEN** 输出不含这些键，且 `name`、`request` 的渲染结果与不含额外键时一致

#### Scenario: 父级未配置资源声明

- **WHEN** 父级未配置该条资源声明
- **THEN** 父级不调用本模板，模板不产生任何输出

### Requirement: name 必填与失败边界

系统 MUST 在 `name` 缺失、为 `null` 或解码后仅含空白时中断渲染；`request` 解码后为空时 MUST 视为未设置而非失败；`name` MUST NOT 进行名称格式校验。

#### Scenario: name 缺失

- **WHEN** 入参 map 不含 `name`
- **THEN** 渲染中断并指出 `name` 为必填

#### Scenario: name 为空白

- **WHEN** `name` 解码后仅含空白字符
- **THEN** 渲染中断

#### Scenario: name 不符合 DNS 名称格式

- **WHEN** `name` 含不符合 Kubernetes 名称格式的字符
- **THEN** 模板仍正常渲染，不中断

#### Scenario: 字段为非字符串标量

- **WHEN** `name` 或 `request` 取值为数字、布尔等非字符串标量
- **THEN** 渲染中断

#### Scenario: request 解码后为空

- **WHEN** `request` 为 `null`、空字符串或仅含空白
- **THEN** 输出仅含 `name`，不中断

## 非目标

- 不校验 `name` 与 Pod `spec.resourceClaims` 条目的对应关系。
- 不实现 `resourceClaims` 数组循环、字符串简写解析、条目合并与去重；这些由调用方负责。
- 不输出 `status`、`apiVersion`、`kind`。
- 不提供默认值、入参清洗或地址格式转换。
