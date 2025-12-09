{{- define "cluster.ClusterRole" -}}
  {{- $_ := set . "_kind" "ClusterRole" }}

  {{- include "base.field" (list "apiVersion" "rbac.authorization.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "ClusterRole") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* aggregationRule map */ -}}
  {{- /* 虽然可以抽象一波，但用到的地方好像实在太少，所以就不处理，直接原生传递 */ -}}
  {{- $aggregationRuleVal := include "base.getValue" (list . "aggregationRule") | fromYaml }}
  {{- if $aggregationRuleVal }}
    {{- $aggregationRule := include "definitions.AggregationRule" $aggregationRuleVal | fromYaml }}
    {{- if $aggregationRule }}
      {{- include "base.field" (list "aggregationRule" $aggregationRule "base.map") }}
    {{- end }}

  {{- end }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- $rules := list }}
  {{- range $rulesVal }}
    {{- $rules = append $rules (include "definitions.PolicyRule" . | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice.quote") }}
  {{- end }}
{{- end }}
