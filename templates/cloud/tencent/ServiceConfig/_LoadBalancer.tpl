{{- define "serviceConfig.LoadBalancer" -}}
  {{- /* l4Listeners array */ -}}
  {{- $l4ListenersVal := include "base.getValue" (list . "l4Listeners") | fromYamlArray }}
  {{- $l4Listeners := list }}
  {{- range $l4ListenersVal }}
    {{- $l4Listeners = append $l4Listeners (include "serviceConfig.L4Listener" . | fromYaml) }}
  {{- end }}
  {{- $l4Listeners = $l4Listeners | mustUniq | mustCompact }}
  {{- if $l4Listeners }}
    {{- include "base.field" (list "l4Listeners" $l4Listeners "base.slice") }}
  {{- end }}

  {{- /* l7Listeners array */ -}}
  {{- $l7ListenersVal := include "base.getValue" (list . "l7Listeners") | fromYamlArray }}
  {{- $l7Listeners := list }}
  {{- range $l7ListenersVal }}
    {{- $l7Listeners = append $l7Listeners (include "serviceConfig.L7Listener" . | fromYaml) }}
  {{- end }}
  {{- $l7Listeners = $l7Listeners | mustUniq | mustCompact }}
  {{- if $l7Listeners }}
    {{- include "base.field" (list "l7Listeners" $l7Listeners "base.slice") }}
  {{- end }}
{{- end }}
