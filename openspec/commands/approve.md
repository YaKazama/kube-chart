# `/sdd-approve`

## 职责

单步审查并冻结批准前契约；用户执行本命令即授权在全部门禁通过后批准，无需再次确认。不修改 draft 正文、plan 或正式代码。

```text
/sdd-approve <change-id>
```

只接受 `status: planned`。同一次执行中完成审查：全部门禁通过时创建批准记录并将状态改为 `approved`；任一门禁失败时不创建或修改批准记录，状态保持 `planned`，并报告阻塞项。

初次检查只接受 `status: planned`；即使 plan 文件已经存在，`status: draft` 也表示仍有阻塞项，必须返回 `/sdd-plan`。

## 读取

- `draft.md`、全部 `plan/`
- 仅为复查目标冲突读取其他活动 change 的 draft frontmatter 和 `plan/spec.md` 的 `## 技术目标`
- [`../rules/change-documents.md`](../rules/change-documents.md)、[`../rules/specifications.md`](../rules/specifications.md)
- 仅按变更范围追加读取 `AGENTS.md` 路由的实现规则
- 仅在 draft、plan、当前规格和适用规则仍不足以独立复核影响契约的目标事实时，读取 [`../references/README.md`](../references/README.md) 作为路由，并只读取与该未决事实直接相关的本地参考资料；不得机械重读 `/sdd-plan` 已使用的全部参考资料

不读取正式实现、归档历史或验证资料。

## 输出

- 审查 draft、技术目标、spec、可选 design 和 tasks 的一致性与完整性，并逐条核对适用规范性规则是否已经转化为当前目标的具体约束。
- 审查通过时，按变更文档规则创建或覆盖 `records/approval.md`，将 draft frontmatter 状态改为 `approved`，并报告冻结范围。
- 审查失败时，只报告具体阻塞项，保持 `planned`；发现 plan 缺陷时要求重新执行 `/sdd-plan`。

任何待确认问题、目标冲突、草稿不一致、适用规则遗漏、规则冲突或以笼统规则引用代替具体落实均阻止批准。不得要求用户再次回复“确认”，也不得把审查和冻结拆成两次命令。
