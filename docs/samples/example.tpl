{{- /* strategy map */ -}}
{{- /* 为空或未定义时，使用默认设置 RollingUpdate 25% 25% */ -}}
{{- $strategyVal := include "base.getValue" (list . "strategy") }}
{{- $match := regexFindAll $const.k8s.strategy.deployment $strategyVal -1 }}
{{- if $match }}
  {{- /* 相对较简单，一次性处理完成 */ -}}
  {{- $type := mustRegexReplaceAll $const.k8s.strategy.deployment $strategyVal "${1}" | trim }}
  {{- $maxSurge := mustRegexReplaceAll $const.k8s.strategy.deployment $strategyVal "${2}" | trim }}
  {{- $maxUnavailable := mustRegexReplaceAll $const.k8s.strategy.deployment $strategyVal "${3}" | trim }}
  {{- $val := dict "type" $type "rollingUpdate" (dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable) }}

  {{- $strategy := include "workloads.DeploymentStrategy" $val | fromYaml }}
  {{- if $strategy }}
    {{- include "base.field" (list "strategy" $strategy "base.map") }}
  {{- end }}
{{- end }}

{{- define "workloads.DeploymentStrategy" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Recreate" "RollingUpdate" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* rollingUpdate map */ -}}
  {{- if or (eq $type "RollingUpdate") (empty $type) }}
    {{- $rollingUpdateVal := include "base.getValue" (list . "rollingUpdate") | fromYaml }}
    {{- if $rollingUpdateVal }}
      {{- $rollingUpdate := include "workloads.RollingUpdateDeployment" $rollingUpdateVal | fromYaml }}
      {{- if $rollingUpdate }}
        {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
