{{- define "definitions.StatefulSetUpdateStrategy" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}

  {{- /* rollingUpdate map */ -}}
  {{- if or (eq $type "RollingUpdate") (empty $type) }}
    {{- $rollingUpdateVal := include "base.getValue" (list . "rollingUpdate") | fromYaml }}
    {{- if $rollingUpdateVal }}
      {{- $rollingUpdate := include "definitions.RollingUpdateStatefulSetStrategy" $rollingUpdateVal | fromYaml }}
      {{- if $rollingUpdate }}
        {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
