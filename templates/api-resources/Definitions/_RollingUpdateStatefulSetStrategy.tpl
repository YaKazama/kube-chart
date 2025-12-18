{{- /*
  数据格式：
    - map[maxUnavailable: <int | percent> partition: <int>]
*/ -}}
{{- define "definitions.RollingUpdateStatefulSetStrategy" -}}
  {{- /* maxUnavailable string or int */ -}}
  {{- $maxUnavailable := include "base.getValue" (list . "maxUnavailable") }}
  {{- if $maxUnavailable }}
    {{- include "base.field" (list "maxUnavailable" $maxUnavailable "base.RollingUpdate") }}
  {{- end }}

  {{- /* partition int */ -}}
  {{- $partition := include "base.getValue" (list . "partition") }}
  {{- if $partition }}
    {{- include "base.field" (list "partition" $partition "base.int.positive") }}
  {{- end }}
{{- end }}
