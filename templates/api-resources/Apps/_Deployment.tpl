{{- /*
  渲染 Kubernetes Deployment 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/

  行为 (按 K8s API 规范字段顺序):
    - apiVersion (string, 必填): 固定为 apps/v1, 与 K8s API 规范对齐, 不允许覆盖。
    - kind (string, 必填): 固定为 Deployment, 与 K8s API 规范对齐, 不允许覆盖。
    - metadata (dict, 必填): 委托 definitions.objectMeta 渲染, 强制 _kind = Deployment, 渲染结果为空时立即中断并报错。
    - spec (dict, 必填): 委托 definitions.deploymentSpec 渲染, 缺失 / 渲染失败 / 非 dict 类型时立即中断并报错。

  核心字段: 上下文 map, 可包含以下字段:
    - 其余字段透传给 definitions.objectMeta (annotations / generateName / labels / name / namespace)
    - spec       (dict, 必填)   DeploymentSpec 结构

  返回值: Deployment 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "apps.deployment" . }}
*/ -}}
{{- define "apps.deployment" -}}
  {{- /* Step 1: apiVersion / kind 固定, 与 K8s API 规范对齐, 不允许覆盖 */ -}}
  {{- nindent 0 "" -}}apiVersion: "apps/v1"
  {{- nindent 0 "" -}}kind: "Deployment"

  {{- /* Step 2: metadata (dict, 必填): 委托 definitions.objectMeta 渲染
       强制设置 _kind = Deployment (definitions.objectMeta 内部不污染源上下文, 无需 mustDeepCopy)
       渲染结果为空或 Helm 4.2.2 fromYaml BUG 错误 map 时立即中断并报错, 符合"必填项缺失"边界行为 */ -}}
  {{- $_ := set . "_kind" "Deployment" }}
  {{- $metadata := include "definitions.objectMeta" . | fromYaml }}
  {{- if not $metadata }}
    {{- fail "[apps.deployment] metadata: required field is missing or empty" }}
  {{- end }}
  {{- if eq (include "base.isFromYamlError" $metadata) "true" }}
    {{- fail "[apps.deployment] metadata: invalid YAML output from definitions.objectMeta" }}
  {{- end }}
  {{- if not (kindIs "map" $metadata) }}
    {{- fail "[apps.deployment] metadata: must be map type" }}
  {{- end }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}

  {{- /*
    Step 3: spec (dict, 必填): 委托 apps.deploymentSpec 渲染
    向下传递 ., 渲染结果缺失 / 为空 / 非法 YAML / 非 dict 类型时立即中断并报错
    兼容 Helm 4.2.2 fromYaml 对非 YAML 输入返回错误 map 的行为, 委托 base.isFromYamlError 检测
  */ -}}
  {{- $specRaw := include "apps.deploymentSpec" . }}
  {{- if not $specRaw }}
    {{- fail "[apps.deployment] spec: required field is missing or empty" }}
  {{- end }}
  {{- $specObj := $specRaw | fromYaml }}
  {{- if not $specObj }}
    {{- fail "[apps.deployment] spec: required field is missing or empty" }}
  {{- end }}
  {{- if eq (include "base.isFromYamlError" $specObj) "true" }}
    {{- fail "[apps.deployment] spec: invalid YAML output from definitions.deploymentSpec" }}
  {{- end }}

  {{- if not (kindIs "map" $specObj) }}
    {{- fail "[apps.deployment] spec: must be dict type" }}
  {{- end }}

  {{- include "base.field" (list "spec" $specObj "base.map") }}
{{- end -}}
