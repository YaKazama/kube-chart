# 批准记录

## 冻结范围

- change-id：`apps-deployment`
- 技术目标：在 `templates/api-resources/Apps/_Deployment.tpl` 提供 Helm 命名模板 `apps.deployment`。
- 行为契约：冻结 `plan/spec.md` 中的 Deployment 单资源输出、`_kind` 上下文标识、`metadata` 与 `spec` 委托及子模板失败边界。
- 设计契约：冻结 `plan/design.md` 中的 Kubernetes API 字段顺序、直接依赖、调用上下文、处理闭环、类型与隔离边界。
- `plan/tasks.md` 仅承载实施顺序，不属于冻结契约。

## 冻结摘要

| 文件 | 存在性 | SHA-256 |
|---|---|---|
| `plan/spec.md` | 存在 | `fa464411607273bfb4d45b9fb412ec764e9c24d962acfc081c46feae3d14b188` |
| `plan/design.md` | 存在 | `fb3aec549ece5c2d0a76558c5eec8e00ed65a20433fc61d772a6e825841097c1` |

## 审查结论

- draft、技术目标、变更规格、设计与任务一致。
- 无待确认问题、目标冲突、适用规则遗漏或规则冲突。
- 批准门禁通过，上述契约已冻结。
