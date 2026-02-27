{{- define "service.EndpointSlice" -}}
  {{- $_ := set . "_kind" "EndpointSlice" }}

  {{- include "base.field" (list "apiVersion" "discovery.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "EndpointSlice") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* addressType string */ -}}
  {{- $addressType := include "base.getValue" (list . "addressType") }}
  {{- $addressTypeAllows := list "FQDN" "IPv4" "IPv6" }}
  {{- if $addressType }}
    {{- include "base.field" (list "addressType" $addressType "base.string" $addressTypeAllows) }}
  {{- end }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* ports array */ -}}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $_ports := toString . }}
    {{- $match := regexFindAll $const.k8s.service.endpoint.port $_ports -1 }}
    {{- if not $match }}
      {{- fail (printf "ServiceSpec: ports error. Values: %s, format: 'port[/protocol][@appProtocol][#name]'" $_ports) }}
    {{- end }}

    {{- $port := regexReplaceAll $const.k8s.service.endpoint.port $_ports "${1}" | trim }}
    {{- $protocol := regexReplaceAll $const.k8s.service.endpoint.port $_ports "${2}" | trim }}
    {{- $appProtocol := regexReplaceAll $const.k8s.service.endpoint.port $_ports "${3}" | trim }}
    {{- $name := regexReplaceAll $const.k8s.service.endpoint.port $_ports "${4}" | trim }}
    {{- $val := dict "port" $port "protocol" $protocol "appProtocol" $appProtocol "name" $name }}

    {{- $ports = append $ports (include "old.EndpointPort" $val | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if gt (len $ports) 100 }}
    {{- $ports = slice $ports 0 100 }}
  {{- end }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}

  {{- /* endpoints array */ -}}
  {{- $endpointsVal := include "base.getValue" (list . "endpoints") | fromYamlArray }}
  {{- $endpoints := list }}
  {{- range $endpointsVal }}
    {{- $endpoints = append $endpoints (include "definitions.Endpoint" . | fromYaml) }}
  {{- end }}
  {{- $endpoints = $endpoints | mustUniq | mustCompact }}
  {{- if gt (len $endpoints) 1000 }}
    {{- $endpoints = slice $endpoints 0 1000 }}
  {{- end }}
  {{- if $endpoints }}
    {{- include "base.field" (list "endpoints" $endpoints "base.slice") }}
  {{- end }}
{{- end }}
