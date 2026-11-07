---
updated_at: "2026-11-07T11:28:00Z"
---

# core.podSpec affinity 别名取值规格

## MODIFIED Requirements

### Requirement: affinity 合并与委托

系统 MUST 把 `affinity` 自身字段与同级的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 合并为同一个对象，同级字段 MUST 以对应同名键（`nodeAffinity`、`podAffinity`、`podAntiAffinity`）进入合并结果。

系统 MUST 识别 `affinity` 对象内部的 `nodeAffinityAlias`、`podAffinityAlias`、`podAntiAffinityAlias`，并在同一对象内优先使用非空别名；别名缺失、为空或为 `null` 时 MUST 回退对应规范键。

系统 MUST 把 `affinity` 内部识别到的别名归一化为对应规范键，传给 `definitions.affinity` 的对象 MUST 只包含 `nodeAffinity`、`podAffinity`、`podAntiAffinity`，MUST NOT 包含任何 `*Alias` 键。

`affinity` 内部三个官方键的取值 MUST 为 map；非 map 时 MUST 中断渲染并报错，错误信息 MUST 包含 `affinity.<字段名>` 以便定位。

合并时 `affinity` 内已存在的同名键 MUST 保留，同级字段 MUST NOT 覆盖同名键。

系统 MUST NOT 识别 `affinity` 内的 `node`、`pod`、`podAnti` 短键，也 MUST NOT 允许这些短键与 `affinity` 同级生效。

合并结果为空时 MUST 不渲染 `affinity`；非空时 MUST 委托 `definitions.affinity` 渲染，并向其传入合并后的对象。

#### Scenario: 内部别名归一化为规范键

- **WHEN** `affinity` 内只提供 `nodeAffinityAlias`，未提供 `nodeAffinity`
- **THEN** 输出包含 `affinity.nodeAffinity`，其内容与 `nodeAffinityAlias` 一致

#### Scenario: 三个官方键的别名等价

- **WHEN** `affinity` 内分别以 `nodeAffinityAlias`、`podAffinityAlias`、`podAntiAffinityAlias` 提供内容
- **THEN** 三者分别等效于以 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 提供

#### Scenario: 别名优先于规范键

- **WHEN** `affinity` 内同时提供 `nodeAffinityAlias` 与 `nodeAffinity`，且取值不同
- **THEN** 输出中的 `nodeAffinity` 取别名内容

#### Scenario: 别名缺失时回退规范键

- **WHEN** `affinity` 内只提供 `nodeAffinity`
- **THEN** 输出中的 `nodeAffinity` 取该值，行为与修复前一致

#### Scenario: 同级字段补缺

- **WHEN** `affinity` 包含 `podAntiAffinity`，同级 `nodeAffinity` 有效
- **THEN** 传给 `definitions.affinity` 的对象同时包含 `podAntiAffinity` 与 `nodeAffinity`

#### Scenario: affinity 优先

- **WHEN** `affinity` 内已有 `nodeAffinity`，同时存在同级 `nodeAffinity`
- **THEN** 合并结果中的 `nodeAffinity` 取 `affinity` 内的值

#### Scenario: 委托上下文不含别名键

- **WHEN** `affinity` 内以任一 `*Alias` 形式提供内容并成功合并
- **THEN** 传给 `definitions.affinity` 的对象不包含任何 `*Alias` 键

#### Scenario: 内部键非 map 时中断

- **WHEN** `affinity.nodeAffinity` 或其别名取值为非 map 类型
- **THEN** 渲染中断，错误信息包含 `affinity.nodeAffinity`

#### Scenario: 短键不生效

- **WHEN** `affinity` 内或同级只提供 `node`、`pod`、`podAnti`
- **THEN** 这些短键不参与合并，合并结果按其余有效内容渲染

#### Scenario: 合并结果为空

- **WHEN** `affinity` 与三个同级字段均缺失或为空
- **THEN** 输出不包含 `affinity`

## 非目标

- 不改变同级 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 及其根上下文别名的既有取值行为。
- 不扩展 `affinity` 可接受的 `node`、`pod`、`podAnti` 短键。
- 不改变 `definitions.affinity` 的调用契约、入参与返回边界。
- 不修改 `base.get` 的别名识别规则。
