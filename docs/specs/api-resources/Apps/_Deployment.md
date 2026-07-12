目标: 新增命名模板 `apps.Deployment`，写入 `templates/api-resources/Apps/_Deployment.tpl`。
需求:
- 入参：唯一上下文 `.`。
- 行为：按 K8s API 规范字段顺序渲染 Deployment 资源。
- 字段：
  - `apiVersion`: string, `apps/v1`。
  - `kind`: string, `Deployment`。
  - `metadata`: object，必填，委托 `definitions.objectMeta`。
  - `spec`: object，必填，委托 `definitions.deploymentSpec` 渲染（不创建）。
- 边界行为：
  - 必填项缺失或值为 `nil`（`base.get` 返回字符串 `"null"`）时立即中断并报错。
  - slice/list 类型字段需通过 `base.isFromYamlArrayError` 兼容 Helm 4.2.2 `fromYamlArray` 对非 slice/list 类型输入返回错误切片的 BUG。
  - map/dict 类型字段需通过 `base.isFromYamlError` 兼容 Helm 4.2.2 `fromYaml` 对非 map 类型输入返回错误 map 的 BUG。
约束:
- 引用约束 `docs/rules/const-general.md`。
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等。
- 允许读取 `docs/samples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#Deployment
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deployment-v1-apps
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`。
