# `/sdd-merge`

## 职责

只将已完成变更合并为当前规格、同步用户文档并归档，不新增实现行为。

## 读取

- `draft.md` frontmatter、`plan/spec.md`、`records/approval.md`
- 按批准记录检查 `plan/design.md` 的存在性并计算普通 SHA-256；只核对摘要，不读取正文
- 读取必需的 `records/verification.md`
- 受影响的当前规格、正式实现、README、`docs/` 与样例
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/documentation.md`](../rules/documentation.md)

不读取其他归档 change；只有处理明确的规格冲突时才读取相关活动 change。

## 输出

- 合并 `plan/spec.md` 到 `openspec/specs/<能力>/spec.md`。
- 同步受影响的 README、`docs/` 和稳定样例。
- 核对 `records/verification.md` 中记录的真实命令矩阵全部通过，且对应当前冻结契约和正式实现。
- 把 draft frontmatter `status` 更新为 `merged`，移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

只接受 `status: verified`。必须有有效批准、当前正式实现和通过的 `records/verification.md`；用户执行本命令即确认人工 Review 已完成，AI 不得自行触发，也不得跳过 `/sdd-verify`。
