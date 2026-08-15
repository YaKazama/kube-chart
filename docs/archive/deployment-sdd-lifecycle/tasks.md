# 任务：Deployment 资源模板正式化

## 任务清单

- [x] T-01：重写 `spec.md`。
  - 目标资产：`docs/archive/deployment-sdd-lifecycle/spec.md`。
  - 前置任务：无。
  - 完成定义：R-01 至 R-04 与 AC-01 至 AC-04 使用列表结构，且不将 template 子字段描述为已独立消费。
  - 关联计划：P-01。
  - 验收 ID：AC-01、AC-02、AC-03、AC-04。
- [x] T-02：重写设计、任务、证据、SDD 和 guide 快照。
  - 目标资产：`design-plan.md`、`tasks.md`、`evidence.md`、`sdd.md`、`guide.md`。
  - 前置任务：T-01。
  - 完成定义：各文件遵循新模板，记录 strategy/template/_kind 的实现限制和待验证状态。
  - 关联计划：P-01。
  - 验收 ID：AC-03、AC-04。
- [ ] T-03：执行 library Chart 静态检查。
  - 目标资产：Chart 根目录和 `evidence.md`。
  - 前置任务：T-02。
  - 完成定义：记录 `/opt/homebrew/bin/helm lint .` 的实际输出和状态。
  - 关联计划：P-02。
  - 验收 ID：AC-04。
- [ ] T-04：创建临时 parent Chart 并验证 Deployment 调用链。
  - 目标资产：`/tmp/` 验证资产和正式变更的 `evidence.md`。
  - 前置任务：T-03。
  - 完成定义：最小、完整和失败输入均有命令、产物和实际状态；临时文件完成后删除。
  - 关联计划：P-02。
  - 验收 ID：AC-01、AC-02、AC-03、AC-04。
- [ ] T-05：完成 Review 与正式化。
  - 目标资产：`docs/specs/`、已验证样例和归档目录。
  - 前置任务：T-04。
  - 完成定义：所有 AC 有通过证据，已解决或记录偏差，正式 SDD 不引用过程文档。
  - 关联计划：P-02。
  - 验收 ID：AC-04。

## 验证任务

- [ ] T-06：执行验证资产与命令，完成定义为记录 AC-01 至 AC-04 的结果到 `evidence.md`。
