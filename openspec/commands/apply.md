# `/sdd-apply`

## 职责

可首次或重复按已冻结契约生成正式代码、更新实施任务，并在会话中输出变更摘要；不执行验证，不创建阶段记录，不修改规格或用户文档。

## 读取

- `draft.md` frontmatter、`records/approval.md` 和全部 `plan/`
- 目标代码和直接依赖的当前规格
- [`../rules/change-documents.md`](../rules/change-documents.md)
- 仅按修改范围读取 `AGENTS.md` 路由的实现规则

只接受 `approved` 或 `applied`。`approved` 用于首次或未完成的执行，`applied` 允许重复执行；不读取其他 change、归档记录或无关验证资料。

## 输出

- 只修改冻结契约列为本 change 目标产物的正式代码、必要样例或测试资产。父模板依赖的子模板不属于当前目标时，只在冻结契约指定的字段或调用位置写入精确的 `include` 引用，不创建或修改子模板；不得在正式 `templates/` 中创建用于绕过缺失依赖的空实现、固定值或假数据 `define`。冻结契约未明确子模板的 `define` 名称、调用位置、传入上下文或最小返回边界时视为契约缺陷，停止并要求 `/sdd-revise`。
- 每次执行都重新核对当前正式代码与冻结契约，以现有实现为基础幂等续作；不得仅凭任务已完成标记跳过契约核对，不得重复生成同一代码块、模板或资产。当前实现已一致时允许不产生代码差异，并在变更摘要中明确报告。
- 按变更文档规则只更新 `plan/tasks.md` 的任务完成状态，不改写任务内容、顺序或 `plan/spec.md`、`plan/design.md`。代码与全部实施任务完成后进入或保持 `applied`；否则保持进入命令前的状态。
- 会话变更摘要只报告修改文件、已完成与剩余任务、发现的契约阻塞和当前状态，不生成额外摘要文件，不作验证通过声明。
- 不运行 lint、测试、渲染、Scenario 或其他验证命令，不创建或更新 `records/verification.md`；所有真实验证、证据记录与验证状态更新都属于 `/sdd-verify`。
- 确认为契约不可实现、目标事实错误或需求需变更时要求 `/sdd-revise`，不得自行选择新边界或按代码反写 plan。

先核对 `records/approval.md` 中记录的 `plan/spec.md` 和存在的 `plan/design.md` 摘要；不匹配时立即停止并要求 `/sdd-revise`。发现契约缺陷或新增需求时停止并要求 `/sdd-revise`；不得按代码反写 plan。
