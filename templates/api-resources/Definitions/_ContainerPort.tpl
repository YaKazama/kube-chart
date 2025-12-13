{{- define "definitions.ContainerPort" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 此处与其他模板定义处理方式不同 */ -}}
  {{- /* 当只有一个值是，一般来说它是 containerPort */ -}}
  {{- /* 此时在内部会被识别为 float64 类型，但实际上此处应该处理 string 类型 */ -}}
  {{- /* 所以，在此处将上下文赋于 $root 以方例单独处理 float64 类型 */ -}}
  {{- $root := . }}
  {{- if kindIs "float64" . }}
    {{- $root = include "base.int" . }}
  {{- end }}

  {{- $match := regexFindAll $const.regexContainerPort $root -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.ContainerPort: invalid. Values: %s, format: '[hostIP:][hostPort:]containerPort[/protocol][#name]'" .) }}
  {{- end }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* containerPort int */ -}}
  {{- $containerPort := regexReplaceAll $const.regexContainerPort $root "${4}" }}
  {{- if $containerPort }}
    {{- include "base.field" (list "containerPort" $containerPort "base.port") }}
  {{- end }}

  {{- /* hostIP string */ -}}
  {{- $hostIP := regexReplaceAll $const.regexContainerPort $root "${2}" }}
  {{- if $hostIP }}
    {{- include "base.field" (list "hostIP" $hostIP) }}
  {{- end }}

  {{- /* hostPort int */ -}}
  {{- $hostPort := regexReplaceAll $const.regexContainerPort $root "${3}" }}
  {{- if $hostPort }}
    {{- include "base.field" (list "hostPort" $hostPort "base.port") }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexContainerPort $root "${6}" }}
  {{- if and $name (include "base.name" $name) }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* protocol */ -}}
  {{- $protocol := regexReplaceAll $const.regexContainerPort $root "${5}" | upper }}
  {{- $protocolAllows := list "TCP" "UDP" "SCTP" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" $protocol "base.string" $protocolAllows) }}
  {{- end }}
{{- end }}
