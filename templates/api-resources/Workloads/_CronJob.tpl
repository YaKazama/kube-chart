{{- define "workloads.CronJob" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "CronJob" }}

  {{- include "base.field" (list "apiVersion" "batch/v1") }}
  {{- include "base.field" (list "kind" "CronJob") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec CronJobSpec */ -}}
  {{- /* fromYaml -> toYamlPretty 双引号会变单引号 */ -}}
  {{- /* Go 的 YAML 编码器（Helm 底层依赖 gopkg.in/yaml.v2）对含特殊字符的字符串，会默认用单引号包裹（避免双引号内的转义问题）。 */ -}}
  {{- $spec := include "workloads.CronJobSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
