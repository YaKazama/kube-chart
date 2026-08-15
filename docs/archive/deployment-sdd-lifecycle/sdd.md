# Deployment 行为契约快照

## 范围与依赖

- 适用对象：`templates/api-resources/Apps/_Deployment.tpl` 定义的 `apps.deployment` 及其已实现调用链。
- 非目标：本文件是未完成验证与 Review 的归档快照，不是当前正式 SDD；不保证 parent Chart 端到端可渲染。
- 外部依赖与前置条件：父 Chart 构造局部上下文；`definitions.objectMeta`、`apps.deploymentSpec` 及其下层模板可用。
- 术语：错误 map 指 Helm 4.2.2 中 `fromYaml` 对非 map 输入返回的带错误信息 map。

## 行为契约

- C-01：固定资源身份与顶层委托。
  - 输入与条件：父 Chart 提供调用上下文。
  - 处理与约束：固定输出 `apiVersion: apps/v1` 与 `kind: Deployment`；设置 `_kind: Deployment` 后委托 objectMeta 和 DeploymentSpec。
  - 输出或可观察结果：metadata/spec 委托输出均须为非空有效 map 后嵌入资源。
  - 失败行为：空、错误 map 或非 map 委托输出立即失败。
- C-02：DeploymentSpec 标量字段。
  - 输入与条件：根上下文包含可选标量字段。
  - 处理与约束：minReadySeconds/progressDeadlineSeconds 仅大于 `0` 输出；paused 仅为 `true` 输出；replicas/revisionHistoryLimit 大于等于 `0` 输出。
  - 输出或可观察结果：缺省值交由 Kubernetes 处理，`replicas: 0` 与 `revisionHistoryLimit: 0` 保留。
  - 失败行为：本层对不满足输出条件的数值静默省略。
- C-03：selector。
  - 输入与条件：根上下文中的 selector 必须能解析为 map。
  - 处理与约束：基础 labels 在有效时合并到 selector.matchLabels，再委托 labelSelector。
  - 输出或可观察结果：输出有效 LabelSelector。
  - 失败行为：selector 缺失或非 map 时失败；下层缺少有效 matchLabels 时失败。
- C-04：strategy 与 RollingUpdate。
  - 输入与条件：strategy 可为 map，或匹配 Deployment strategy 正则的 string。
  - 处理与约束：map 深拷贝；匹配 string 规整为 dict；不匹配的 string 不输出 strategy；Recreate 跳过 rollingUpdate。
  - 输出或可观察结果：进入下层的 type 缺省为 RollingUpdate；RollingUpdate 可输出 maxSurge/maxUnavailable。
  - 失败行为：进入 RollingUpdate 分支的 list/int/bool rollingUpdate 失败；两个容量字段同为 `0` 或 `0%` 时失败；非法 type 枚举失败。
- C-05：PodTemplateSpec 调用限制。
  - 输入与条件：DeploymentSpec 将完整根上下文传给 core.podTemplateSpec。
  - 处理与约束：当前不独立读取或传递 `template` 子字段。
  - 输出或可观察结果：仅当 core.podTemplateSpec 输出非空有效 map 时嵌入 spec.template。
  - 失败行为：下层输出为空、错误 map 或非 map 时失败。

## 边界与兼容性

- 兼容性基线：map 解析使用 `base.isFromYamlError` 与真实 map 类型判断。
- 已知限制：无完整 parent Chart 渲染证据；`template` 子字段未独立消费；顶层直接写入 `_kind`。
- 错误与恢复行为：失败消息由当前模板的 `fail` 分支产生；修复上述限制后需重新验证并经 Review。

## 验证基线

- 覆盖的验收场景：AC-01 至 AC-04 仅完成静态审阅。
- 稳定验证资产：无；尚未生成可作为正式 SDD 依赖的已验证样例。

## 规范引用

- 外部规范：Kubernetes Deployment API、Helm 模板函数文档。
- 相关规范：正式化后应引用 `docs/patterns/` 中的通用规则；本归档快照不具引用资格。
