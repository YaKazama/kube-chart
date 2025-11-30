{{- /*
  数据格式：
    - cpu memory hugepages-size hugepages-max
    - map[map[limits: map[cpu: 1 memory: 1Gi hugepages]] map[requests: map[cpu: 1 memory: 1Gi hugepages-2Mi: 10Mi]]]

  支持四段式 (cpu memory hugepages-size hugepages-max) 字符串，也可以使用 map
*/ -}}
{{- define "definitions.ResourceRequirements" -}}
  {{- /*
    {{- if not (hasKey . "requests") }}
    {{- fail (printf "resources.requests must be exists. Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
    {{- end }}
  */ -}}

  {{- $const := include "base.env" . | fromYaml }}

  {{- /* limits */ -}}
  {{- $limitsVal := include "base.getValue" (list . "limits") }}
  {{- $limits := dict }}
  {{- if regexMatch $const.regexResources $limitsVal }}
    {{- $val := regexSplit $const.regexSplit $limitsVal -1 }}
    {{- $len := len $val }}

    {{- if or (lt $len 1) (eq $len 3) }}
      {{- fail (printf "resources.limits (string) invalid. Values: %s, type: %s (%s) %d" $limitsVal (typeOf $limitsVal) (kindOf $limitsVal)) }}
    {{- end }}

    {{- $cpu := index $val 0 }}
    {{- if $cpu }}
      {{- $_ := set $limits "cpu" $cpu }}
    {{- end }}

    {{- if eq $len 2 }}
      {{- $memory := index $val 1 }}
      {{- if $memory }}
        {{- $_ := set $limits "memory" $memory }}
      {{- end }}
    {{- end }}

    {{- if ge $len 4 }}
      {{- $size := index $val 2 }}
      {{- $max := index $val 3 }}
      {{- $_ := set $limits (printf "hugepages-%s" $size) $max }}
    {{- end }}
  {{- else }}
    {{- $limits = fromYaml $limitsVal }}
  {{- end }}
  {{- if $limits }}
    {{- include "base.field" (list "limits" $limits "base.map") }}
  {{- end }}

  {{- /* requests */ -}}
  {{- $requestsVal := include "base.getValue" (list . "requests") }}
  {{- $requests := dict }}
  {{- if regexMatch $const.regexResources $requestsVal }}
    {{- $val := regexSplit $const.regexSplit $requestsVal -1 }}
    {{- $len := len $val }}

    {{- if or (lt $len 1) (eq $len 3) }}
      {{- fail (printf "resources.limits (string) invalid. Values: %s, type: %s (%s) %d" $limitsVal (typeOf $limitsVal) (kindOf $limitsVal)) }}
    {{- end }}

    {{- $cpu := index $val 0 }}
    {{- if $cpu }}
      {{- $_ := set $limits "cpu" $cpu }}
    {{- end }}

    {{- if eq $len 2 }}
      {{- $memory := index $val 1 }}
      {{- if $memory }}
        {{- $_ := set $limits "memory" $memory }}
      {{- end }}
    {{- end }}

    {{- if ge $len 4 }}
      {{- $size := index $val 2 }}
      {{- $max := index $val 3 }}
      {{- $_ := set $requests (printf "hugepages-%s" $size) $max }}
    {{- end }}
  {{- else }}
    {{- $requests = fromYaml $requestsVal }}
  {{- end }}
  {{- if $requests }}
    {{- include "base.field" (list "requests" $requests "base.map") }}
  {{- end }}
{{- end }}
