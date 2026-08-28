{{- /*
  功能：渲染单个 Kubernetes apps/v1 Deployment 资源。
  边界：固定资源身份，metadata 与 spec 委托给对应子模板；不输出 status、文档分隔符或其他资源。
  入参：父模板当前的可写 map 上下文 .；原地覆盖 _kind 后直接传递给 definitions.objectMeta 与 apps.deploymentSpec。
  返回值：包含 apiVersion、kind、metadata 与 spec 的单个 Deployment YAML 字符串。
  最小示例：{{ include "apps.deployment" . }}
*/ -}}
{{- define "apps.deployment" -}}
  {{- $_ := set . "_kind" "Deployment" -}}

  {{- /* apiVersion（string）：标识资源使用的版本化 Kubernetes API schema。 */ -}}
  {{- nindent 0 "" -}}apiVersion: "apps/v1"

  {{- /* kind（string）：标识该 REST 资源的类型为 Deployment。 */ -}}
  {{- nindent 0 "" -}}kind: "Deployment"

  {{- /* metadata（ObjectMeta）：承载标准 Kubernetes 对象元数据。 */ -}}
  {{- $_metadataRaw := include "definitions.objectMeta" . -}}
  {{- if not $_metadataRaw }}
    {{- fail "[apps.deployment] metadata: required field is missing or empty" }}
  {{- end }}
  {{- $__metadataEnvelope := printf "value:%s" ($_metadataRaw | nindent 2) | fromYaml -}}
  {{- if eq (include "base.isFromYamlError" $__metadataEnvelope) "true" }}
    {{- fail "[apps.deployment] metadata: invalid YAML output from definitions.objectMeta" }}
  {{- end }}
  {{- if not (kindIs "map" $__metadataEnvelope) }}
    {{- fail "[apps.deployment] metadata: invalid YAML output from definitions.objectMeta" }}
  {{- end }}
  {{- $metadata := get $__metadataEnvelope "value" -}}
  {{- if not (kindIs "map" $metadata) }}
    {{- fail "[apps.deployment] metadata: must be map type" }}
  {{- end }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}

  {{- /* spec（DeploymentSpec）：描述 Deployment 的期望行为。 */ -}}
  {{- $_specRaw := include "apps.deploymentSpec" . -}}
  {{- if not $_specRaw }}
    {{- fail "[apps.deployment] spec: required field is missing or empty" }}
  {{- end }}
  {{- $__specEnvelope := printf "value:%s" ($_specRaw | nindent 2) | fromYaml -}}
  {{- if eq (include "base.isFromYamlError" $__specEnvelope) "true" }}
    {{- fail "[apps.deployment] spec: invalid YAML output from apps.deploymentSpec" }}
  {{- end }}
  {{- if not (kindIs "map" $__specEnvelope) }}
    {{- fail "[apps.deployment] spec: invalid YAML output from apps.deploymentSpec" }}
  {{- end }}
  {{- $spec := get $__specEnvelope "value" -}}
  {{- if not (kindIs "map" $spec) }}
    {{- fail "[apps.deployment] spec: must be map type" }}
  {{- end }}
  {{- include "base.field" (list "spec" $spec "base.map") }}
{{- end }}
