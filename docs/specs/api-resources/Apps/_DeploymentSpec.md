目标: 新增命名模板 `apps.DeploymentSpec`，写入 `templates/api-resources/Apps/_DeploymentSpec.tpl`。
需求:
- 入参：唯一上下文 `.`（由 `apps.Deployment` 传递）。
- 行为：按 K8s API 规范字段顺序渲染 DeploymentSpec 资源。
- 字段：
  - `minReadySeconds`: int, 可选，default `0`，大于 0 时设置。
  - `paused`: bool, 可选，default `false`。
  - `progressDeadlineSeconds`: int, 可选，default `600`，大于 0 时设置。
  - `replicas`: int, 可选，default `1`，允许显式 0 表示缩容到 0，大于等于 0 时设置。
  - `revisionHistoryLimit`: int, 可选，default `10`，大于等于 0 时设置。
  - `selector`: object，必填，委托 `definitions.labelSelector`。
    - 至少包括 `matchLabels` 字段。`matchExpressions` 字段可选。
    - `base.labels`，合并到 `selector.matchLabels` 字段中。
    - `base.labels` 入参上下文：`.`。
    - 去重、去空。
  - `strategy`: string / object，可选，委托 `apps.deploymentStrategy`。
    - string 类型，正则，参考：`^(Recreate|RollingUpdate)?(?:\\s*(\\d+\\%?))?(?:\\s+(\\d+\\%?))?$`。
      - 需要使用正则拆分字符串，提取 `type`、`minReadySeconds`、`maxSurge`、`maxUnavailable` 字段并生成可用的 dict 兼容原生语义。
      - 正则表达式放到 `Apps` 组。
      - 先统一解析规整为 dict，再透传给委托的模板。
    - object 类型，原生定义。包括 `type`、`rollingUpdate` 字段。
    - 上下文：dict，包括 `type`、`rollingUpdate` 字段。
  - `template`: object，必填，委托 `core.podTemplateSpec`。
    - 上下文：`.`。
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
  - https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentspec-v1-apps
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`。
