{{- define "definitions.SecretKeySelector" -}}
  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* optional bool */ -}}
  {{- $optional := include "base.getValue" (list . "optional") }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
