{{- define "definitions.VolumeResourceRequirements" -}}
  {{- $const := include "base.env" . | fromYaml }}

  {{- /* limits map */ -}}
  {{- $limitsVal := include "base.getValue" (list . "limits") }}
  {{- $limits := dict }}
  {{- if regexMatch $const.regexResources $limitsVal }}
    {{- $_ := set $limits "storage" $limitsVal }}
  {{- end }}
  {{- if $limits }}
    {{- include "base.field" (list "limits" $limits "base.map") }}
  {{- end }}

  {{- /* requests map */ -}}
  {{- $requestsVal := include "base.getValue" (list . "requests") }}
  {{- $requests := dict }}
  {{- if regexMatch $const.regexResources $requestsVal }}
    {{- $_ := set $requests "storage" $requestsVal }}
  {{- end }}
  {{- if $requests }}
    {{- include "base.field" (list "requests" $requests "base.map") }}
  {{- end }}
{{- end }}
