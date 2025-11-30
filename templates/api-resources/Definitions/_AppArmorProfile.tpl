{{- define "definitions.AppArmorProfile" -}}
  {{- /* type */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Localhost" "RuntimeDefault" "Unconfined" }}
  {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}

  {{- /* localhostProfile */ -}}
  {{- $localhostProfile := include "base.getValue" (list . "localhostProfile") }}
  {{- if and (eq $type "Localhost") (empty $localhostProfile) }}
    {{- fail "securityContext.appArmorProfile.localhostProfile must be set" }}
  {{- end }}
  {{- include "base.field" (list "localhostProfile" $localhostProfile) }}
{{- end }}
