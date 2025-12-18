{{- define "definitions.LabelSelectorRequirement" -}}
  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* operator string */ -}}
  {{- $operator := include "base.getValue" (list . "operator") }}
  {{- $operatorAllows := list "In" "NotIn" "Exists" "DoesNotExist" }}
  {{- if $operator }}
    {{- include "base.field" (list "operator" $operator "base.string" $operatorAllows) }}
  {{- end }}

  {{- /* values string array */ -}}
  {{- $values := include "base.getValue" (list . "values") | fromYamlArray }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
