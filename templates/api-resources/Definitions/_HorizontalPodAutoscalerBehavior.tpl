{{- define "definitions.HorizontalPodAutoscalerBehavior" -}}
  {{- /* scaleDown map */ -}}
  {{- $scaleDownVal := include "base.getValue" (list . "scaleDown") | fromYaml }}
  {{- if $scaleDownVal }}
    {{- $scaleDown := include "definitions.HPAScalingRules" $scaleDownVal | fromYaml }}
    {{- if $scaleDown }}
      {{- include "base.field" (list "scaleDown" $scaleDown "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* scaleUp map */ -}}
  {{- $scaleUpVal := include "base.getValue" (list . "scaleUp") | fromYaml }}
  {{- if $scaleUpVal }}
    {{- $scaleUp := include "definitions.HPAScalingRules" $scaleUpVal | fromYaml }}
    {{- if $scaleUp }}
      {{- include "base.field" (list "scaleUp" $scaleUp "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
