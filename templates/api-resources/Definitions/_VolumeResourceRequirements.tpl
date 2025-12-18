{{- define "definitions.VolumeResourceRequirements" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* limits map */ -}}
  {{- $limits := include "base.getValue" (list . "limits") | fromYaml }}
  {{- if $limits }}
    {{- include "base.field" (list "limits" (list $limits $const.k8s.resources) "base.map.verify") }}
  {{- end }}

  {{- /* requests map */ -}}
  {{- $requests := include "base.getValue" (list . "requests") | fromYaml }}
  {{- if $requests }}
    {{- include "base.field" (list "requests" (list $requests $const.k8s.resources)  "base.map.verify") }}
  {{- end }}
{{- end }}
