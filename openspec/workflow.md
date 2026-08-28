# kube-chart OPSX 工作流

本文件是制品、状态转换和共享门禁的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 共享边界

- 工作流使用 `draft.md`、`spec.md`、`design.md` 和 `tasks.md` 四个活动制品，不生成验证记录或同步记录。
- `draft.md` 保存用户意图；`spec.md` 只锁定可观察行为；`design.md` 锁定技术目标、实现决策、依赖契约和代码边界；`tasks.md` 锁定实施顺序与验证场景。
- `/opsx-spec` 在内存中生成 spec、design 和 tasks 候选，完成行为闭包、设计闭包和任务闭包检查后一次性创建三个制品；任一闭包失败时不得创建部分制品。
- spec、design 和 tasks 共同构成当前 change 的执行契约。三者生成后冻结 draft；正式代码、规则和参考资料只能解析、约束或校验既定意图，不能反向增加需求。
- `design.md` 的代码边界按精确文件记录 `read | write` 权限、operation 和 writable scope。`read` 只允许读取；`write` 同时允许读取，但只能修改声明的 writable scope。
- 历史聊天、旧摘要和旧工具输出不能替代当前制品、当前命令中的用户确认或本轮允许读取的当前工作区事实。
- 状态只表示最近完成的稳定动作。等待确认、执行中、失败、局部修正或待用户决定是否回写不增加新状态，失败不得推进状态。
- 完整 Chart 验证只属于 `/ck-deploy`；`/opsx-review` 不能把文件级轻量检查表述为发布验证通过。

## 目录与制品

```text
openspec/changes/<change-id>/
  draft.md                  用户初始意图
  spec.md                   可观察行为与状态
  design.md                 技术设计、依赖契约与代码边界
  tasks.md                  实施和验证任务
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

`design.md` 和 `tasks.md` 不使用 frontmatter。概念状态 `draft` 由只有 `draft.md`、且 spec、design 和 tasks 均不存在唯一确定。三个执行制品缺少任一文件都属于无效的部分制品，不得推断状态或自动补齐。

## 状态与转换

| 状态 | 存储位置 | 含义 | 可执行动作 |
|---|---|---|---|
| `draft` | 文件存在性 | 只有 `draft.md`，意图仍在收集 | `/opsx-draft`、`/opsx-spec` |
| `spec` | `spec.md` frontmatter | spec、design 和 tasks 已完成闭包检查并锁定 | `/opsx-code` |
| `code` | `spec.md` frontmatter | tasks 已完成，代码可以局部调整、受控回写或 Review | `/opsx-fix`、`/opsx-spec-rewrite`、`/opsx-review` |
| `reviewed` | 归档中的 `spec.md` frontmatter | 轻量核对已通过并完成归档 | 无 |

允许的转换：

```text
draft ──/opsx-spec──→ spec ──/opsx-code──→ code
code  ──/opsx-fix────────────────────────→ code
code  ──/opsx-spec-rewrite───────────────→ code
code  ──/opsx-review 成功──→ reviewed + archive
```

`/docs-usage` 是独立文档动作，不读取或改变活动 change 的状态，也不参与上述状态转换。

活动目录中出现 `status: reviewed` 只表示 Review 已更新状态但归档移动被中断；重新执行 `/opsx-review` 时必须再次完成本轮轻量核对后续作归档。

## 三类闭包

- 行为闭包：draft 中每项已确认意图都映射到 spec，spec 的每项 Requirement、Scenario、失败边界和非目标都有明确意图来源或适用工程规则，不含实现步骤。
- 设计闭包：spec 中每项行为都映射到 design 的技术目标、设计决策或依赖契约；每个依赖都有确定的 availability、入参、返回边界和来源路径，或明确标记为当前未实现且不在本 change 实现。
- 任务闭包：design 中每项 write operation 和验证设计都映射到 tasks；每个任务只引用 design 中的精确代码边界，不引入新的行为、设计选择或文件。

移除 draft、历史聊天和旧工具输出后，仅凭 spec、design、tasks、三者明确列出的当前文件及适用规则仍不能唯一完成代码时，闭包检查失败。

## 动作门禁

- `/opsx-draft` 只在 spec、design 和 tasks 均不存在时创建或更新 draft；任一执行制品已存在时停止，避免双源分叉。
- `/opsx-spec` 必须先有完整 draft。它只创建一次 spec、design 和 tasks；任一目标、行为、设计、依赖、代码边界、任务或验证不能唯一确定时不创建任何执行制品。
- `/opsx-code` 只接受完整的 `status: spec` 三制品契约；按 tasks 实施，只修改 design 中 `access: write` 的 writable scope，并只把已实际完成的 task checkbox 从 `[ ]` 改为 `[x]`。
- `/opsx-fix` 只接受 `status: code`，只在已锁定 write boundary 内局部调整代码，不修改四个变更制品。结束时必须输出修改摘要、`无需回写 | 必须回写` 的二值结论、精确回写建议和 Review 就绪结论。
- `/opsx-spec-rewrite` 只接受 `status: code` 和当前命令中用户确认的精确行为变化；只更新 spec。若变化会使 design 或 tasks 失效则停止，不得重新推理或修补它们。
- `/opsx-review` 读取 spec、design、tasks 和当前变更涉及的代码边界；代码、设计、任务或规格不一致，存在未完成 task、未确认回写或轻量检查失败时保持 `code`。
- `/ck-deploy` 独立读取整个 Chart 所需的当前文件并执行真实发布检查，不依赖 Review 摘要替代实际命令。
- `/docs-usage` 在存在 `status: spec | code` 或部分执行制品的活动 change 时停止，避免将未 Review 行为写入文档。

如果用户拒绝 `/opsx-fix` 给出的必须回写建议，必须再次执行 `/opsx-fix` 把代码恢复为当前 spec 所定义的行为，之后才能 Review。

## 参数与时间

- change-id 是 `/opsx-*` 命令的必填参数，必须是 kebab-case，并精确对应 `openspec/changes/<change-id>/`。
- 正常执行直接访问确切路径，不扫描、模糊匹配、自动纠错或根据唯一活动 change 推断参数。
- 目标不存在或前置制品缺失时停止并报告确切缺口，不创建替代 change。
- `updated_at` 使用 UTC RFC 3339 时间；命令只在实际修改对应制品时更新时间。
