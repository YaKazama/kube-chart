{{- /*
  数据格式：
    - cpu memory hugepages-size hugepages-max
    - map[map[limits: map[cpu: 1 memory: 1Gi hugepages]] map[requests: map[cpu: 1 memory: 1Gi hugepages-2Mi: 10Mi]]]

  支持四段式 (cpu memory hugepages-size hugepages-max) 字符串，也可以使用 map
*/ -}}
{{- define "definitions.ResourceRequirements" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* limits */ -}}
  {{- $limitsVal := include "base.getValue" (list . "limits") }}
  {{- $limits := dict }}
  {{- if regexMatch $const.k8s.resources $limitsVal }}
    {{- $val := regexSplit $const.split.space $limitsVal -1 }}
    {{- $len := len $val }}

    {{- if or (lt $len 1) (eq $len 3) }}
      {{- fail (printf "ResourceRequirements: limits, v: %s, t: %s (%s), f: 'cpu [memory] [hugepages-size hugepages-max]'" $limitsVal (kindOf $limitsVal) (typeOf $limitsVal)) }}
    {{- end }}

    {{- $cpu := index $val 0 | trim }}
    {{- if and $cpu (ne $cpu "0") }}
      {{- $_ := set $limits "cpu" $cpu }}
      {{- if regexMatch "^\\d+$" $cpu }}
        {{- $_ := set $limits "cpu" ($cpu | int) }}
      {{- else if regexMatch "^(?:\\d+)?\\.\\d+$" $cpu }}
        {{- $_ := set $limits "cpu" ($cpu | float64) }}
      {{- end }}
    {{- end }}

    {{- if or (eq $len 2) (ge $len 4) }}
      {{- $memory := index $val 1 | trim }}
      {{- if $memory }}
        {{- $_ := set $limits "memory" $memory }}
      {{- end }}
    {{- end }}

    {{- if ge $len 4 }}
      {{- $size := index $val 2 | trim }}
      {{- $max := index $val 3 | trim }}
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
  {{- if regexMatch $const.k8s.resources $requestsVal }}
    {{- $val := regexSplit $const.split.space $requestsVal -1 }}
    {{- $len := len $val }}

    {{- if or (lt $len 1) (eq $len 3) }}
      {{- fail (printf "ResourceRequirements: requests, v: %s, t: %s (%s), f: 'cpu [memory] [hugepages-size hugepages-max]'" $requestsVal (kindOf $requestsVal) (typeOf $requestsVal)) }}
    {{- end }}

    {{- $cpu := index $val 0 | trim }}
    {{- if $cpu }}
      {{- $_ := set $requests "cpu" $cpu }}
      {{- if regexMatch "^\\d+$" $cpu }}
        {{- $_ := set $requests "cpu" ($cpu | int) }}
      {{- else if regexMatch "^(?:0)?\\.\\d+$" $cpu }}
        {{- $_ := set $requests "cpu" ($cpu | float64) }}
      {{- end }}
    {{- end }}

    {{- if or (eq $len 2) (ge $len 4) }}
      {{- $memory := index $val 1 | trim }}
      {{- if $memory }}
        {{- $_ := set $requests "memory" $memory }}
      {{- end }}
    {{- end }}

    {{- if ge $len 4 }}
      {{- $size := index $val 2 | trim }}
      {{- $max := index $val 3 | trim }}
      {{- $_ := set $requests (printf "hugepages-%s" $size) $max }}
    {{- end }}
  {{- else }}
    {{- $requests = fromYaml $requestsVal }}
  {{- end }}
  {{- if $requests }}
    {{- include "base.field" (list "requests" $requests "base.map") }}
  {{- end }}
{{- end }}
