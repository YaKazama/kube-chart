{{- define "definitions.AppArmorProfile" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Localhost" "RuntimeDefault" "Unconfined" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* localhostProfile string */ -}}
  {{- if eq $type "Localhost" }}
    {{- $localhostProfile := include "base.getValue" (list . "localhostProfile") }}
    {{- if empty $localhostProfile }}
      {{- fail "definitions.AppArmorProfile: securityContext.appArmorProfile.localhostProfile must be set" }}
    {{- end }}
    {{- if $localhostProfile }}
      {{- include "base.field" (list "localhostProfile" $localhostProfile) }}
    {{- end }}
  {{- end }}
{{- end }}
