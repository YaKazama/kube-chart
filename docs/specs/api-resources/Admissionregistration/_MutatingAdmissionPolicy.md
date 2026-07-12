目标: 新增命名模板 `admissionregistration.MutatingAdmissionPolicy`，写入 `templates/api-resources/Admissionregistration/_MutatingAdmissionPolicy.tpl`。
需求:
- 入参：唯一上下文 `.`。
- 行为：按 K8s API 规范字段顺序渲染 MutatingAdmissionPolicy 资源。`definitions.objectMeta` 不需要 mustDeepCopy。
- 字段：
  - apiVersion: string, 必填，`admissionregistration.k8s.io/v1`。
  - kind: string, 必填，`MutatingAdmissionPolicy`。
  - metadata: dict, 必填，包含 `base.metadata`。
  - spec: dict, 可选，向下传递 `.`，委托 `admissionregistration.mutatingAdmissionPolicySpec` 渲染（不创建）。
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
