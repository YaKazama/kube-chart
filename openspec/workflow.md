# kube-chart SDD 工作流

本文件是 `/sdd-*` 与 `/ck-deploy` 的唯一流程定义。目标是保留 OpenSpec 的冻结、验证和归档门禁，同时让用户只维护一份直观输入。

## 核心原则

- `openspec/changes/<change-id>/proposal.md` 是草案阶段唯一用户入口，正文固定为“目标、需求、约束”。
- “约束”只保存用户明确指定的本次变更特殊限制；用户未指定时保持空白。AI 从项目上下文得到的通用约束只进入生成产物。
- 参考资料由 AI 自动从 `AGENTS.md`、适用 OpenSpec 规则、当前规格、目标代码和官方资料获取；用户不维护“参考”字段。
- 用户可以直接修改 proposal，也可以在会话中描述，由 AI 代写并同步其他文件。
- `specs/*/spec.md` 与 `artifacts/` 中的文件是 AI 产物，不要求用户修改，也不得重复维护完整用户输入。
- `artifacts/verification.md` 不是草案或探索产物，只能在正式实现完成后的 `/sdd-verify` 阶段根据实际代码和真实子模板创建。
- 模板按父到子、自顶向下设计和实现；缺失子模板使用 proposal 中的 checkbox 占位，不改走自底向上。
- 当前规格与已批准变更规格优先于 design、tasks 和代码；客观的 Kubernetes 或 Helm 约束冲突时进入修订，不能按现有代码反写规格。

## 流程与目录

```text
/sdd-new → /sdd-approve → /sdd-apply → /sdd-verify
                                        ↓
                                  人工 Review
                                        ↓
                                    /sdd-spec
```

```text
openspec/changes/<change-id>/
  proposal.md                 用户入口：目标、需求、约束
  specs/<能力名>/spec.md      AI 同步的行为与场景
  artifacts/                  AI 过程产物，用户无需修改
    design.md                 重要技术决策，按需创建
    tasks.md                  执行与门禁清单
    approval.md               批准状态与冻结摘要
    verification.md           实施完成后由 /sdd-verify 创建的实际验证记录
```

change 根目录只允许 `proposal.md` 与分类目录；design、tasks、approval 和 verification 不得与用户入口处于同一层级。
这是本项目的固定布局；即使外部 OpenSpec 默认把 design 或 tasks 放在 change 根目录，AI 也必须以本文件为准写入 `artifacts/`。

| 状态 | 允许 | 禁止 |
|---|---|---|
| 草案 | 修改 proposal，执行 `/sdd-new` 同步 | 修改正式代码 |
| 已批准或实施中 | 按冻结规格实施和验证 | 直接修改 proposal 或变更规格 |
| 已验证 | 人工 Review | 跳过 Review 归档 |
| 已完成 | 读取当前规格、执行发布检查 | 把归档材料当作当前契约 |

## 1. `/sdd-new`：建立或继续草案

### 命令与目标

```text
/sdd-new <change-id> <主要能力名> <define名称=目标tpl文件>...
```

- `change-id` 必须是 kebab-case。
- 主要能力名是稳定行为领域，对应 `specs/<能力名>/spec.md`。
- 至少提供一个目标；以第一个 `=` 分隔完整 define 名称和工作区相对 tpl 路径。
- 路径必须位于 `templates/`，文件名以 `_` 开头并以 `.tpl` 结尾；命名空间、API 组目录和文件名必须一致。
- 新 define 必须检查 Helm 全局命名空间重名；目标不得与其他活动变更冲突。
- 参数非法时立即停止，不创建或覆盖 change。

继续未批准草案时，change-id 和主要能力必须一致。已有确认目标不得被静默删除或改写；新映射可以确认占位或追加目标。用户明确要求替换时直接修改对应 proposal 行，由 Git 保留历史，不在正文堆叠审计日志。

### proposal 格式

目标校验通过后立即创建或更新 proposal：

```markdown
# <变更名称>

- 状态：草案
- change-id：`<id>`
- 主要能力：`<能力>`
- 命名模板：`<define 名称>`
- 存放路径：`<工作区相对 tpl 路径>`

修改方法：编辑下面三节，或在会话中直接说明。

## 目标

- [x] `[稳定编号]` `define=tpl路径`
- [ ] `[稳定编号]` `<父字段>` 子模板：`define=预计tpl路径`（占位，可修改或勾选）

## 需求

直白描述输入、输出、必填、默认值和失败行为。

## 约束

只填写用户明确指定的本次变更特殊限制；没有则留空。AI 不得预填项目通用规则或推导约束。
```

顶部摘要必须按 `/sdd-new` 的输入顺序列出命名模板及其存放路径；存在多个目标时成对重复“命名模板、存放路径”，不得只显示名称、文件名或无法对应的两组列表。“目标”节仍保存带稳定编号的完整映射及后续发现的子模板占位。

proposal 不保存长篇基线、受影响能力表、方案比较、成功标准副本、任务或验证记录。

### AI 同步

AI 每次执行 `/sdd-new`：

1. 自动读取 `AGENTS.md`、proposal、当前规格、目标代码、适用规则、官方资料和已有 AI 产物；需要时查阅 Git 历史，不要求用户整理参考。
2. 将会话中的用户输入合并进 proposal；“约束”只能写入用户明确表达的限制，不得自动生成。
3. 把“需求”同步成 Requirement 与 WHEN/THEN Scenario；新能力使用 ADDED，修改现有能力使用完整 MODIFIED Requirement。
4. 根据项目上下文把版本、分层、类型、安全、兼容性和实现边界补充到 spec 或简短 design，不回写 proposal “约束”。
5. 生成简短 tasks，自动补充适用检查，覆盖目标确认、批准、父到子实施、验证、Review、文档和归档。
6. 对 Helm 或 Kubernetes 客观行为的不确定性按需在 `/tmp/` 探索；影响实现的结论进入简短 design，临时资产完成后清理，不把探索结果当作正式验证。

AI 产物首行必须指向 proposal 作为修改入口。用户输入变化后重新同步；不得要求用户跨文件修改。design、tasks、approval 和 verification 必须写入 `artifacts/`，不得回到 change 根目录。

### 子模板占位

父模板行为明确、子模板尚未确认时，在 proposal “目标”添加一行 `[ ]` 占位。完整定义只保留在这一行；spec、design 和 tasks 只引用稳定编号。

- 父规格只描述真实的委托、上下文隔离、最小返回契约和父级失败收口，不替子模板虚构字段行为。
- 正式 `templates/` 不得创建空值或假数据占位 define。
- 用户勾选该行、在会话中确认编号，或通过后续 `/sdd-new` 提供同一映射后，AI 展开该子模板并继续发现下一层占位。
- 占位不会触发架构选择，也不会阻止父级规格、设计、任务和探索完成。

### `/sdd-new` 停止状态

- 顶层行为仍不明确：在 proposal “需求”留下具体 `[待补充]`，停止，不创建虚构 Requirement。
- 存在子模板占位：完成全部父级 AI 产物后，报告需要修改的 proposal 编号，状态保持草案。
- 需要独立设计 Review：完成 design 后报告 Review 点，状态保持草案。
- 没有 `[待补充]`、未勾选占位或设计 Review：报告“可批准”。

AI 不得自行批准或在 `/sdd-new` 修改正式代码。

## 2. `/sdd-approve`：冻结行为

只能由用户明确触发。批准前确认：

- proposal 的目标和需求明确，目标没有未勾选占位，需求没有 `[待补充]`；约束允许为空。
- 每个 Requirement 至少有一个可验证 Scenario。
- proposal、全部变更规格、design 和 tasks 一致。
- tasks 覆盖实施、验证、Review、文档和归档。

`artifacts/approval.md` 记录状态、ISO 8601 时间、用户命令，并保存 proposal 与全部变更规格的 SHA-256。冻结后需求变化必须执行 `/sdd-revise`。

## 3. `/sdd-apply` 与 `/sdd-revise`

`/sdd-apply` 先核对 approval 和冻结摘要，再按 tasks 从父模板到子模板实施：

- 只能创建或修改已批准目标映射中的 define 和 tpl 文件。
- 父模板可以先写出已批准的子模板 include；子模板完成前不以替身结果判定父模板通过验证。
- 每级完成后执行当前能够执行的开发检查；完整渲染验证等待真实子模板实现完成。
- 发现代码不符合规格时修代码；不按代码回写规格。

新增需求、条件、目标或外部约束时执行 `/sdd-revise`：将批准标记为“需重新批准”，在 proposal 三节中修改用户输入，由 AI 重新同步规格、design 和 tasks；重新批准前停止受影响实施。

## 4. `/sdd-verify`：验证

最终验证以冻结规格为预期，至少包括：

- OpenSpec 严格校验。
- `/opt/homebrew/bin/helm lint`。
- 最小有效、较完整有效和全部关键失败 Scenario。
- 受影响公共能力回归。
- 使用真实子模板的完整渲染；不得依赖测试替身或残留未解析占位。

`/sdd-verify` 只能在有效批准存在、正式目标全部实现、真实子模板可用且实施任务完成后执行。它根据当次实际检查创建或更新 `artifacts/verification.md`，记录环境、输入、命令、预期、实际和状态；不得写入草案推断、临时候选代码结果或测试替身结果。

验证结果同时直接报告给用户。全部通过时勾选 `artifacts/tasks.md` 中对应验证任务；有失败或偏差时保留实际结果，但不得标记任务完成或进入归档。

## 5. 人工 Review 与 `/sdd-spec`

`/sdd-spec` 前必须满足：冻结摘要匹配、tasks 完成、`artifacts/verification.md` 来自当前正式实现且无失败或偏差、无占位、人工 Review 完成、代码与全部材料一致；并重新执行关键验证，不能只根据已勾选任务推断当前结果。

通过后：

1. 将 ADDED、MODIFIED、REMOVED、RENAMED 合并到 `openspec/specs/<能力名>/spec.md`。
2. 当前规格只保留已实现、已验证的行为契约。
3. 同步 README、`docs/`、样例和适用通用规则。
4. 重新执行 OpenSpec、文档链接和适用发布检查。
5. 移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

## 6. 其他命令

- `/sdd-rewrite <能力名>`：只整理当前规格表达，不改变行为；发现实现不一致时停止。
- `/ck-deploy`：执行 `openspec/checks/release.md`，不创建、批准、实施或归档 change。

只有一个活动 change 时，除 `/sdd-new` 外的 change 命令可以省略 change-id；存在多个时必须显式指定，AI 不得猜测。
