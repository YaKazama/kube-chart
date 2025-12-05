{{- define "definitions.ContainerRestartRuleOnExitCodes" -}}
  {{- /* operator string */ -}}
  {{- $operator := include "base.getValue" (list . "operator") }}
  {{- if $operator }}
    {{- if eq $operator "in" }}
      {{- $operator = "In" }}
    {{- else if eq $operator "notin" }}
      {{- $operator = "NotIn" }}
    {{- end }}
    {{- include "base.field" (list "operator" $operator) }}
  {{- end }}

  {{- /* values int array */ -}}
  {{- $values := include "base.getValue" (list . "values") | fromYamlArray }}
  {{- if gt (len $values) 255 }}
    {{- $values = slice $values 0 255 }}
  {{- end }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
