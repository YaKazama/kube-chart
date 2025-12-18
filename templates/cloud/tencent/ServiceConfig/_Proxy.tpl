{{- define "serviceConfig.Proxy" -}}
  {{- /* enable bool */ -}}
  {{- $enable := include "base.getValue" (list . "enable") }}
  {{- if $enable }}
    {{- include "base.field" (list "enable" $enable "base.bool") }}
  {{- end }}
{{- end }}
