{{- define "kustomization.OpenAPI" -}}
  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path) }}
  {{- end }}

  {{- /* version string */ -}}
  {{- $version := include "base.getValue" (list . "version") }}
  {{- if $version }}
    {{- include "base.field" (list "version" $version) }}
  {{- end }}
{{- end }}
