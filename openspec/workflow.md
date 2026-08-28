# kube-chart 精简 OPSX 工作流

本文件是制品、状态转换和共享门禁的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 共享边界

- 工作流只使用 `draft.md` 和 `spec.md` 两个活动制品，不生成 design、tasks、验证记录或同步记录。
- `draft.md` 在规格生成前保存用户意图；`spec.md` 生成后冻结 draft，并成为当前 change 的唯一执行契约。
- 用户明确写出或在当前命令中确认的内容优先于 AI 推断。当前规格、工程规则、参考资料和正式代码只能解析、约束或校验既定意图，不能反向增加需求。
- `spec.md` 的代码锚点是当前 change 可读取和修改的精确文件边界；路径必须由规格或已授权文件清单确认，不得使用目录、glob 或猜测路径。
- 状态只表示最近完成的稳定动作。等待确认、执行中、失败、局部修正或待用户决定是否回写不增加新状态，失败不得推进状态。
- `/opsx-fix` 可以产生用户明确要求的局部代码变化，但不能修改规格；当前代码与规格存在契约差异时，`/opsx-review` 必须停止。
- 完整 Chart 验证只属于 `/ck-deploy`；`/opsx-review` 不能把文件级轻量检查表述为发布验证通过。

## 目录与制品

```text
openspec/changes/<change-id>/
  draft.md                  用户初始意图
  spec.md                   当前 change 的规格、代码锚点与状态
```

活动 change 根目录只保留上述制品。归档 change 可以保留创建时采用的历史结构，不参与当前状态判断。

`draft.md` frontmatter 只包含：

```yaml
change-id: <kebab-case>
updated_at: "<UTC RFC 3339 时间>"
```

`spec.md` frontmatter 只包含：

```yaml
status: spec | code | reviewed
updated_at: "<UTC RFC 3339 时间>"
```

概念状态 `draft` 不写入 frontmatter；它由 `draft.md` 存在且 `spec.md` 不存在唯一确定。

## 状态与转换

| 状态 | 存储位置 | 含义 | 可执行动作 |
|---|---|---|---|
| `draft` | 文件存在性 | 只有 `draft.md`，意图仍在收集 | `/opsx-draft`、`/opsx-spec` |
| `spec` | `spec.md` frontmatter | 规格和代码锚点已锁定，尚未完成代码生成 | `/opsx-code` |
| `code` | `spec.md` frontmatter | 代码已生成，可以局部调整、受控回写或 Review | `/opsx-fix`、`/opsx-spec-rewrite`、`/opsx-review` |
| `reviewed` | 归档中的 `spec.md` frontmatter | 轻量核对已通过并完成归档 | 无 |

允许的转换：

```text
draft ──/opsx-spec──→ spec ──/opsx-code──→ code
code  ──/opsx-fix────────────────────────→ code
code  ──/opsx-spec-rewrite───────────────→ code
code  ──/opsx-review 成功──→ reviewed + archive
```

活动目录中出现 `status: reviewed` 只表示 Review 已更新状态但归档移动被中断；重新执行 `/opsx-review` 时必须再次完成轻量核对后续作归档。

## 动作门禁

- `/opsx-draft` 只在 `spec.md` 不存在时创建或更新 draft；spec 已存在时停止，避免双源分叉。
- `/opsx-spec` 必须先有 `draft.md`。它只创建一次 `spec.md`；目标、契约、验收或代码锚点不能唯一确定时不创建文件。
- `status: spec` 时，用户可以在执行 `/opsx-code` 前手工调整 `spec.md` 的代码锚点，并同步更新 `updated_at`。`/opsx-code` 成功后锚点锁定。
- `/opsx-code` 在 `spec.md` 缺失时必须输出警告并停止；只接受 `status: spec`，只按当前规格和锚点实施，全部完成后才写入 `status: code`。
- `/opsx-fix` 只接受 `status: code`，只修改锚点中的正式代码文件，不修改 draft、spec、用户文档或锚点范围。结束时必须输出修改摘要、`无需回写 | 必须回写` 的二值结论、精确回写建议和 Review 就绪结论。
- `/opsx-spec-rewrite` 只接受 `status: code`，且当前命令必须包含用户确认的精确回写内容。它只更新规格正文和 `updated_at`，保持 `status: code`；不得修改代码锚点、draft 或正式代码。
- `/opsx-review` 只读取 `spec.md` 和代码锚点中当前已变更的文件。代码与规格不一致、存在未确认回写或轻量检查失败时保持 `code`；全部通过后写入 `reviewed` 并归档。
- `/ck-deploy` 独立读取整个 Chart 所需的当前文件并执行真实发布检查，不依赖 Review 摘要替代实际命令。

如果用户拒绝 `/opsx-fix` 给出的必须回写建议，必须再次执行 `/opsx-fix` 把代码恢复为当前 spec 所定义的行为，之后才能 Review。

## 参数与时间

- change-id 是 `/opsx-*` 命令的必填参数，必须是 kebab-case，并精确对应 `openspec/changes/<change-id>/`。
- 正常执行直接访问确切路径，不扫描、模糊匹配、自动纠错或根据唯一活动 change 推断参数。
- 目标不存在或前置制品缺失时停止并报告确切缺口，不创建替代 change。
- `updated_at` 使用 UTC RFC 3339 时间；命令只在实际修改对应制品时更新时间。
