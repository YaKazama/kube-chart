{{- define "cluster.RoleBinding" -}}
  {{- $_ := set . "_kind" "RoleBinding" }}

  {{- include "base.field" (list "apiVersion" "rbac.authorization.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "RoleBinding") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* roleRef map */ -}}
  {{- $roleRefVal := include "base.getValue" (list . "roleRef") | fromYaml }}
  {{- if $roleRefVal }}
    {{- $roleRef := include "definitions.RoleRef" $roleRefVal | fromYaml }}
    {{- if $roleRef }}
      {{- include "base.field" (list "roleRef" $roleRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* subjects array */ -}}
  {{- $subjectsVal := include "base.getValue" (list . "subjects") | fromYamlArray }}
  {{- $subjects := list }}
  {{- range $subjectsVal }}
    {{- $subjects = append $subjects (include "old.Subject" . | fromYaml) }}
  {{- end }}
  {{- $subjects = $subjects | mustUniq | mustCompact }}
  {{- if $subjects }}
    {{- include "base.field" (list "subjects" $subjects "base.slice") }}
  {{- end }}
{{- end }}
