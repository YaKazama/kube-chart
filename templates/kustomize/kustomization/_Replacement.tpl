{{- define "kustomization.Replacement" -}}
  {{- /* source map */ -}}
  {{- $sourceVal := include "base.getValue" (list . "source") | fromYaml }}
  {{- if $sourceVal }}
    {{- $source := include "kustomization.ReplacementSource" $sourceVal | fromYaml }}
    {{- if $source }}
      {{- include "base.field" (list "source" $source "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* sourceValue string */ -}}
  {{- $sourceValue := include "base.getValue" (list . "sourceValue") }}
  {{- if $sourceValue }}
    {{- include "base.field" (list "sourceValue" $sourceValue) }}
  {{- end }}

  {{- /* targets array */ -}}
  {{- $targetsVal := include "base.getValue" (list . "targets") | fromYamlArray }}
  {{- $targets := list }}
  {{- range $targetsVal }}
    {{- $targets = append $targets (include "kustomization.ReplacementTarget" . | fromYaml) }}
  {{- end }}
  {{- $targets = $targets | mustUniq | mustCompact }}
  {{- if $targets }}
    {{- include "base.field" (list "targets" $targets "base.slice") }}
  {{- end }}
{{- end }}
