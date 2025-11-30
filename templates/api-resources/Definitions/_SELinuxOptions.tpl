{{- define "definitions.SELinuxOptions" -}}
  {{- /* level */ -}}
  {{- $level := include "base.getValue" (list . "level") }}
  {{- include "base.field" (list "level" $level) }}

  {{- /* role */ -}}
  {{- $role := include "base.getValue" (list . "role") }}
  {{- include "base.field" (list "role" $role) }}

  {{- /* type */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- include "base.field" (list "type" $type) }}

  {{- /* user */ -}}
  {{- $user := include "base.getValue" (list . "user") }}
  {{- include "base.field" (list "user" $user) }}
{{- end }}
