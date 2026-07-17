目标：新增命名模板 `core.podTemplateSpec`，写入 `templates/api-resources/Core/_PodTemplateSpec.tpl`
需求：
- 入参：唯一上下文 `.`（由父模板 `apps.deploymentSpec` 传入）。
- 字段：
  - `metadata`：object，由 `definitions.objectMeta` 渲染。直接透传 `.`。
  - `spec`：object，委托 `core.podSpec` 渲染。直接透传 `.`。
行为：
- 不创建 `core.podSpec`
边界：
- 引用 `docs/rules/const-boundary.md`
约束：
- 引用 `docs/rules/const-general.md`
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等
参考：
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/core/pod-template-v1/#PodTemplateSpec
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#podtemplatespec-v1-core
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`
