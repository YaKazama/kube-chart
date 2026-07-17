{{- /*
  渲染 Kubernetes MutatingAdmissionPolicy 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/admissionregistration/mutating-admission-policy-v1/#MutatingAdmissionPolicy

  行为 (按 K8s API 规范字段顺序):
    - apiVersion (string, 必填): 固定为 admissionregistration.k8s.io/v1, 与 K8s API 规范对齐, 不允许覆盖。
    - kind (string, 必填): 固定为 MutatingAdmissionPolicy, 与 K8s API 规范对齐, 不允许覆盖。
    - metadata (dict, 必填): 委托 definitions.objectMeta 渲染, 强制 _kind = MutatingAdmissionPolicy, 渲染结果为空时立即中断并报错。
    - spec (dict, 可选): 委托 admissionregistration.mutatingAdmissionPolicySpec 渲染, 缺失或为 nil 时不渲染 spec 字段, 非 dict 类型时立即中断并报错。

  核心字段: 上下文 map, 可包含以下字段:
    - 其余字段透传给 definitions.objectMeta (annotations / generateName / labels / name / namespace)
    - spec       (dict, 可选)   MutatingAdmissionPolicySpec 结构

  返回值: MutatingAdmissionPolicy 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "admissionregistration.mutatingAdmissionPolicy" . }}
*/ -}}
{{- define "admissionregistration.mutatingAdmissionPolicy" -}}
  {{- /* Step 1: apiVersion / kind 固定, 与 K8s API 规范对齐, 不允许覆盖 */ -}}
  {{- nindent 0 "" -}}apiVersion: "admissionregistration.k8s.io/v1"
  {{- nindent 0 "" -}}kind: "MutatingAdmissionPolicy"

  {{- /* Step 2: metadata (dict, 必填): 委托 definitions.objectMeta 渲染
       强制设置 _kind = MutatingAdmissionPolicy (definitions.objectMeta 内部不污染源上下文, 无需 mustDeepCopy)
       渲染结果为空或 Helm 4.2.2 fromYaml BUG 错误 map 时立即中断并报错, 符合"必填项缺失"边界行为 */ -}}
  {{- $_ := set . "_kind" "MutatingAdmissionPolicy" }}
  {{- $metadata := include "definitions.objectMeta" . | fromYaml }}
  {{- if not $metadata }}
    {{- fail "[admissionregistration.mutatingAdmissionPolicy] metadata: required field is missing or empty" }}
  {{- end }}
  {{- if eq (include "base.isFromYamlError" $metadata) "true" }}
    {{- fail "[admissionregistration.mutatingAdmissionPolicy] metadata: invalid YAML output from definitions.objectMeta" }}
  {{- end }}
  {{- if not (kindIs "map" $metadata) }}
    {{- fail "[admissionregistration.mutatingAdmissionPolicy] metadata: must be map type" }}
  {{- end }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}

  {{- /*
    Step 3: spec (dict, 可选): 委托 admissionregistration.mutatingAdmissionPolicySpec 渲染
    向下传递 ., 缺失 / nil / 空字符串 时跳过, 非法 YAML 或非 dict 类型时立即中断并报错
    兼容 Helm 4.2.2 fromYaml 对非 YAML 输入返回错误 map 的行为, 委托 base.isFromYamlError 检测
  */ -}}
  {{- $specRaw := include "admissionregistration.mutatingAdmissionPolicySpec" . }}
  {{- if $specRaw }}
    {{- $specObj := $specRaw | fromYaml }}
    {{- if $specObj }}
      {{- if eq (include "base.isFromYamlError" $specObj) "true" }}
        {{- fail "[admissionregistration.mutatingAdmissionPolicy] spec: invalid YAML output from admissionregistration.mutatingAdmissionPolicySpec" }}
      {{- end }}

      {{- if not (kindIs "map" $specObj) }}
        {{- fail "[admissionregistration.mutatingAdmissionPolicy] spec: must be dict type" }}
      {{- end }}

      {{- include "base.field" (list "spec" $specObj "base.map") }}
    {{- end }}
  {{- end }}
{{- end -}}
