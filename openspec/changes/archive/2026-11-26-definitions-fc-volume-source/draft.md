---
change-id: definitions-fc-volume-source
updated_at: "2026-11-26T15:07:10Z"
---

# definitions.fcVolumeSource

## 目标

- 提供 `definitions.fcVolumeSource`，用于生成 Pod 卷的 Fibre Channel 卷源定义。
- 调整 `definitions.volume` 中 `fc` 字符串的清洗逻辑，使清洗后的上下文满足本模板的类型契约。

## 需求

- 上下文是原生 map 或由父模板清洗后的 map。
- 所有字段可选，但受以下组合约束。
- `targetWWNs` 与 `wwids` 互斥，且 `targetWWNs` 优先。
- `targetWWNs` 与 `lun` 必须整组出现，不允许只出现其一。
- `targetWWNs` 与 `wwids` 都缺失时，渲染中断并报错。
- `wwids` 分支出现时，`lun` 不渲染。
- `fsType` 枚举值只有 `ext4`、`xfs`、`ntfs`，取其他值视为非法并中断报错。
- 非法组合一律中断报错，不输出残缺的卷源定义。
- `definitions.volume` 的 `fc` 字符串分支 MUST 将 `lun` 以原生整数写入上下文，不得以字符串传递。
- `definitions.volume` 的 `fc` 清洗契约 MUST 显式说明：`lun` 仅在 `targetWWNs` 出现时写入；`targetWWNs` 缺 `lun` 时由 `definitions.fcVolumeSource` 中断；`wwids` 分支忽略 `lun`。
- 父模板 MUST NOT 重复实现 `targetWWNs` 与 `lun` 的组合校验。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 非目标

## 验收

- `targetWWNs` 与 `wwids` 同时存在时，输出只包含 `targetWWNs` 分支。
- `targetWWNs` 与 `lun` 只出现其一，或 `targetWWNs` 与 `wwids` 都缺失时，渲染中断并报错。
- `wwids` 分支出现时，输出不含 `lun`。
- `fsType` 取值只能为 `ext4`、`xfs` 或 `ntfs`，取其他值时渲染中断并报错。
- `fc: "0 xfs targetWWNs (10:20:30:40:50:60:70:80) wwids (0x5001)"` 经 `definitions.volume` 渲染成功，并与等价原生 map 的输出一致。
- `_Volume.tpl` 的 `fc` 契约注释与 `definitions.volume` 规格条目均显式包含上述三条组合边界。

## 开放问题
