# `/sdd-merge`

## 职责

检查既有验证证据，将已验证变更合并为当前规格、同步用户文档并归档；不新增实现行为，不重跑完整验证。

```text
/sdd-merge <change-id>
```

## 上下文

读取 `draft.md` frontmatter、`plan/spec.md`、`records/verification.md`、目标当前规格以及 [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md) 和 [`../rules/documentation.md`](../rules/documentation.md)。按验证范围核对契约、目标实现与直接依赖的摘要；用户可见行为变化时读取对应文档和稳定样例。证据无法对应当前内容时停止，不重建或补写证据。

## 输出

- 将 `plan/spec.md` 合并到 `openspec/specs/<能力>/spec.md`。
- 同步受影响的 README、`docs/` 和稳定样例。
- 核对验证记录中的真实命令全部通过，且对应当前契约和正式实现。
- 不执行 lint、测试、渲染或 Scenario；证据缺失、失败、过期或无法对应当前契约与正式实现时停止合并并保持 `verified`。
- 归档目标已存在时停止，不覆盖既有归档。
- 把 draft frontmatter `status` 更新为 `merged`，移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

只接受 `verified`，且必须有当前正式实现和通过的验证记录。用户执行即确认人工 Review 已完成；AI 不得自行触发、跳过 `/sdd-verify`，或以本命令重跑验证代替既有证据。
