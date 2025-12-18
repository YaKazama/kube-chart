{{- define "kustomization.PatchesOption" -}}
  {{- /* allowNameChange bool */ -}}
  {{- $allowNameChange := include "base.getValue" (list . "allowNameChange") }}
  {{- if $allowNameChange }}
    {{- include "base.field" (list "allowNameChange" $allowNameChange "base.bool") }}
  {{- end }}

  {{- /* allowKindChange bool */ -}}
  {{- $allowKindChange := include "base.getValue" (list . "allowKindChange") }}
  {{- if $allowKindChange }}
    {{- include "base.field" (list "allowKindChange" $allowKindChange "base.bool") }}
  {{- end }}
{{- end }}
