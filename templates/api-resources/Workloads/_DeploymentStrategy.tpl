{{- /*
  数据格式：
    - Recreate
    - RollingUpdate
    - RollingUpdate 0 1
    - RollingUpdate 1 2
    - RollingUpdate 0 25%
    - RollingUpdate 25% 0
    - RollingUpdate 50% 50%
*/ -}}
{{- define "workloads.DeploymentStrategy" -}}
  {{- $regexStrategy := "^Recreate|RollingUpdate(\\s+\\d+(\\%)?){0,2}$" }}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- if not (mustRegexMatch $regexStrategy .) }}
    {{- fail "DeploymentStrategy: strategy must string. Format: <Recreate|RollingUpdate> [maxSurge(25%)][maxUnavailable(25%)]" }}
  {{- end }}

  {{- $val := mustRegexSplit $const.regexSplitStr . -1 }}

  {{- /* type */ -}}
  {{- $type := index $val 0 }}
  {{- $typeAllows := list "Recreate" "RollingUpdate" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* rollingUpdate */ -}}
  {{- if or (eq $type "RollingUpdate") (empty $type) }}
    {{- $rollingUpdateVal := dict }}
    {{- $_ := set $rollingUpdateVal "maxSurge" "25%" }}
    {{- $_ := set $rollingUpdateVal "maxUnavailable" "25%" }}
    {{- $len := len $val }}
    {{- if and (eq $len 2) (ne (index $val 1) "0") }}   {{- /* 没有将 0 转换为 int 而是直接使用 string 类型比较 下同 */ -}}
      {{- $_ := set $rollingUpdateVal "maxSurge" (index $val 1) }}
    {{- else if and (eq $len 3) (or (ne (index $val 1) "0") (ne (index $val 2) "0")) }}
      {{- $_ := set $rollingUpdateVal "maxSurge" (index $val 1) }}
      {{- $_ := set $rollingUpdateVal "maxUnavailable" (index $val 2) }}
    {{- end }}

    {{- $rollingUpdate := include "workloads.RollingUpdateDeployment" $rollingUpdateVal | fromYaml }}
    {{- if $rollingUpdate }}
      {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
