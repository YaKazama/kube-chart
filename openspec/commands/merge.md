# `/sdd-merge`

## 职责

检查既有验证证据，将已验证变更合并为当前规格、同步用户文档并归档；不新增实现行为，不重跑完整验证。

```text
/sdd-merge <change-id>
```

## 读取

### 固定读取

- `draft.md` frontmatter、`plan/spec.md`、`records/approval.md`
- 按批准记录检查 `plan/design.md` 是否存在并计算普通 SHA-256；只核对摘要，不读取正文
- 必需的 `records/verification.md`
- `plan/spec.md` 技术目标对应且真实存在的确切当前规格；新能力只确认其确切目标路径尚不存在
- 验证记录冻结范围列出的确切正式实现与直接依赖只用于计算普通 SHA-256；除同步用户文档所需的目标公开行为外，不读取实现正文
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)、[`../rules/documentation.md`](../rules/documentation.md)

### 条件读取

- 只有变更规格改变用户可见配置、示例或文档契约时，才按文档规则映射读取确切 README、`docs/` 或稳定样例；需要定位引用时，只在这些授权目录中搜索技术目标的确切名称，不通读全部文档。
- 只有发现与另一个活动 change 的同一技术目标冲突时，才读取该 change 的 draft frontmatter 与 `plan/spec.md` 的 `## 技术目标`；不得读取其余内容。
- 归档前只检查确切目标路径 `openspec/changes/archive/YYYY-MM-DD-<change-id>/` 是否冲突，不读取其他归档目录或文件。

### 禁止读取

- 不读取 `plan/design.md` 正文、其他归档 change、无关活动 change、未受影响的实现、文档与样例、参考资料或外部资源。
- 固定证据无法对应当前契约与实现时停止，不得扩大读取范围重建、补写或替代验证证据。

## 输出

- 将 `plan/spec.md` 合并到 `openspec/specs/<能力>/spec.md`。
- 同步受影响的 README、`docs/` 和稳定样例。
- 核对验证记录中的真实命令矩阵全部通过，且对应当前冻结契约和正式实现。
- 不执行 lint、测试、渲染、Scenario 或验证矩阵中的任何命令；证据缺失、失败、过期或无法对应当前冻结契约与正式实现时停止合并并保持 `verified`。
- 把 draft frontmatter `status` 更新为 `merged`，移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

只接受 `verified`，且必须有有效批准、当前正式实现和通过的验证记录。用户执行即确认人工 Review 已完成；AI 不得自行触发、跳过 `/sdd-verify`，或以本命令重跑验证代替既有证据。
