{{- define "definitions.ContainerRestartRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* action string */ -}}
  {{- $action := include "base.getValue" (list . "action") }}
  {{- if $action }}
    {{- include "base.field" (list "action" $action) }}
  {{- end }}

  {{- /* exitCodes map */ -}}
  {{- $exitCodesVal := include "base.getValue" (list . "exitCodes") }}
  {{- if $exitCodesVal }}
    {{- $operator := regexReplaceAll $const.k8s.container.exitCodes $exitCodesVal "${1}" | trim }}
    {{- $values := regexReplaceAll $const.k8s.container.exitCodes $exitCodesVal "${2}" | trim }}

    {{- if eq $operator "in" }}
      {{- $operator = "In" }}
    {{- else if eq $operator "notin" }}
      {{- $operator = "NotIn" }}
    {{- end }}

    {{- $val := dict "operator" $operator "values" (include "base.slice.cleanup" (dict "s" $values "r" $const.split.comma "c" $const.types.positiveInt) | fromYamlArray) }}

    {{- $exitCodes := include "definitions.ContainerRestartRuleOnExitCodes" $val | fromYaml }}
    {{- if $exitCodes }}
      {{- include "base.field" (list "exitCodes" $exitCodes "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
