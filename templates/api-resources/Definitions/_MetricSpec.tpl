{{- define "definitions.MetricSpec" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "ContainerResource" "External" "Object" "Pods" "Resource" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* containerResource map */ -}}
  {{- if eq $type "ContainerResource" }}
    {{- $containerResourceVal := include "base.getValue" (list . "containerResource") | fromYaml }}
    {{- if $containerResourceVal }}
      {{- $containerResource := include "definitions.ContainerResourceMetricSource" $containerResourceVal | fromYaml }}
      {{- if $containerResource }}
        {{- include "base.field" (list "containerResource" $containerResource "base.map") }}
      {{- end }}
    {{- end }}

  {{- /* external map */ -}}
  {{- else if eq $type "External" }}
    {{- $externalVal := include "base.getValue" (list . "external") | fromYaml }}
    {{- if $externalVal }}
      {{- $external := include "definitions.ExternalMetricSource" $externalVal | fromYaml }}
      {{- if $external }}
        {{- include "base.field" (list "external" $external "base.map") }}
      {{- end }}
    {{- end }}

  {{- /* object map */ -}}
  {{- else if eq $type "Object" }}
    {{- $objectVal := include "base.getValue" (list . "object") | fromYaml }}
    {{- if $objectVal }}
      {{- $object := include "definitions.ObjectMetricSource" $objectVal | fromYaml }}
      {{- if $object }}
        {{- include "base.field" (list "object" $object "base.map") }}
      {{- end }}
    {{- end }}

  {{- /* pods map */ -}}
  {{- else if eq $type "Pods" }}
    {{- $podsVal := include "base.getValue" (list . "pods") | fromYaml }}
    {{- if $podsVal }}
      {{- $pods := include "definitions.PodsMetricSource" $podsVal | fromYaml }}
      {{- if $pods }}
        {{- include "base.field" (list "pods" $pods "base.map") }}
      {{- end }}
    {{- end }}

  {{- /* resource map */ -}}
  {{- else if eq $type "Resource" }}
    {{- $resourceVal := include "base.getValue" (list . "resource") | fromYaml }}
    {{- if $resourceVal }}
      {{- $resource := include "definitions.ResourceMetricSource" $resourceVal | fromYaml }}
      {{- if $resource }}
        {{- include "base.field" (list "resource" $resource "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
