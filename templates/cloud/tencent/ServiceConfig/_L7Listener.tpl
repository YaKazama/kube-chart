{{- define "serviceConfig.L7Listener" -}}
  {{- /* protocol string */ -}}
  {{- $protocol := include "base.getValue" (list . "protocol") }}
  {{- $protocolAllows := list "HTTP" "HTTPS" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" ($protocol | upper) "base.string" $protocolAllows) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* snatEnable bool */ -}}
  {{- $snatEnable := include "base.getValue" (list . "snatEnable" "toString") }}
  {{- $_keepaliveEnable := include "base.getValue" (list . "keepaliveEnable") }}
  {{- if and (eq $snatEnable "false") (eq (int $_keepaliveEnable) 1) }}
    {{- fail "serviceConfig.L7Listener: snatEnable cannot set false when keepaliveEnable = 1" }}
  {{- end }}
  {{- if $snatEnable }}
    {{- include "base.field" (list "snatEnable" $snatEnable "base.bool") }}
  {{- end }}

  {{- /* defaultServer string */ -}}
  {{- $defaultServer := include "base.getValue" (list . "defaultServer") }}
  {{- if $defaultServer }}
    {{- include "base.field" (list "defaultServer" $defaultServer "base.domain") }}
  {{- end }}

  {{- /* keepaliveEnable int */ -}}
  {{- $keepaliveEnable := include "base.getValue" (list . "keepaliveEnable" "toString") }}
  {{- if $keepaliveEnable }}
    {{- include "base.field" (list "keepaliveEnable" $keepaliveEnable "base.int") }}
  {{- end }}

  {{- /* domains array */ -}}
  {{- $domainsVal := include "base.getValue" (list . "domains") | fromYamlArray }}
  {{- $domains := list }}
  {{- range $domainsVal }}
    {{- $domains = append $domains (include "serviceConfig.Domain" . | fromYaml) }}
  {{- end }}
  {{- $domains = $domains | mustUniq | mustCompact }}
  {{- if $domains }}
    {{- include "base.field" (list "domains" $domains "base.slice") }}
  {{- end }}
{{- end }}
