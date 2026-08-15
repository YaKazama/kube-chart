# docs

`docs` 是项目 SDD 文档根目录。

## 目录

```text
docs/
  AGENTS.md
  patterns/
  changes/
  specs/
  archive/
  guide/
```

- `patterns/`：已验证的通用规则、固定文档模板、检查清单、样例、参考资料和工作流。
- `changes/`：单模板或单功能的开发工作区；只保留未完成或待 Review 的变更。
- `specs/`：已实现、已验证、已 Review 的正式 SDD 文档；目录与 `templates/` 对齐。
- `archive/`：过程文档、历史草案、废弃方案与决策记录；不具备规范能力。
- `guide/`：面向最终使用者的文档；在项目后期基于稳定实现集中生成。

## 文件流

```text
patterns/ → changes/<change-id>/ → templates/
                    ↓                 ↓
                 Review 与验证 → specs/
                    ↓
                archive/
```

`changes/` 中的 `spec.md`、`design-plan.md`、`tasks.md` 与 `evidence.md` 是过程文档。高风险变更可将 `design-plan.md` 拆为已确认的 `design.md` 与 `plan.md`。`/sdd-spec` 根据代码、验收证据和 Review 结果更新 `specs/` 中唯一的正式 SDD 文档，并归档过程材料。

## 迁移原则

- 本目录沿用旧规则文件名：`const-general.md`、`const-boundary.md`、`dev.checklist`、`deployment.checklist`、`readme-rules.md`、`specs-ai-rewrite.md`。
- 规则正文只在 `patterns/` 保留一份权威来源；正式 SDD 仅引用通用规则，不重复定义。
- 旧文档已迁移至 `docs-bak/`；它们仅用于历史追溯，不具备当前规范能力。
