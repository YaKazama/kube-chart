{{- /* strategy map */ -}}
{{- /* 为空或未定义时，使用默认设置 RollingUpdate 25% 25% */ -}}
{{- $strategyVal := include "base.getValue" (list . "strategy") }}
{{- $match := regexFindAll $const.k8s.strategy.deployment $strategyVal -1 }}
{{- if $match }}
  {{- /* 相对较简单，一次性处理完成 */ -}}
  {{- $type := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${1}" }}
  {{- $maxSurge := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${2}" }}
  {{- $maxUnavailable := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${3}" }}
  {{- $val := dict "type" $type "rollingUpdate" (dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable) }}

  {{- $strategy := include "workloads.DeploymentStrategy" $val | fromYaml }}
  {{- if $strategy }}
    {{- include "base.field" (list "strategy" $strategy "base.map") }}
  {{- end }}
{{- end }}
