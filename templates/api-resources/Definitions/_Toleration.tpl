{{- define "definitions.Toleration" -}}
  {{- /* effect string */ -}}
  {{- $effect := include "base.getValue" (list . "effect") }}
  {{- $effectAllows := list "NoExecute" "NoSchedule" "PreferNoSchedule" }}
  {{- if $effect }}
    {{- include "base.field" (list "effect" $effect "base.string" $effectAllows) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* operator string */ -}}
  {{- $operator := include "base.getValue" (list . "operator") }}
  {{- $operatorAllows := list "Equal" "Exists" }}
  {{- if empty $key }}
    {{- $operator = "Exists" }}
  {{- end }}
  {{- if $operator }}
    {{- include "base.field" (list "operator" $operator "base.string" $operatorAllows) }}
  {{- end }}

  {{- /* tolerationSeconds int */ -}}
  {{- if eq $effect "NoExecute" }}
    {{- $tolerationSeconds := include "base.getValue" (list . "tolerationSeconds" "toString") }}
    {{- if or $tolerationSeconds (eq (int $tolerationSeconds) 0) }}
      {{- include "base.field" (list "tolerationSeconds" $tolerationSeconds "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* value string */ -}}
  {{- if not (eq $operator "Exists") }}
    {{- $value := include "base.getValue" (list . "value") }}
    {{- if $value }}
      {{- include "base.field" (list "value" $value) }}
    {{- end }}
  {{- end }}
{{- end }}
