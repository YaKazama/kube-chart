# kube-chart OPSX v0.2.0 工作流

本文件是制品关系、文件即状态判据、共享闭包和命令上下文类别的唯一来源。命令职责与读取范围位于 [`commands/`](commands/)，变更文档规则位于 [`rules/change-documents.md`](rules/change-documents.md)。

## 动作模型

- OPSX 命令是可以按需执行和重复执行的动作，不存在刚性阶段、状态枚举或状态转换。
- `draft.md` 保存意图、已确认共识和开放问题；`spec.md` 保存可观察行为；`design.md` 保存技术目标、设计决策、依赖契约和代码边界；`tasks.md` 保存实施和验证 checkbox。
- spec、design 和 tasks 共同构成执行契约，三者必须保持 draft ↔ spec ↔ design ↔ tasks 闭包；任何单一制品不得替代其他职责。
- `design.md` 的代码边界按精确文件记录 `read | write` 权限、operation 和 writable scope。`read` 只允许读取；`write` 同时允许读取，但只能修改声明的 writable scope。
- `/opsx:spec` 和 `/opsx:sync` 都可以重复执行。已有制品必须先对比再更新或补全，不得盲目重新生成。
- `/opsx:code` 只负责生成或修改代码和明显静态错误检查；最小 Helm 渲染属于 `/opsx:verify`，完整 Chart 发布检查属于 `/opsx:ck:publish`。

## 命令上下文类别

当前命令定义、工作流和适用规则属于控制上下文。业务事实按下表取用：

| 类别 | 命令 | 可用业务上下文 |
|---|---|---|
| 会话与文件 | `/opsx:new`、`/opsx:explore`、`/opsx:code` | 当前命令输入、相关聊天历史和完成职责所需的文件上下文。 |
| 仅文件 | `/opsx:spec`、`/opsx:verify`、`/opsx:docs`、`/opsx:archive`、`/opsx:ck:publish` | 只使用完成职责所需的当前文件和本轮真实工具结果；聊天历史不作为业务依据。 |
| 同步专用 | `/opsx:sync` | 不依赖聊天历史；允许使用当前命令输入中的简短同步说明，并以代码事实、测试事实和既有文档为准。 |

仅文件动作即使在同一会话中执行，也必须重新从允许的当前文件建立事实。`/opsx:sync` 的回写确认必须出现在当前命令输入或代码库内可读取的变更说明中，不能仅引用上一轮会话结论。

## 目录与制品

```text
openspec/changes/<change-id>/
  draft.md                  用户意图、共识与开放问题
  spec.md                   可观察行为与执行契约确认标记
  design.md                 技术设计、依赖契约与代码边界
  tasks.md                  实施和验证进度
  notes/                    可选；/opsx:explore 指定的讨论笔记
```

活动 change 至少包含 `draft.md`。`notes/` 只保存讨论记录，不能替代任何正式制品。归档位于 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`；旧归档可以保留创建时采用的历史结构。

frontmatter、正文归属和确认标记统一遵循 [`rules/change-documents.md`](rules/change-documents.md)。

## 文件即状态

| 事实 | 判断依据 |
|---|---|
| 是否已有草稿 | `openspec/changes/<change-id>/draft.md` 是否存在。 |
| 是否已有变更目录 | `openspec/changes/<change-id>/` 是否存在。 |
| 是否已有规格制品 | `spec.md`、`design.md`、`tasks.md` 各自是否存在；缺失文件是明确缺口，不映射为状态值。 |
| 执行契约是否已确认 | `spec.md` frontmatter 的 `confirmed: true`；该标记确认同目录当前 spec、design 和 tasks 的组合。 |
| 任务进度 | `tasks.md` 中对应 checkbox 是否勾选，并由代码或验证事实支撑。 |
| 是否已实现 | 代码文件、测试结果、任务 checkbox 和版本控制变更共同证明，不由单个标记推断。 |
| 是否已归档 | change 是否位于 `openspec/changes/archive/YYYY-MM-DD-<change-id>/`。 |
| 文档是否完成 | `docs/` 和根 `README.md` 是否已按实际行为更新。 |

`confirmed: true` 不是阶段状态。`/opsx:spec` 修改 spec、design 或 task 文本后必须把它重置为 `false`，用户审阅当前三制品后再通过确认动作设置为 `true`。`/opsx:sync` 只有在当前命令精确确认全部实际差异且同步后闭包成立时才能写入 `true`，否则写入 `false`。仅勾选既有 task 不重置确认标记。

## 四向闭包

- draft ↔ spec：draft 中每项已确认意图都映射到 spec；spec 的每项 Requirement、Scenario、失败边界和非目标都有 draft 意图、当前同步说明或经确认的代码事实来源，不含实现步骤。未确认 `[AI 推断]` 和阻塞性开放问题不得变成行为契约。
- spec ↔ design：spec 中每项行为都映射到 design 的技术目标、设计决策或依赖契约；design 不新增或弱化行为。每个依赖都有确定的 availability、入参、返回边界和来源路径，或明确标记为当前未实现且不在本 change 实现。
- design ↔ tasks：design 中每项 write operation 和验证设计都映射到 tasks；tasks 不引入新的行为、设计选择或文件。
- tasks ↔ 实现事实：已勾选任务具有当前代码或实际命令结果；未完成或证据失效的任务保持未勾选。

移除聊天历史后，仅凭正式制品、其明确列出的当前文件、适用规则和对应工具事实仍不能唯一执行仅文件动作时，闭包检查失败并报告缺口。

## 共享动作约束

- `/opsx:new` 只在确切 change 路径不存在时新建目录和 `draft.md`。
- `/opsx:explore` 把已形成的共识写回 draft 或用户指定笔记；未形成共识时把开放问题明确写入文件。
- `/opsx:spec` 要求 draft 存在。目标制品不存在时创建，存在时逐项对比、更新、补全并输出差异与冲突；不能闭包时保留可验证的既有内容并报告缺口，不宣称完成。
- `/opsx:code` 要求三制品完整、闭包且已确认。所有影响验收、接口、行为和任务边界的决策必须已存在于 draft、spec、design 或 tasks；缺失时停止相关修改并建议 `/opsx:explore` 或 `/opsx:sync`。
- `/opsx:verify` 只验证当前 change 已变更模板及必要依赖，不修改代码；实际通过后可以勾选精确对应的验证 task。
- `/opsx:sync` 首轮只输出代码事实、制品差异、建议更新、疑似冲突、待确认项和不建议写入规格项。只有当前命令输入或可读取变更说明包含精确确认后才回写，且永不修改 draft。
- `/opsx:docs` 只把正式实现支持的行为写入最终用户文档；带 change-id 时限定该 change，不带时处理全部归档内容。
- `/opsx:archive` 在轻量核对通过后移动整个 change 目录；失败时只输出缺失项、风险项和建议动作。
- `/opsx:ck:publish` 对整个 Chart 执行实际发布检查，不能复用局部验证或会话摘要替代真实命令。

## 参数与时间

- change-id 必须是 kebab-case，并精确对应 `openspec/changes/<change-id>/`；`/opsx:docs` 的 change-id 可选，`/opsx:ck:publish` 不接受 change-id。
- 正常执行直接访问确切路径，不模糊匹配、自动纠错或根据唯一活动 change 推断参数。无 change-id 的 `/opsx:docs` 和全 Chart 发布检查按各自命令定义列出所需范围。
- 目标不存在或必要制品缺失时报告确切缺口，不创建替代 change。
- `updated_at` 使用 UTC RFC 3339 时间，只在对应制品实际变化时更新。
