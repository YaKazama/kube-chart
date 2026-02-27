{{- define "definitions.EndpointHints" -}}
  {{- /* forNodes array */ -}}
  {{- $forNodesVal := include "base.getValue" (list . "forNodes") | fromYamlArray }}
  {{- $forNodes := list }}
  {{- range $forNodesVal }}
    {{- $forNodes = append $forNodes (include "definitions.ForNode" . | fromYaml) }}
  {{- end }}
  {{- $forNodes = $forNodes | mustUniq | mustCompact }}
  {{- if gt (len $forNodes) 8 }}
    {{- $forNodes = slice $forNodes 0 8 }}
  {{- end }}
  {{- if $forNodes }}
    {{- include "base.field" (list "forNodes" $forNodes "base.slice") }}
  {{- end }}

  {{- /* forZones array */ -}}
  {{- $forZonesVal := include "base.getValue" (list . "forZones") | fromYamlArray }}
  {{- $forZones := list }}
  {{- range $forZonesVal }}
    {{- $forZones = append $forZones (include "definitions.ForZone" . | fromYaml) }}
  {{- end }}
  {{- $forZones = $forZones | mustUniq | mustCompact }}
  {{- if gt (len $forZones) 8 }}
    {{- $forZones = slice $forZones 0 8 }}
  {{- end }}
  {{- if $forZones }}
    {{- include "base.field" (list "forZones" $forZones "base.slice") }}
  {{- end }}
{{- end }}
