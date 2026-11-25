---
change-id: definitions-ephemeral-volume-source
updated_at: "2026-11-25T16:42:15Z"
---

# `definitions.ephemeralVolumeSource`

## 目标

- 新增 `definitions.ephemeralVolumeSource`，把原生 map 渲染为 EphemeralVolumeSource 字段片段。

## 需求

- 上下文为原生 map，键值直接来自 values。
- `ephemeral` 与 `projected` 只接受原生 map；该约束已在父模板 `definitions.volume` 中说明。
- `ephemeral` 源在 volume 中可选，其值可以声明为空 map。
- 声明 `ephemeral` 时，`volumeClaimTemplate` 必填。
- `volumeClaimTemplate` 必须能恢复为非空 map；无法恢复为 map 或为空 map 时中断报错。
- `volumeClaimTemplate` 通过 include 调用 `definitions.persistentVolumeClaimTemplate`。
- 该子模板在本 change 只占位、不创建；子模板返回空内容时不输出 `volumeClaimTemplate` 字段。
- 未声明的键静默忽略。
- 子模板返回空内容时整体输出为空视为正确，不做额外校验或提示。
- 模板只输出当前层字段，不输出 `ephemeral` 父键。

## 期望输入格式

- 原生 map：字段与 EphemeralVolumeSource 同名，直接来自 values。

## 约束

- 本 change 的模板必须实际实现，不能是空占位。
- 上下文为 map 的类型前提由父模板保证。

## 非目标

- 不接受字符串简写。
- 不处理父模板清洗后的 map。
- 不实现 `definitions.persistentVolumeClaimTemplate`。

## 验收

- 原生 map 上下文能进入本模板渲染。
- `ephemeral` 为空 map 或缺少 `volumeClaimTemplate` 时渲染中断并报错。
- `volumeClaimTemplate` 为非 map 或空 map 时渲染中断并报错。
- 未声明的键被静默忽略，不进入输出。
- 提供合法 `volumeClaimTemplate` 时委托子模板；占位期间输出为空且视为正确。
- 输出中不出现 `ephemeral` 父键。

## 开放问题

- 当前无阻塞性开放问题。
