---
updated_at: "2026-11-07T10:14:30Z"
---

# 修正 YAML 恢复后重复的 kindIs 类型检查规格

## NO SPEC DELTA

本 change 只删除在 `base.isFromYamlError` 判定之后对同一 YAML 恢复结果重复执行的 `kindIs "map"` 判断，不改变任何用户可见行为。

受影响能力：

- `apps.deploymentSpec`：`strategy` 分支的 map 与字符串简写归一化结果、委托输入与失败消息保持不变。
- `base.labels`：自定义标签与 `helmLabels` 的合并结果、字段生效条件、空值保底与失败边界保持不变。

理由：`fromYaml` 成功即保证恢复结果为 map，错误 helper 已完全覆盖类型检查；删除的 `kindIs` 不参与任何取值、生效或失败判定。

## 非目标

- 不改变 `fromYaml`、`fromYamlArray`、`base.isFromYamlError`、`base.isFromYamlArrayError` 的能力与实现。
- 不改变 `apps.deploymentSpec` 与 `base.labels` 的输出字段、顺序、默认值与失败消息。
- 不修正与重复 `kindIs` 无关的代码风格问题。
