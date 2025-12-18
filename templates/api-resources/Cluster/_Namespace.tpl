{{- define "cluster.Namespace" -}}
  {{- $_ := set . "_kind" "Namespace" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "Namespace") }}

  {{- /* 使用 name namespace 重写 name 字段，同时判断 name 是否符合约定 */ -}}
  {{- /* name namespace 不能使用 default 或 kube-* */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- $ns := coalesce $name $namespace }}
  {{- if and $ns (regexMatch $const.k8s.reservedNamespace $ns) }}
    {{- fail (printf "Namespace: namespace '%s' cannot be empty or use 'default' or start with 'kube-'." $ns) }}
  {{- end }}
  {{- $_ := set . "name" (coalesce $name $namespace) }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}
{{- end }}
