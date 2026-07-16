目标: 新增命名模板 `definitions.labelSelectorRequirement`，写入 `templates/api-resources/Definitions/_LabelSelectorRequirement.tpl`
需求:
- 入参：dict，由 `definitions.labelSelector` 传递，包括 `key`（必填）、`operator`（必填）、`values` 字段
- 字段：
  - `key`: string，必填，标签选择器的键名
  - `operator`: string，必填，标签选择器的操作符
  - `values`: string array/[]string，可选，标签选择器的值列表
行为：
- `operator` 可选值：`In`、`NotIn`、`Exists`、`DoesNotExist`
- `values` 可选值：根据 `operator` 不同而不同
  - If the operator is In or NotIn, the values array must be non-empty.
  - If the operator is Exists or DoesNotExist, the values array must be empty.
边界：
- 引用 `docs/rules/const-boundary.md`
约束:
- 引用 `docs/rules/const-general.md`
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-requirement-v1-meta/#LabelSelectorRequirement
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#labelselectorrequirement-v1-meta
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`
