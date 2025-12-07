{{- define "service.IngressClassSpec" -}}
  {{- /* controller string */ -}}
  {{- $controller := include "base.getValue" (list . "controller") }}
  {{- if $controller }}
    {{- include "base.field" (list "controller" $controller) }}
  {{- end }}

  {{- /* parameters map */ -}}
  {{- $parametersVal := include "base.getValue" (list . "parameters") | fromYaml }}
  {{- if $parametersVal }}
    {{- $parameters := include "definitions.IngressClassParametersReference" $parametersVal | fromYaml }}
    {{- if $parameters }}
      {{- include "base.field" (list "parameters" $parameters "base.map") }}
    {{- end }}
  {{- end }}

{{- end }}
