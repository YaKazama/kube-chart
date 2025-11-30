{{- define "definitions.SeccompProfile" -}}
  {{- /* type */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Localhost" "RuntimeDefault" "Unconfined" }}
  {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}

  {{- /* localhostProfile */ -}}
  {{- $localhostProfile := include "base.getValue" (list . "localhostProfile") }}
  {{- if and (eq $type "Localhost") (empty $localhostProfile) }}
    {{- fail "securityContext.appArmorProfile.localhostProfile must be set" }}
  {{- end }}
  {{- if eq $type "Localhost" }}
    {{- include "base.field" (list "localhostProfile" $localhostProfile) }}
  {{- end }}
{{- end }}
