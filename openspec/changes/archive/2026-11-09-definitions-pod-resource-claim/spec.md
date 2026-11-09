---
updated_at: "2026-11-09T14:24:14Z"
---

# definitions.podResourceClaim 模板规格

## Purpose

新增 `definitions.podResourceClaim`，把父级传入的单个 resourceClaim 上下文渲染为 Kubernetes `PodResourceClaim` 条目。

## ADDED Requirements

### Requirement: Pod resourceClaim 条目渲染

系统 MUST 依据父级传入的上下文渲染单条 `PodResourceClaim` 条目，输出只包含 `name` 与恰一个引用字段，字段顺序为 `name`、`resourceClaimName`、`resourceClaimTemplateName`，字段值为去除首尾空白后的传入字符串。

#### Scenario: 仅设置 resourceClaimName

- **WHEN** 父级传入非空 `name`，且仅设置 `resourceClaimName`
- **THEN** 输出按 API 顺序包含 `name` 与 `resourceClaimName`，不含 `resourceClaimTemplateName`

#### Scenario: 仅设置 resourceClaimTemplateName

- **WHEN** 父级传入非空 `name`，且仅设置 `resourceClaimTemplateName`
- **THEN** 输出按 API 顺序包含 `name` 与 `resourceClaimTemplateName`，不含 `resourceClaimName`

#### Scenario: name 未设置时中断

- **WHEN** `name` 缺失、为 `null`、为空字符串或仅空白
- **THEN** 渲染中断，并出现定位到 `name` 的失败消息

#### Scenario: 两个引用字段均未设置时中断

- **WHEN** `resourceClaimName` 与 `resourceClaimTemplateName` 均未设置（缺失、`null`、空字符串或仅空白）
- **THEN** 渲染中断，并出现定位到两个引用字段的失败消息

#### Scenario: 两个引用字段同时设置时中断

- **WHEN** `resourceClaimName` 与 `resourceClaimTemplateName` 都设置为非空值
- **THEN** 渲染中断，并出现定位到两个引用字段的失败消息

#### Scenario: 非 string 类型中断

- **WHEN** 任一字段存在且不是 string 类型
- **THEN** 渲染中断，并出现定位到该字段的失败消息

## 非目标

- 不校验 `resourceClaimName` 与 `resourceClaimTemplateName` 的名称格式。
- 不处理 `resourceClaims` 数组的循环、字符串简写拆分、条目合并与去重；这些由父级负责。
- 不修改父级 `core.podSpec` 的 `resourceClaims` 接入或其他模板。
- 不输出 `status` 或 `PodResourceClaim` 以外的字段。
