{{- define "gcp.backend.Logging" -}}
  {{- /* enable bool */ -}}
  {{- $enable := include "base.getValue" (list . "enable") }}
  {{- if $enable }}
    {{- include "base.field" (list "enable" $enable "base.bool") }}
  {{- end }}

  {{- /* sampleRate int/float64 */ -}}
  {{- if $enable }}
    {{- $sampleRate := include "base.getValue" (list . "sampleRate") }}
    {{- if $sampleRate }}
      {{- include "base.field" (list "sampleRate" (list (float64 $sampleRate) 0.0 1.0) "base.int.range") }}
    {{- end }}
  {{- end }}
{{- end }}
