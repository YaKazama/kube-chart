---
change-id: fix-core-pod-spec-affinity
updated_at: "2026-11-07T11:28:00Z"
---

# 修复 core.podSpec 中 affinity 三个官方键的别名取值

## 目标

- 修复 `core.podSpec` 在处理 `affinity` 对象内部的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 时，`*Alias` 形式的取值没有被取到的问题。

## 需求

- 受影响位置：`core.podSpec` 中 `affinity` 对象内部的 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 三个键。
- 现状：`core.podSpec` 使用 `pick $_affinityParsed "nodeAffinity" "podAffinity" "podAntiAffinity"` 从 `affinity` 内取三个官方键；`pick` 是纯键名筛选、不经过 `base.get`，因此 `affinity.nodeAffinityAlias` 等内部别名键在进入合并前即被丢弃。
- 已验证的边界：同级 `nodeAffinityAlias` 等根上下文别名由已有的 `base.get` 读取，行为正常，不属于本次修复范围。
- 修复目标：`affinity` 内部的 `*Alias` 形式取值 MUST 与规范键等价参与合并，结果 MUST 与直接用规范键提供时一致。
- 归一化位置：别名归一化 MUST 在 `core.podSpec` 内完成，`definitions.affinity` 收到的对象 MUST 只包含规范键 `nodeAffinity`、`podAffinity`、`podAntiAffinity`，MUST NOT 包含任何 `*Alias` 键。
- 实现方式：对 `affinity` 解析结果逐键调用 `base.get` 读取三个官方键，由 `base.get` 完成别名优先与回退，再把非空结果写入 `$affinity`；不使用 `pick` 白名单。
- 合并规则不变：合并结果 MUST 以规范键 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 进入 `affinity`，`affinity` 内已存在的同名键 MUST 保留，同级字段 MUST NOT 覆盖。
- 本次修复不改变合并后的委托目标 `definitions.affinity`、传入上下文的规范键集合与失败边界。
- `affinity` 内部三个官方键的取值 MUST 为 map；非 map 时 MUST 中断渲染，错误信息 MUST 包含 `affinity.<字段名>`。修复前这些非法值被 `pick` 静默丢弃，修复后属于新增失败边界。
- 修复后的行为 MUST 与 `core.podSpec` 其他字段的别名语义保持一致，不引入新的特例。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 只修改 `templates/api-resources/Core/_PodSpec.tpl` 中 `core.podSpec` 处理 `affinity` 对象的取值逻辑。
- 不修改 `base.get` 的实现或别名能力，不在 `core.podSpec` 内自行实现别名优先逻辑。
- 不采用将 `*Alias` 键加入 `pick` 白名单并向下游透传的做法，避免把别名归一化责任推给 `definitions.affinity`。
- 不改变 `affinity` 字段本身的规范键取值语义、合并顺序与 `affinity` 内值优先规则。
- 不修改同级 `nodeAffinity`、`podAffinity`、`podAntiAffinity` 的既有取值路径及其别名行为。
- 不修改与 `affinity` 无关的其他 PodSpec 字段。
- 修改后文件保持单末尾换行且不引入冲突标记。

## 非目标

- 不扩展 `affinity` 可接受的短键（`node`、`pod`、`podAnti`）。
- 不改变 `definitions.affinity` 的调用契约、入参与返回边界。
- 不修改 `base.get` 的别名识别规则。
- 不对整 Chart 执行 `helm lint` 或发布检查。

## 验收

- 仅在 `affinity` 内以 `nodeAffinityAlias` 提供内容时，MUST 输出对应的规范键 `nodeAffinity`，结果与直接用 `nodeAffinity` 提供时一致。
- `podAffinityAlias`、`podAntiAffinityAlias` 同样适用上述等价性。
- 别名缺失或为空时，规范键保持原有行为。
- 别名与规范键同时存在于 `affinity` 内时，MUST 按 `base.get` 的别名优先规则取别名。
- 别名与同级字段同时存在，且 `affinity` 内已有同名键时，合并结果 MUST 仍取 `affinity` 内的值。
- 传给 `definitions.affinity` 的对象 MUST NOT 包含任何 `*Alias` 键。
- `affinity` 内部官方键为非 map 时 MUST 中断渲染，错误信息包含 `affinity.<字段名>`。
- 相关模板在 `/tmp/` 最小 application Chart 中的渲染结果覆盖别名命中、别名回退、别名优先与委托上下文无别名键四种情形。

## 开放问题

- 已关闭：别名所在位置已确认为 `affinity` 对象内部。同级别名由 `base.get` 正常处理；`affinity` 内部的 `pick` 白名单不含 `*Alias`，才是真实缺口。
- 已关闭：`openspec/specs/` 下仅有 `.gitkeep`，`core.podSpec` 当前无正式能力规格，本次无需同步既有规格。
