{{- define "kustomization.HelmGlobal" -}}
  {{- /* chartHome string */ -}}
  {{- $chartHome := include "base.getValue" (list . "chartHome") }}
  {{- if $chartHome }}
    {{- include "base.field" (list "chartHome" $chartHome) }}
  {{- end }}

  {{- /* configHome string */ -}}
  {{- $configHome := include "base.getValue" (list . "configHome") }}
  {{- if $configHome }}
    {{- include "base.field" (list "configHome" $configHome) }}
  {{- end }}
{{- end }}
