目标: 新增命名模板 `admissionregistration.MutatingAdmissionPolicySpec`，写入 `templates/api-resources/Admissionregistration/_MutatingAdmissionPolicySpec.tpl`。
需求:
- 入参：唯一上下文 `.`（由 `admissionregistration.mutatingAdmissionPolicy` 直接传递）。
- 行为：按 K8s API 规范字段顺序渲染 MutatingAdmissionPolicySpec 资源。
- 字段：
  - `failurePolicy`: 可选，string。
    - allows: 允许的值: `Fail`、`Ignore`。
  - `matchConditions`: 可选, list([]map[string]string, []string)。
    - []map[string]string 格式：`[expression: string, name: string]`。
    - []string 格式：`expression name`，分隔符参考 `,\\s*|\\s+|=`。
      - 字符拆分正则表达式，参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/match-condition-v1-admissionregistration/#MatchCondition
    - 委托 `definitions.matchCondition` 渲染（不创建）。
  - `matchConstraints`: 。
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
  - https://kubernetes.io/docs/reference/kubernetes-api/admissionregistration/mutating-admission-policy-v1/#MutatingAdmissionPolicy
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#mutatingadmissionpolicy-v1-admissionregistration-k8s-io
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`。
  - https://raw.githubusercontent.com/kubernetes/website/main/content/en/examples/mutatingadmissionpolicy/applyconfiguration-example.yaml
