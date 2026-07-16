目标: 新增命名模板 `apps.rollingUpdateDeployment`，写入 `templates/api-resources/Apps/_RollingUpdateDeployment.tpl`
需求:
- 入参：dict（由 `apps.deploymentStrategy` 传递）
- 字段：
  - `maxSurge`: 整数或百分比字符串，可选
  - `maxUnavailable`: 整数或百分比字符串，可选
行为：
- 入参包含`maxSurge`、`maxUnavailable`字段
- 直接取值并渲染，不需要正则校验
- 空值时，不渲染对应字段；`0` 时，渲染为 `0`
边界：
  - 引用 `docs/rules/const-boundary.md`
  - `maxSurge`、`maxUnavailable` 不能同时为 `0` 但可以同时为空值
约束:
- 引用 `docs/rules/const-general.md`
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#rollingupdatedeployment-v1-apps
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`
