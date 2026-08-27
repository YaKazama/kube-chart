# `/sdd-approve`

## 职责

单步审查并冻结批准前契约，不修改 draft 正文、plan 或正式代码。用户执行即授权在全部门禁通过后批准，无需再次确认。

```text
/sdd-approve <change-id>
```

只接受 `status: planned`；即使 plan 已存在，`draft` 仍表示有阻塞项，必须返回 `/sdd-plan`。审查与冻结在同一次执行中完成。

## 读取

### 固定读取

- `draft.md`、全部 `plan/`
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- plan 技术目标指向且真实存在的确切当前规格，以及 plan 已具体落实的确切实现规则

### 条件读取

- 仅为复查目标冲突，列出除 `archive/` 与当前 change 外的直接活动 change 目录；存在其他活动 change 时，只读取其 draft frontmatter 与 `plan/spec.md` 的 `## 技术目标`，目标不重叠时立即停止。

### 禁止读取

- 不读取正式实现、目录结构、依赖实现、调用链、参考资料、外部资源、归档历史或验证资料。
- 固定上下文不足以独立批准时判定 plan 不完整并要求重跑 `/sdd-plan`；不得在批准阶段重新开展技术调查或扩大读取范围补全 plan。

## 输出

- 审查 draft、技术目标、spec、可选 design 和 tasks 的一致性与完整性，并逐条核对适用规范性规则是否已经转化为当前目标的具体约束。
- 通过时按变更文档规则创建或覆盖 `records/approval.md`，将 plan 已确定的技术目标、确切目标文件和直接依赖抄录到人类可读冻结范围，不新增契约；随后将状态改为 `approved` 并报告冻结范围。
- 失败时不创建或修改批准记录，只报告具体阻塞项并保持 `planned`；plan 有缺陷时要求重跑 `/sdd-plan`。

任何待确认问题、目标冲突、草稿不一致、适用规则遗漏、规则冲突或以笼统引用代替具体落实均阻止批准。不得要求用户再次“确认”，也不得拆分审查与冻结。
