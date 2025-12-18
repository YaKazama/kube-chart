{{- define "serviceConfig.Session" -}}
  {{- /* enable bool */ -}}
  {{- $enable := include "base.getValue" (list . "enable") }}
  {{- if $enable }}
    {{- include "base.field" (list "enable" $enable "base.bool") }}
  {{- end }}

  {{- /* sessionExpireTime int */ -}}
  {{- $sessionExpireTime := include "base.getValue" (list . "sessionExpireTime") }}
  {{- if $sessionExpireTime }}
    {{- include "base.field" (list "sessionExpireTime" (list (int $sessionExpireTime) 30 3600) "base.int.range") }}
  {{- end }}
{{- end }}
