{{- define "cluster.Role" -}}
  {{- $_ := set . "_kind" "Role" }}

  {{- include "base.field" (list "apiVersion" "rbac.authorization.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "Role") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- $rules := list }}
  {{- range $rulesVal }}
    {{- $rules = append $rules (include "definitions.PolicyRule" . | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice.quote") }}
  {{- end }}
{{- end }}
