{{- define "definitions.PolicyRule" -}}
  {{- /* apiGroups string array */ -}}
  {{- $apiGroups := include "base.getValue" (list . "apiGroups") | fromYamlArray }}
  {{- if $apiGroups }}
    {{- include "base.field" (list "apiGroups" $apiGroups "base.slice") }}
  {{- end }}

  {{- /* nonResourceURLs string array */ -}}
  {{- $nonResourceURLs := include "base.getValue" (list . "nonResourceURLs") | fromYamlArray }}
  {{- if $nonResourceURLs }}
    {{- include "base.field" (list "nonResourceURLs" $nonResourceURLs "base.slice") }}
  {{- end }}

  {{- /* resourceNames string array */ -}}
  {{- $resourceNames := include "base.getValue" (list . "resourceNames") | fromYamlArray }}
  {{- if $resourceNames }}
    {{- include "base.field" (list "resourceNames" $resourceNames "base.slice") }}
  {{- end }}

  {{- /* resources string array */ -}}
  {{- $resources := include "base.getValue" (list . "resources") | fromYamlArray }}
  {{- if $resources }}
    {{- include "base.field" (list "resources" $resources "base.slice") }}
  {{- end }}

  {{- /* verbs string array */ -}}
  {{- $verbs := include "base.getValue" (list . "verbs") | fromYamlArray }}
  {{- if $verbs }}
    {{- include "base.field" (list "verbs" $verbs "base.slice") }}
  {{- end }}
{{- end }}
