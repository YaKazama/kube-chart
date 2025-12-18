{{- define "kustomization.Image" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* newTag string */ -}}
  {{- $newTag := include "base.getValue" (list . "newTag") }}
  {{- if $newTag }}
    {{- include "base.field" (list "newTag" $newTag) }}
  {{- end }}

  {{- /* newName string */ -}}
  {{- $newName := include "base.getValue" (list . "newName") }}
  {{- if $newName }}
    {{- include "base.field" (list "newName" $newName) }}
  {{- end }}

  {{- /* digest string */ -}}
  {{- $digest := include "base.getValue" (list . "digest") }}
  {{- if $digest }}
    {{- include "base.field" (list "digest" $digest) }}
  {{- end }}
{{- end }}
