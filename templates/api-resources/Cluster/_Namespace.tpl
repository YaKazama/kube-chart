{{- define "cluster.Namespace" -}}
  {{- $_ := set . "_kind" "Namespace" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "Namespace") }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 使用 name namespace 重写 name 字段，同时判断 name 是否符合约定 */ -}}
  {{- /* name namespace 不能使用 default 或 kube-* */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- $ns := coalesce $namespace $name }}
  {{- if and $ns (regexMatch $const.k8s.reservedNamespace $ns) }}
    {{- fail (printf "Namespace: namespace '%s' cannot be empty or use 'default' or start with 'kube-'." $ns) }}
  {{- end }}
  {{- $_ := set . "name" $ns }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}
{{- end }}
