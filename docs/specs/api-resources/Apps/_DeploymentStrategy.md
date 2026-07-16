目标: 新增命名模板 `apps.DeploymentStrategy`，写入 `templates/api-resources/Apps/_DeploymentStrategy.tpl`
需求:
- 入参：dict（由 `apps.DeploymentSpec` 传递, 包含 `type`、`rollingUpdate` 字段）
- 行为：按 K8s API 规范字段顺序渲染 DeploymentStrategy 资源
- 字段：
  - `rollingUpdate`: object/map/string，可选，委托 `apps.rollingUpdateDeployment`
    - Present only if DeploymentStrategyType = RollingUpdate.
    - string 类型：
      - 格式 `maxSurge maxUnavailable`，空格分隔
      - 正则解析为 dict，包含 `maxSurge`、`maxUnavailable` 字段
      - `maxSurge`、`maxUnavailable` 可以为空、或为整数或百分比
    - 上下文：dict，包括 `maxSurge`、`maxUnavailable` 字段。通常直接将 `rollingUpdate` 字段透传给委托的模板
  - `type`: string, 可选，default `RollingUpdate`
    - Can be "Recreate" or "RollingUpdate".
- 边界行为：
  - 引用 `docs/rules/const-boundary.md`
约束:
- 引用 `docs/rules/const-general.md`
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentstrategy-v1-apps
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`
