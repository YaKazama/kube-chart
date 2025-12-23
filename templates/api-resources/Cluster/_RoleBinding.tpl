{{- define "cluster.RoleBinding" -}}
  {{- $_ := set . "_kind" "RoleBinding" }}

  {{- include "base.field" (list "apiVersion" "rbac.authorization.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "RoleBinding") }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* roleRef map */ -}}
  {{- $roleRefVal := include "base.getValue" (list . "roleRef") }}
  {{- if $roleRefVal }}
    {{- /* 兼容 string 和 map */ -}}
    {{- /* string 格式会直接作为 name 属性的值，因为 kind 和 apiGroup 理论上是个固定值 */ -}}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($roleRefVal | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($roleRefVal | fromYaml) }}
    {{- $val := dict }}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = dict "apiGroup" "rbac.authorization.k8s.io" "kind" "Role" "name" $roleRefVal }}
    {{- else if eq $isNotMap "false" }}
      {{- $val = pick $roleRefVal "apiGroup" "kind" "name" }}
    {{- end }}
    {{- $roleRef := include "definitions.RoleRef" $val | fromYaml }}
    {{- if $roleRef }}
      {{- include "base.field" (list "roleRef" $roleRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* subjects array */ -}}
  {{- $subjectsVal := include "base.getValue" (list . "subjects") | fromYamlArray }}
  {{- $subjects := list }}
  {{- range $subjectsVal }}
    {{- $val := dict }}
    {{- if kindIs "string" . }}
      {{- $match := regexFindAll $const.k8s.rbac.subject . -1 }}
      {{- if not $match }}
        {{- fail (printf "cluster.RoleBinding: subjects invalid. Values: '%s', format: 'kind name [namespace|apiGroup]'" .) }}
      {{- end }}

      {{- $val := dict }}
      {{- $kind := regexReplaceAll $const.k8s.rbac.subject . "${1}" | trim }}
      {{- $name := regexReplaceAll $const.k8s.rbac.subject . "${2}" | trim }}
      {{- $apiGroup := regexReplaceAll $const.k8s.rbac.subject . "${3}" | trim }}
      {{- $val = dict "kind" $kind "name" $name "apiGroup" $apiGroup }}
      {{- if eq $kind "ServiceAccount" }}
        {{- $namespace := regexReplaceAll $const.k8s.rbac.subject . "${3}" | trim }}
        {{- if empty $namespace }}
          {{- fail "cluster.RoleBinding: kind=ServiceAccount, namespace cannot be empty." }}
        {{- end }}
        {{- $val = dict "kind" $kind "name" $name "namespace" $namespace }}
      {{- end }}

      {{- $subjects = append $subjects (include "old.Subject" $val | fromYaml) }}

    {{- else if kindIs "map" . }}
      {{- $subjects = append $subjects (include "old.Subject" . | fromYaml) }}
    {{- end }}
  {{- end }}
  {{- $subjects = $subjects | mustUniq | mustCompact }}
  {{- if $subjects }}
    {{- include "base.field" (list "subjects" $subjects "base.slice") }}
  {{- end }}
{{- end }}
