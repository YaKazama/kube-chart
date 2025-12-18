{{- define "definitions.PodFailurePolicyOnExitCodesRequirement" -}}
  {{- /* containerName string */ -}}
  {{- $containerName := include "base.getValue" (list . "containerName") }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName) }}
  {{- end }}

  {{- /* operator string */ -}}
  {{- $operator := include "base.getValue" (list . "operator") }}
  {{- $operatorAllows := list "In" "NotIn" }}
  {{- if $operator }}
    {{- if eq $operator "in" }}
      {{- $operator = "In" }}
    {{- else if eq $operator "notin" }}
      {{- $operator = "NotIn" }}
    {{- end }}
    {{- include "base.field" (list "operator" $operator "base.string" $operatorAllows) }}
  {{- end }}

  {{- /* values int array */ -}}
  {{- $values := include "base.getValue" (list . "values") | fromYamlArray }}
  {{- if and (mustHas "0" $values) (eq $operator "In") }}
    {{- fail "definitions.PodFailurePolicyOnExitCodesRequirement: Value '0' cannot be used for the In operator" }}
  {{- end }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
