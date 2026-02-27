{{- define "definitions.Endpoint" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* addresses string array */ -}}
  {{- $addresses := include "base.getValue" (list . "addresses") | fromYamlArray }}
  {{- $addresses = $addresses | mustUniq | mustCompact }}
  {{- if gt (len $addresses) 100 }}
    {{- $addresses = slice $addresses 0 100 }}
  {{- end }}
  {{- if $addresses }}
    {{- include "base.field" (list "addresses" $addresses "base.slice.ips") }}
  {{- end }}

  {{- /* conditions map */ -}}
  {{- $conditionsVal := include "base.getValue" (list . "conditions") | fromYaml }}
  {{- if $conditionsVal }}
    {{- $conditions := include "definitions.EndpointConditions" $conditionsVal | fromYaml }}
    {{- include "base.field" (list "conditions" $conditions "base.map") }}
  {{- end }}

  {{- /* deprecatedTopology object/map */ -}}
  {{- $deprecatedTopology := include "base.getValue" (list . "deprecatedTopology") | fromYaml }}
  {{- if $deprecatedTopology }}
    {{- include "base.field" (list "deprecatedTopology" $deprecatedTopology "base.map") }}
  {{- end }}

  {{- /* hints map */ -}}
  {{- /* 抽象为 []string 格式: node(s)|zone(s) name */ -}}
  {{- $hintsVal := include "base.getValue" (list . "hints") | fromYamlArray }}
  {{- $_nodes := list }}
  {{- $_zones := list }}
  {{- range $hintsVal }}
    {{- $match := regexFindAll $const.k8s.service.endpoint.hints . -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.Endpoint: hints invalid. Values: %s, format: 'node|zone name{1,8}'" .) }}
    {{- end }}

    {{- $key := regexReplaceAll $const.k8s.service.endpoint.hints . "${1}" | trim }}
    {{- $names := regexReplaceAll $const.k8s.service.endpoint.hints . "${2}" | trim }}

    {{- /* 比较简单，故取处先预处理 names */ -}}
    {{- $_names := regexSplit " " ($names | trim) -1 }}
    {{- range $_names }}
      {{- if eq $key "node" }}
        {{- $_nodes = append $_nodes (dict "name" .) }}
      {{- else if eq $key "zone" }}
        {{- $_zones = append $_zones (dict "name" .) }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $_val := dict "forNodes" $_nodes "forZones" $_zones }}
  {{- $hints := include "definitions.EndpointHints" $_val | fromYaml }}
  {{- if $hints }}
    {{- include "base.field" (list "hints" $hints "base.map") }}
  {{- end }}

  {{- /* hostname string */ -}}
  {{- $hostname := include "base.getValue" (list . "hostname") }}
  {{- if $hostname }}
    {{- include "base.field" (list "hostname" $hostname) }}
  {{- end }}

  {{- /* nodeName string */ -}}
  {{- $nodeName := include "base.getValue" (list . "nodeName") }}
  {{- if $nodeName }}
    {{- include "base.field" (list "nodeName" $nodeName) }}
  {{- end }}

  {{- /* targetRef map */ -}}
  {{- $targetRefVal := include "base.getValue" (list . "targetRef") | fromYaml }}
  {{- if $targetRefVal }}
    {{- $targetRef := include "definitions.ObjectReference" $targetRefVal | fromYaml }}
    {{- if $targetRef }}
      {{- include "base.field" (list "targetRef" $targetRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* zone string */ -}}
  {{- $zone := include "base.getValue" (list . "zone") }}
  {{- if $zone }}
    {{- include "base.field" (list "zone" $zone) }}
  {{- end }}
{{- end }}
