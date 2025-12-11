{{- define "definitions.VolumeNodeAffinity" -}}
  {{- /* required map */ -}}
  {{- $requiredVal := include "base.getValue" (list . "required") | fromYaml }}
  {{- if $requiredVal }}
    {{- $required := include "definitions.NodeSelector" $requiredVal | fromYaml }}
    {{- if $required }}
      {{- include "base.field" (list "required" $required "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
