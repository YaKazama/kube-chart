# `/sdd-merge`

## 职责

检查既有验证证据，将已验证变更合并为当前规格、同步用户文档并归档；不新增实现行为，不重跑完整验证。

## 读取

- `draft.md` frontmatter、`plan/spec.md`、`records/approval.md`
- 按批准记录检查 `plan/design.md` 是否存在并计算普通 SHA-256；只核对摘要，不读取正文
- 必需的 `records/verification.md`
- 受影响的当前规格、正式实现、README、`docs/` 与样例
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/documentation.md`](../rules/documentation.md)

不读取其他归档 change；只有处理明确的规格冲突时才读取相关活动 change。

## 输出

- 将 `plan/spec.md` 合并到 `openspec/specs/<能力>/spec.md`。
- 同步受影响的 README、`docs/` 和稳定样例。
- 核对验证记录中的真实命令矩阵全部通过，且对应当前冻结契约和正式实现。
- 不执行 lint、测试、渲染、Scenario 或验证矩阵中的任何命令；证据缺失、失败、过期或无法对应当前冻结契约与正式实现时停止合并并保持 `verified`。
- 把 draft frontmatter `status` 更新为 `merged`，移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

只接受 `verified`，且必须有有效批准、当前正式实现和通过的验证记录。用户执行即确认人工 Review 已完成；AI 不得自行触发、跳过 `/sdd-verify`，或以本命令重跑验证代替既有证据。
