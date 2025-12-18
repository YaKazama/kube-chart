{{- define "serviceConfig.HealthCheck" -}}
  {{- /* enable bool */ -}}
  {{- $enable := include "base.getValue" (list . "enable" "toString") }}
  {{- if $enable }}
    {{- include "base.field" (list "enable" $enable "base.bool") }}
  {{- end }}

  {{- /* checkType string */ -}}
  {{- $checkType := include "base.getValue" (list . "checkType") }}
  {{- $checkTypeAllows := list "TCP" "HTTP" "CUSTOM" }}
  {{- if $checkType }}
    {{- include "base.field" (list "checkType" ($checkType | upper) "base.string" $checkTypeAllows) }}
  {{- end }}

  {{- /* checkPort int */ -}}
  {{- $checkPort := include "base.getValue" (list . "checkPort") }}
  {{- if $checkPort }}
    {{- include "base.field" (list "checkPort" $checkPort "base.port") }}
  {{- end }}

  {{- /* intervalTime int */ -}}
  {{- $intervalTime := include "base.getValue" (list . "intervalTime") }}
  {{- $_timeout := include "base.getValue" (list . "timeout") }}
  {{- if and $intervalTime $_timeout (le (int $intervalTime) (int $_timeout)) }}
    {{- fail "serviceConfig.HealthCheck: intervalTime must greater than timeout" }}
  {{- end }}
  {{- if $intervalTime }}
    {{- include "base.field" (list "intervalTime" (list (int $intervalTime) 5 300) "base.int.range") }}
  {{- end }}

  {{- /* timeout int */ -}}
  {{- $timeout := include "base.getValue" (list . "timeout") }}
  {{- $_intervalTime := include "base.getValue" (list . "intervalTime") }}
  {{- if and $timeout $_intervalTime (ge (int $timeout) (int $_intervalTime)) }}
    {{- fail "serviceConfig.HealthCheck: timeout must less than intervalTime" }}
  {{- end }}
  {{- if $timeout }}
    {{- include "base.field" (list "timeout" (list (int $timeout) 2 60) "base.int.range") }}
  {{- end }}

  {{- /* healthNum int */ -}}
  {{- $healthNum := include "base.getValue" (list . "healthNum") }}
  {{- if $healthNum }}
    {{- include "base.field" (list "healthNum" (list (int $healthNum) 2 10) "base.int.range") }}
  {{- end }}

  {{- /* unHealthNum int */ -}}
  {{- $unHealthNum := include "base.getValue" (list . "unHealthNum") }}
  {{- if $unHealthNum }}
    {{- include "base.field" (list "unHealthNum" (list (int $unHealthNum) 2 10) "base.int.range") }}
  {{- end }}

  {{- /* httpCode int */ -}}
  {{- /* 多个值相加 */ -}}
  {{- /* 1 => 1xx 2 => 2xx 4 => 3xx 8 => 4xx 16 => 5xx */ -}}
  {{- $httpCode := include "base.getValue" (list . "httpCode") }}
  {{- if $httpCode }}
    {{- include "base.field" (list "httpCode" (list (int $httpCode) 1 31) "base.int.range") }}
  {{- end }}

  {{- /* httpCheckPath string */ -}}
  {{- $httpCheckPath := include "base.getValue" (list . "httpCheckPath") }}
  {{- if $httpCheckPath }}
    {{- include "base.field" (list "httpCheckPath" $httpCheckPath "base.absPath") }}
  {{- end }}

  {{- /* httpCheckDomain string */ -}}
  {{- $httpCheckDomain := include "base.getValue" (list . "httpCheckDomain") }}
  {{- if $httpCheckDomain }}
    {{- include "base.field" (list "httpCheckDomain" $httpCheckDomain "base.domain") }}
  {{- end }}

  {{- /* httpCheckMethod string */ -}}
  {{- $httpCheckMethod := include "base.getValue" (list . "httpCheckMethod") }}
  {{- $httpCheckMethodAllows := list "HEAD" "GET" }}
  {{- if $httpCheckMethod }}
    {{- include "base.field" (list "httpCheckMethod" ($httpCheckMethod | upper) "base.string" $httpCheckMethodAllows) }}
  {{- end }}

  {{- /* httpVersion string */ -}}
  {{- $httpVersion := include "base.getValue" (list . "httpVersion") }}
  {{- $httpVersionAllows := list "HTTP/1.0" "HTTP/1.1" }}
  {{- if $httpVersion }}
    {{- include "base.field" (list "httpVersion" ($httpVersion | upper) "base.string" $httpVersionAllows) }}
  {{- end }}

  {{- /* sourceIpType int */ -}}
  {{- $sourceIpType := include "base.getValue" (list . "sourceIpType" "toString") }}
  {{- if $sourceIpType }}
    {{- include "base.field" (list "sourceIpType" $sourceIpType "base.int") }}
  {{- end }}

  {{- /* checkType string */ -}}
  {{- $checkType := include "base.getValue" (list . "checkType") }}
  {{- $checkTypeAllows := list "HTTP" "HTTPS" "TCP" "GRPC" }}
  {{- if $checkType }}
    {{- include "base.field" (list "checkType" ($checkType | upper) "base.string" $checkTypeAllows) }}
  {{- end }}
{{- end }}
