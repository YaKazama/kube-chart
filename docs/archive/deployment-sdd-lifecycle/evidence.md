# 验证证据：Deployment 资源模板正式化

## 环境

- 执行环境与版本：静态审阅当前工作区；Kubernetes API 基线 `>= v1.36.0`；Helm 命令尚未执行。
- 输入资产版本或标识：`templates/api-resources/Apps/_Deployment.tpl`、`_DeploymentSpec.tpl`、`_DeploymentStrategy.tpl`、`_RollingUpdateDeployment.tpl`。

## 验证执行

- [x] AC-01：
  - 验证类型：静态审阅。
  - 输入资产：Deployment 顶层模板与直接委托输出检查。
  - 命令：未执行命令。
  - 期望结果：资源身份固定，metadata/spec 的委托输出必须为非空有效 map。
  - 实际结果：代码实现符合该预期。
  - 产物位置：`templates/api-resources/Apps/_Deployment.tpl`。
  - 执行时间：文档重写时。
  - 状态：通过。
- [x] AC-02：
  - 验证类型：静态审阅。
  - 输入资产：DeploymentSpec 标量字段实现。
  - 命令：未执行命令。
  - 期望结果：正数条件字段省略零值；replicas 与 revisionHistoryLimit 保留 `0`。
  - 实际结果：代码实现符合该预期。
  - 产物位置：`templates/api-resources/Apps/_DeploymentSpec.tpl`。
  - 执行时间：文档重写时。
  - 状态：通过。
- [x] AC-03：
  - 验证类型：静态审阅。
  - 输入资产：selector、strategy 与 RollingUpdate 实现。
  - 命令：未执行命令。
  - 期望结果：selector 非 map 失败；Recreate 跳过 rollingUpdate；双零失败；无效 strategy 简写省略。
  - 实际结果：代码实现符合该预期；rollingUpdate 的类型失败仅在 RollingUpdate 分支进入时发生。
  - 产物位置：`_DeploymentSpec.tpl`、`_DeploymentStrategy.tpl`、`_RollingUpdateDeployment.tpl`。
  - 执行时间：文档重写时。
  - 状态：通过。
- [x] AC-04：
  - 验证类型：静态审阅。
  - 输入资产：Deployment 到 PodTemplateSpec 调用链。
  - 命令：未执行命令。
  - 期望结果：明确限制与未完成验证。
  - 实际结果：`deployment.template` 未被独立读取；顶层直接写入 `_kind`；未执行 helm lint、parent Chart 渲染或 Review。
  - 产物位置：`_Deployment.tpl`、`_DeploymentSpec.tpl`、`_PodTemplateSpec.tpl`。
  - 执行时间：文档重写时。
  - 状态：通过。

## 未决项

- 问题或偏差：缺少 parent Chart 端到端证据；`template` 子字段未接入；顶层 `_kind` 写入可能污染共享上下文。
- 后续动作：执行 T-03 至 T-06，确认或修复偏差后才可创建正式 SDD 和用户 guide。
