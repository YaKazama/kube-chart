{{- /*
  数据格式：
    - map[preferred required]
*/ -}}
{{- define "definitions.NodeAffinity" -}}
  {{- /* preferredDuringSchedulingIgnoredDuringExecution */ -}}
  {{- $preferredDuringSchedulingIgnoredDuringExecutionVal := include "base.getValue" (list . "preferred") | fromYamlArray }}
  {{- $preferredDuringSchedulingIgnoredDuringExecution := list }}
  {{- range $preferredDuringSchedulingIgnoredDuringExecutionVal }}
    {{- $preferredDuringSchedulingIgnoredDuringExecution = append $preferredDuringSchedulingIgnoredDuringExecution (include "definitions.PreferredSchedulingTerm" . | fromYaml) }}
  {{- end }}
  {{- if $preferredDuringSchedulingIgnoredDuringExecution }}
    {{- include "base.field" (list "preferredDuringSchedulingIgnoredDuringExecution" $preferredDuringSchedulingIgnoredDuringExecution "base.slice") }}
  {{- end }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution */ -}}
  {{- $requiredDuringSchedulingIgnoredDuringExecutionVal := include "base.getValue" (list . "required") | fromYamlArray }}
  {{- $requiredDuringSchedulingIgnoredDuringExecution := include "definitions.NodeSelector" $requiredDuringSchedulingIgnoredDuringExecutionVal | fromYaml }}
  {{- if $requiredDuringSchedulingIgnoredDuringExecution }}
    {{- include "base.field" (list "requiredDuringSchedulingIgnoredDuringExecution" $requiredDuringSchedulingIgnoredDuringExecution "base.map") }}
  {{- end }}
{{- end }}
