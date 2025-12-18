{{- define "definitions.SELinuxOptions" -}}
  {{- /* level */ -}}
  {{- $level := include "base.getValue" (list . "level") }}
  {{- if $level }}
    {{- include "base.field" (list "level" $level) }}
  {{- end }}

  {{- /* role */ -}}
  {{- $role := include "base.getValue" (list . "role") }}
  {{- if $role }}
    {{- include "base.field" (list "role" $role) }}
  {{- end }}

  {{- /* type */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}

  {{- /* user */ -}}
  {{- $user := include "base.getValue" (list . "user") }}
  {{- if $user }}
    {{- include "base.field" (list "user" $user) }}
  {{- end }}
{{- end }}
