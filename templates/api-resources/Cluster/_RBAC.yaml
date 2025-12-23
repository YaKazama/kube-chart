{{- define "cluster.RBAC" -}}
  {{- /* 公共值 */ -}}
  {{- $anno := include "base.getValue" (list . "annotations") | fromYaml }}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- $ns := include "base.getValue" (list . "namespace") }}

  {{- /* ServiceAccount */ -}}
  {{- $sa := include "base.getValue" (list . "serviceAccount") | fromYaml }}
  {{- if $sa }}
    {{- nindent 0 "" -}}---

    {{- $val := mustMergeOverwrite $sa (dict "annotations" $anno "labels" $labels "namespace" $ns) }}
    {{- include "cluster.ServiceAccount" $val }}
  {{- end }}

  {{- $isCluster := include "base.getValue" (list . "isCluster") }}
  {{- if $isCluster }}
    {{- /* ClusterRole */ -}}
    {{- nindent 0 "" -}}---

    {{- $role := include "base.getValue" (list . "role") | fromYaml }}

    {{- $name := include "base.getValue" (list . "name") }}
    {{- $fullname := include "base.getValue" (list . "fullname") }}

    {{- $roleVal := mustMergeOverwrite $role (dict "name" $name "fullname" $fullname) (dict "annotations" $anno "labels" $labels "namespace" $ns) }}
    {{- include "cluster.ClusterRole" $roleVal }}

    {{- /* ClusterRoleBinding */ -}}
    {{- nindent 0 "" -}}---

    {{- $roleBinding := include "base.getValue" (list . "roleBinding") | fromYaml }}

    {{- $roleBindingVal := mustMergeOverwrite $roleBinding (dict "name" $name "fullname" $fullname "roleRef" (include "base.name.rbac" (dict "name" $name "fullname" $fullname))) (dict "annotations" $anno "labels" $labels "namespace" $ns) }}

    {{- include "cluster.ClusterRoleBinding" $roleBindingVal }}

  {{- else }}
    {{- /* Role */ -}}
    {{- nindent 0 "" -}}---

    {{- $role := include "base.getValue" (list . "role") | fromYaml }}

    {{- $name := include "base.getValue" (list . "name") }}
    {{- $fullname := include "base.getValue" (list . "fullname") }}

    {{- $roleVal := mustMergeOverwrite $role (dict "name" $name "fullname" $fullname) (dict "annotations" $anno "labels" $labels "namespace" $ns) }}
    {{- include "cluster.Role" $roleVal }}

    {{- /* RoleBinding */ -}}
    {{- nindent 0 "" -}}---

    {{- $roleBinding := include "base.getValue" (list . "roleBinding") | fromYaml }}

    {{- $roleBindingVal := mustMergeOverwrite $roleBinding (dict "name" $name "fullname" $fullname "roleRef" (include "base.name.rbac" (dict "name" $name "fullname" $fullname))) (dict "annotations" $anno "labels" $labels "namespace" $ns) }}

    {{- include "cluster.RoleBinding" $roleBindingVal }}
  {{- end }}
{{- end }}
