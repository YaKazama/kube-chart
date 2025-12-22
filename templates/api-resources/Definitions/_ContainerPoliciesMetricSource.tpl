{{- /* vpa v1 */ -}}
{{- define "definitions.ContainerPoliciesMetricSource" -}}
  {{- /* containerName string */ -}}
  {{- $containerName := include "base.getValue" (list . "containerName") }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName) }}
  {{- end }}

  {{- /* controlledResources array */ -}}
  {{- $controlledResourcesVal := include "base.getValue" (list . "controlledResources") | fromYamlArray }}
  {{- $controlledResources := list }}
  {{- range $controlledResourcesVal }}
    {{- $val := dict "item" . }}
    {{- $controlledResources = append $controlledResources (include "definitions.ControlledResourcesReference" $val | fromYaml) }}
  {{- end }}
  {{- $controlledResources = $controlledResources | mustUniq | mustCompact }}
  {{- if $controlledResources }}
    {{- include "base.field" (list "controlledResources" $controlledResources "base.slice") }}
  {{- end }}

  {{- /* controlledValues string */ -}}
  {{- $controlledValues := include "base.getValue" (list . "controlledValues") }}
  {{- $controlledValuesAllows := list "RequestsAndLimits" "RequestsOnly" }}
  {{- if $controlledValues }}
    {{- include "base.field" (list "controlledValues" $controlledValues "base.string" $controlledValuesAllows) }}
  {{- end }}

  {{- /* maxAllowed object/map */ -}}
  {{- $maxAllowed := include "base.getValue" (list . "maxAllowed") | fromYaml }}
  {{- if $maxAllowed }}
    {{- include "base.field" (list "maxAllowed" $maxAllowed "base.map") }}
  {{- end }}

  {{- /* minAllowed object/map */ -}}
  {{- $minAllowed := include "base.getValue" (list . "minAllowed") | fromYaml }}
  {{- if $minAllowed }}
    {{- include "base.field" (list "minAllowed" $minAllowed "base.map") }}
  {{- end }}

  {{- /* mode string */ -}}
  {{- $mode := include "base.getValue" (list . "mode") }}
  {{- $modeAllows := list "Auto" "Off" }}
  {{- if $mode }}
    {{- include "base.field" (list "mode" $mode "base.string" $modeAllows) }}
  {{- end }}

  {{- /* oomBumpUpRatio Quantity */ -}}
  {{- $oomBumpUpRatio := include "base.getValue" (list . "oomBumpUpRatio") }}
  {{- if $oomBumpUpRatio }}
    {{- include "base.field" (list "oomBumpUpRatio" $oomBumpUpRatio "base.Quantity") }}
  {{- end }}

  {{- /* oomMinBumpUp Quantity */ -}}
  {{- $oomMinBumpUp := include "base.getValue" (list . "oomMinBumpUp") }}
  {{- if $oomMinBumpUp }}
    {{- include "base.field" (list "oomMinBumpUp" $oomMinBumpUp "base.Quantity") }}
  {{- end }}
{{- end }}
