{{- define "definitions.Capabilities" -}}
  {{- /* add string array */ -}}
  {{- $add := include "base.getValue" (list . "add") | fromYamlArray }}
  {{- if $add }}
    {{- include "base.field" (list "add" $add "base.slice") }}
  {{- end }}

  {{- /* drop string array */ -}}
  {{- $drop := include "base.getValue" (list . "drop") | fromYamlArray }}
  {{- if $drop }}
    {{- include "base.field" (list "drop" $drop "base.slice") }}
  {{- end }}
{{- end }}
