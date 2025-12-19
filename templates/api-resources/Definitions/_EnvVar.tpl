{{- define "definitions.EnvVar" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* value string */ -}}
  {{- /* valueFrom map */ -}}
  {{- $value := include "base.getValue" (list . "value") }}
  {{- $valueFromVal := include "base.getValue" (list . "valueFrom") }}
  {{- if $value }}
    {{- include "base.field" (list "value" $value) }}

  {{- else if $valueFromVal }}
    {{- $match := regexFindAll $const.k8s.container.envVar $valueFromVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.EnvVarSource: env.valueFrom invalid, must start with 'cm|configMap|field|file|resource|secret'. Values: '%s'" $valueFromVal) }}
    {{- end }}

    {{- $val := dict }}

    {{- $_key := regexReplaceAll $const.k8s.container.envVar $valueFromVal "${1}" | lower | trim }}
    {{- $_value := regexReplaceAll $const.k8s.container.envVar $valueFromVal "${2}" | trim }}
    {{- if or (eq $_key "configMap") (eq $_key "configmap") (eq $_key "cm") }}
      {{- $val = dict "configMapKeyRef" $_value }}

    {{- else if eq $_key "field" }}
      {{- $val = dict "fieldRef" $_value }}

    {{- else if eq $_key "file" }}
      {{- $val = dict "fileKeyRef" $_value }}

    {{- else if eq $_key "resource" }}
      {{- $val = dict "resourceFieldRef" $_value }}

    {{- else if eq $_key "secret" }}
      {{- $val = dict "secretKeyRef" $_value }}
    {{- end }}

    {{- $valueFrom := include "definitions.EnvVarSource" $val | fromYaml }}
    {{- if $valueFrom }}
      {{- include "base.field" (list "valueFrom" $valueFrom "base.map") }}
    {{- end }}
  {{- else }}
    {{- fail "definitions.EnvVar: env.value or env.valueFrom cannot be empty" }}
  {{- end }}
{{- end }}
