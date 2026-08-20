# kube-chart SDD 工作流

本文件是开发流程和快捷命令语义的唯一来源。它保留原 SDD 的人工确认、验证证据和正式化门禁，同时使用 OpenSpec 的当前规格、变更规格和归档目录。

相关入口：[`OpenSpec 导航`](README.md) · [`规格与文档规则`](rules/documentation.md) · [`开发检查`](checks/development.md) · [`发布检查`](checks/release.md)

## 核心模型

```text
当前规格 + 已批准的变更规格 → 候选代码 → 验证 → 新的当前规格
```

- [`openspec/specs/`](specs/)：当前已经实现、验证和确认的行为契约。
- [`openspec/changes/<change-id>/`](changes/)：尚未成为当前事实的变更材料。
- [`templates/`](../templates/)：对规格的候选实现，不是修改规格的依据。
- [`openspec/changes/archive/`](changes/archive/)：完成变更的历史；未完成或未验证的工作不得进入。

批准后的约束优先级：

```text
当前规格 + 已批准的变更规格 > design.md > tasks.md > 代码
```

Kubernetes 或 Helm 的客观行为与规格冲突时，停止实现并进入规格修订，不能用现有代码自动改写规格。

## 变更目录

```text
openspec/changes/<change-id>/
  proposal.md                 变更原因、范围和影响
  specs/<能力名>/spec.md      本次新增、修改、删除或改名的行为
  design.md                   重要技术决策，按风险创建
  tasks.md                    实施与验证清单
  approval.md                 人工批准及冻结文件摘要
  verification.md             实际执行的环境、命令和结果
```

纯重构、工具或文档变更可以没有变更规格，但必须在 `.openspec.yaml` 设置 `skip_specs: true`。

## 主流程

```text
/sdd-new
    ↓
批准前准备：proposal + 变更规格 + 按需探索和设计 + tasks
    ↓
/sdd-approve
    ↓
/sdd-apply
    ↓
/sdd-verify
    ↓
人工 Review
    ↓
/sdd-spec → 合并当前规格、同步用户文档并归档
```

`/sdd-new` 可以新建或继续未批准草案，自动推进到“可批准”或明确的停止条件。草案阶段允许反复修改；`/sdd-approve` 是行为契约冻结点。批准后需要改变需求时必须执行 `/sdd-revise`，不能直接修改变更规格。

判断下一步时只看当前状态：

| 当前状态 | 可以做什么 | 不可以做什么 |
|---|---|---|
| 草案 | 执行 `/sdd-new` 完成批准前准备，Review 或调整草案 | 修改正式代码 |
| 已批准 | 按冻结规格实现 | 直接改 proposal 或变更规格 |
| 实施中 | 修复不符合规格的代码，补充不改变行为的任务细节 | 用现有代码反向修改规格 |
| 已验证 | 人工 Review，处理发现的问题 | 跳过 Review 直接归档 |
| 已完成 | 读取或整理当前规格，执行发布检查 | 把归档材料当作当前契约 |

## 快捷命令

这些命令是发送给 AI 的会话触发命令，不是 shell 命令。

| 命令 | 读取 | 写入或执行 | 停止条件 |
|---|---|---|---|
| `/sdd-new <change-id> [能力名]` | 当前规格、目标代码、适用规则、已有未批准草案 | proposal、变更规格、按需探索和 design、tasks | 存在未决用户选择或需要独立设计 Review 时提前停止；否则准备至可批准，不修改正式代码 |
| `/sdd-approve [change-id]` | proposal、变更规格、design、tasks | 创建或更新 `approval.md`，冻结 proposal 与变更规格 | 只能由用户明确触发；AI 不得自行批准 |
| `/sdd-apply [change-id]` | 全部变更材料、当前规格、实现规则 | 修改代码、勾选 tasks、执行开发检查并记录证据 | 批准缺失、摘要不匹配或出现规格问题时停止 |
| `/sdd-revise [change-id]` | 已批准材料、新条件或新需求 | 使批准失效，记录原因，修订 proposal、变更规格和任务 | 返回 `/sdd-approve` 前停止，不继续写代码 |
| `/sdd-verify [change-id]` | 已批准规格、代码、tasks | OpenSpec、Helm 和场景验证；更新 `verification.md` | 有失败或偏差时不得进入归档 |
| `/sdd-spec [change-id]` | 批准、验证、Review 结果 | 合并当前规格、同步用户文档、校验并移动到 archive | 任一正式化门禁未满足时停止 |
| `/sdd-rewrite <能力名>` | 当前规格；代码和证据只用于一致性检查 | 只整理表达 | 不得改变 Requirement 语义；发现不一致时停止 |
| `/ck-deploy` | 整个 Chart | 执行 [`openspec/checks/release.md`](checks/release.md) | 输出未通过项 |

`/sdd-new` 必须指定 `change-id`。同时只有一个活动变更时，其他 change 命令可以省略 `change-id`；存在多个活动变更时必须指定，AI 不得猜测。

开发检查清单和 Helm lint 是 `/sdd-apply`、`/sdd-verify` 的内部动作，不再作为会话快捷命令。用户文档同步是 `/sdd-spec` 的正式化步骤，不再单独触发。

## 1. 新建或继续草案

`/sdd-new` 必须：

1. 确认 `change-id` 对应新变更还是已有未批准草案；已有有效批准时停止并路由到 apply 或 revise。
2. 确认目标、范围、非目标、成功标准和能力名；信息不足时先分析和提问，不创建占位规格。
3. 修改已有能力时读取 [`openspec/specs/<能力名>/spec.md`](specs/)；没有当前规格时明确“无基线”。
4. 创建或更新 proposal，列出新能力或被修改的现有能力。
5. 创建或更新只描述本次变化的变更规格。
6. 按下一节解决未知问题，按风险创建 design，并始终创建或更新 tasks。
7. 核对 proposal、变更规格、design、tasks 和探索证据；存在未决用户选择或需要独立设计 Review 时提前停止。
8. 没有未决问题时报告“可批准”并停止；不得自行执行 `/sdd-approve` 或修改正式代码。

新增能力的最小变更规格：

```markdown
## Purpose

说明该能力解决什么问题、服务谁以及主要边界。

## ADDED Requirements

### Requirement: 可观察行为名称
模板 MUST 在明确输入下产生可验证的输出或失败结果。

#### Scenario: 最小有效输入
- **WHEN** 父 Chart 提供最小有效配置
- **THEN** 模板渲染出预期字段

#### Scenario: 关键非法输入
- **WHEN** 必填字段缺失或类型非法
- **THEN** 渲染失败并指出字段路径
```

修改已有行为时，从当前规格复制完整 Requirement 和全部 Scenario，放入 `## MODIFIED Requirements` 后修改。不能只记录变化的一行，因为归档时整个 Requirement 会被替换。

## 2. 批准前准备

探索、设计和任务拆分是 `/sdd-new` 的内部阶段，不要求用户逐项触发。

### 探索未知问题

适用情况：

- Helm 或 Kubernetes 版本行为尚未确认。
- 公共上下文、类型转换或合并语义存在不确定性。
- 需要最小渲染实验才能确定可行边界。

探索规则：

- 实验资产只创建于 `/tmp/`，不得把试验代码直接当作正式实现。
- `verification.md` 记录问题、输入、命令、预期、实际结果和结论。
- 结论可以修改未批准草案；未经 `/sdd-approve` 不得固化为当前规格、正式代码或公共规则。
- 实验结束后立即清理 `/tmp/` 资产；未知问题没有证据结论时不得标记为可批准。

### 设计与任务

以下情况创建 `design.md`：跨模板层级、公共能力、上下文重构、兼容性、安全、迁移、外部依赖或需要比较备选方案。

`design.md` 只回答如何实现以及为什么这样选择；行为要求仍由变更规格定义。`tasks.md` 将已明确的工作拆成按依赖排序的复选项，每项必须有完成定义和验证方式。

设计需要独立人工 Review 时，`/sdd-new` 在 design 完成后停止；用户确认后再次执行同一 `/sdd-new <change-id>` 继续生成或更新 tasks。不得为简化调用顺序而跳过真实的设计决策门禁。

## 3. 批准与冻结

`/sdd-approve` 只能由用户明确触发。执行前必须确认：

- proposal 的范围、非目标和能力列表明确。
- 每个 Requirement 至少有一个可验证 Scenario。
- 重要未知问题已经解决；design 不含会改变行为或任务的未决问题。
- tasks 覆盖实现、验证和文档同步。

`approval.md` 最小格式：

```markdown
# 变更批准

## 当前状态

- 状态：已批准
- 批准时间：<ISO 8601>
- 批准方式：用户执行 `/sdd-approve <change-id>`

## 冻结输入

- `proposal.md`：`sha256:<摘要>`
- `specs/<能力名>/spec.md`：`sha256:<摘要>`

## 修订记录

- 无。
```

冻结对象是 proposal 和所有变更规格。`design.md` 与 `tasks.md` 可以在不改变行为契约的前提下细化；一旦它们暴露出需求变化，必须转入 `/sdd-revise`。

## 4. 实施与受控修订

`/sdd-apply` 开始前重新计算冻结文件摘要；缺少 approval 或摘要不同必须停止。

实施按 tasks 顺序修改代码并执行 [`openspec/checks/development.md`](checks/development.md)。模板变更在实现过程中运行固定 Helm CLI 的 lint 和必要的聚焦场景，将命令、输入和实际结果写入 `verification.md`；开发检查不能替代最终 `/sdd-verify`。

实施中按以下规则处理反馈：

| 发现 | 处理 |
|---|---|
| 代码不符合已批准规格 | 修复代码，规格不变 |
| 代码结构不合适但行为不变 | 修改 design、tasks 和代码 |
| 新增条件、边界或业务需求 | `/sdd-revise`，重新批准后再实施 |
| 规格矛盾或外部约束导致不可实现 | `/sdd-revise`，记录证据和影响 |
| 与本 change 无关的新目标 | 新建另一个 change |

`/sdd-revise` 必须把 approval 状态改为“需重新批准”，记录原因、受影响 Requirement、已完成代码和需作废的验证，再修改草案。重新批准前不得继续实现受影响部分。

## 5. 验证

`/sdd-verify` 以已批准规格为预期，不得为了让验证通过而按现有代码回写规格。

模板变更至少验证：

- OpenSpec 严格校验。
- `/opt/homebrew/bin/helm lint`。
- 最小有效输入和较完整有效输入。
- 每个关键失败 Scenario。
- 受影响公共能力的回归场景。

`verification.md` 对每个场景记录环境、输入、命令、预期、实际结果和状态。静态代码审阅可以确定验证范围，但不能替代 Helm 渲染证据。

## 6. 正式化、文档与归档

执行 `/sdd-spec` 前必须满足：

- approval 存在、状态为“已批准”且冻结摘要仍匹配。
- tasks 已完成，取消项有理由。
- OpenSpec、Helm 和 Scenario 验证通过，无未解决偏差。
- 代码、变更规格、design、tasks 和 verification 不冲突。
- 人工 Review 已完成。
- 通用工程结论已进入 [`openspec/rules/`](rules/)，能力专属行为保留在当前规格。

通过后：

1. 将 ADDED、MODIFIED、REMOVED、RENAMED 变更合并到 `openspec/specs/<能力名>/spec.md`。
2. 当前规格只保留行为契约和稳定验证基线，不引用活动变更或归档过程材料。
3. 用户可见行为变化时依据合并后的当前规格和已验证样例同步 [`docs/`](../docs/)；不得引用尚未成为当前事实的活动材料。
4. 重新执行 OpenSpec、文档链接和适用发布检查；失败时保留活动 change 并修复，不得归档。
5. 将整个 change 移动到 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。

归档记录解释为什么发生变化；当前规格回答系统现在必须怎样工作。

## 7. 独立维护

- `/sdd-rewrite <能力名>` 只整理当前规格的结构和表达，不改变 Requirement 或 Scenario 语义；代码和证据只用于发现不一致，不能反向生成新行为。
- `/ck-deploy` 对整个 Chart 执行 [`openspec/checks/release.md`](checks/release.md)，不创建、批准、实施或归档 change。
