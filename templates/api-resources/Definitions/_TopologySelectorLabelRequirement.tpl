{{- define "definitions.TopologySelectorLabelRequirement" -}}
  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* values string array */ -}}
  {{- $values := include "base.getValue" (list . "values") | fromYamlArray }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
