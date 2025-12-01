{{- define "definitions.StatefulSetUpdateStrategy" -}}
  {{- $regex := "^(OnDelete|RollingUpdate)?(?:\\s*(\\d+\\%?))?(?:\\s*(\\d+))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "StatefulSetUpdateStrategy: error. Values: %s, format: '[OnDelete|RollingUpdate] [maxUnavailable] [partition]'" .) }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := regexReplaceAll $regex . "${1}" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}

  {{- /* rollingUpdate map */ -}}
  {{- if or (eq $type "RollingUpdate") (empty $type) }}
    {{- $_maxUnavailable := regexReplaceAll $regex . "${2}" }}
    {{- $_partition := regexReplaceAll $regex . "${3}" }}
    {{- $rollingUpdateVal := dict }}
    {{- if $_maxUnavailable }}
      {{- $_ := set $rollingUpdateVal "maxUnavailable" $_maxUnavailable }}
    {{- end }}
    {{- if $_partition }}
      {{- $_ := set $rollingUpdateVal "partition" $_partition }}
    {{- end }}
    {{- if $rollingUpdateVal }}
      {{- $rollingUpdate := include "definitions.RollingUpdateStatefulSetStrategy" $rollingUpdateVal | fromYaml }}
      {{- if $rollingUpdate }}
        {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
