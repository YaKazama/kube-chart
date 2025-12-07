{{- define "definitions.IngressRule" -}}
  {{- /* host string */ -}}
  {{- $host := include "base.getValue" (list . "host") }}
  {{- include "base.field" (list "host" $host "quote") }}

  {{- /* http map */ -}}
  {{- /* rules 中没有定义 http , 但抽象成了一个 slice . 直接透传 */ -}}
  {{- $httpVal := include "base.getValue" (list . "http") | fromYamlArray }}
  {{- $val := dict "paths" $httpVal }}
  {{- $http := include "definitions.HTTPIngressRuleValue" $val | fromYaml }}
  {{- if $http }}
    {{- include "base.field" (list "http" $http "base.map") }}
  {{- end }}
{{- end }}
