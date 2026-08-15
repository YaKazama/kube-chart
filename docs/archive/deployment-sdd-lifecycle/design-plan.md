# 设计与计划：Deployment 资源模板正式化

## 上下文

- 需求规格：`spec.md`。
- 相关需求：R-01、R-02、R-03、R-04。
- 目标与约束：只整理真实实现；不改变模板；未执行命令不得标为通过。

## 方案与决策

- D-01：以 `apps.deployment` 作为 Deployment 对外资源入口，内部模板行为作为同一调用链说明。
  - 理由与替代方案：入口模板决定完整资源身份和顶层委托；按内部文件拆分多份快照会割裂用户可见行为。
  - 关联需求：R-01、R-02、R-03。
  - 状态：已确认。
- D-02：以代码实际路径描述 template 与 strategy，不以期望模型替代实现。
  - 理由与替代方案：`core.podTemplateSpec` 接收根上下文，`deployment.template` 子字段尚未独立消费；无效 strategy 简写会省略而非失败。
  - 关联需求：R-03、R-04。
  - 状态：已确认。
- D-03：端到端验证保持待验证，证据仅记录静态审阅事实。
  - 理由与替代方案：library Chart 不能独立渲染资源，且缺少完成的父 Chart 验证资产。
  - 关联需求：R-04。
  - 状态：已确认。

## 接口与数据设计

- 架构、数据流或调用关系：父 Chart `$ctx` → `apps.deployment` → `definitions.objectMeta`、`apps.deploymentSpec` → selector、strategy、PodTemplateSpec 委托。
- 接口、输入输出或数据模型：顶层固定 `apiVersion`、`kind`；metadata/spec 由委托输出构成；strategy 支持 map 或匹配目标正则的 string。
- 兼容性与安全设计：`fromYaml` 结果必须结合 `base.isFromYamlError` 和 map 类型判断；rollingUpdate 的 list/int/bool 仅在 RollingUpdate 分支进入时失败。

## 风险与取舍

- 风险与缓解：顶层直接写入 `_kind`，可能污染共享上下文；当前仅记录为待修复风险，不将其描述为状态隔离。
- 待确认假设：父 Chart 是否能提供满足下层 PodTemplateSpec 的完整输入；待通过端到端渲染确认。

## 影响范围与依赖

- 受影响资产：本归档目录的过程快照；不修改 `templates/` 或 `patterns/`。
- 前置依赖与顺序：先形成过程文档，再执行 parent Chart 验证，最后经 Review 才能生成正式 SDD 与 guide。

## 实施步骤

- P-01：按新模板重写 spec、design-plan、tasks、evidence、SDD 与 guide 快照。
  - 目标资产：`docs/archive/deployment-sdd-lifecycle/`。
  - 完成定义：文档采用列表/checklist，完整保留 R/D/P/T/AC/C 标识，且修正已发现的实现偏差。
  - 关联决策：D-01、D-02、D-03。
  - 验收 ID：AC-01、AC-02、AC-03、AC-04。
- P-02：补充真实 Helm 验证和 Review。
  - 目标资产：临时 parent Chart、正式 `changes/` 证据及 `docs/specs/`。
  - 完成定义：`helm lint`、最小/完整/失败输入均有可复现证据，偏差经 Review 处理。
  - 关联决策：D-03。
  - 验收 ID：AC-04。

## 验证策略

- 验证范围与方法：先静态核对当前模板，再在临时 parent Chart 执行 `/opt/homebrew/bin/helm lint` 与 `helm template`。
- 证据产物：`evidence.md`。
