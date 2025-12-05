{{- define "workloads.JobSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "PodSpec" }}

  {{- /* activeDeadlineSeconds int */ -}}
  {{- $activeDeadlineSeconds := include "base.getValue" (list . "activeDeadlineSeconds" "int") }}
  {{- if $activeDeadlineSeconds }}
    {{- include "base.field" (list "activeDeadlineSeconds" $activeDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* backoffLimit int */ -}}
  {{- $backoffLimit := include "base.getValue" (list . "backoffLimit" "int") }}
  {{- if $backoffLimit }}
    {{- include "base.field" (list "backoffLimit" $backoffLimit "base.int") }}
  {{- end }}

  {{- /* backoffLimitPerIndex int */ -}}
  {{- $backoffLimitPerIndex := include "base.getValue" (list . "backoffLimitPerIndex" "int") }}
  {{- if $backoffLimitPerIndex }}
    {{- include "base.field" (list "backoffLimitPerIndex" $backoffLimitPerIndex "base.int") }}
  {{- end }}

  {{- /* completionMode string */ -}}
  {{- $completionMode := include "base.getValue" (list . "completionMode") }}
  {{- $completionModeAllows := list "NonIndexed" "Indexed" }}
  {{- if $completionMode }}
    {{- include "base.field" (list "completionMode" $completionMode "base.string" $completionModeAllows) }}
  {{- end }}

  {{- /* completions int */ -}}
  {{- $completions := include "base.getValue" (list . "completions" "int") }}
  {{- if $completions }}
    {{- include "base.field" (list "completions" $completions "base.int") }}
  {{- end }}

  {{- /* managedBy string */ -}}
  {{- $managedBy := include "base.getValue" (list . "managedBy") }}
  {{- if $managedBy }}
    {{- include "base.field" (list "managedBy" $managedBy) }}
  {{- end }}

  {{- /* manualSelector bool */ -}}
  {{- $manualSelector := include "base.getValue" (list . "manualSelector") }}
  {{- if $manualSelector }}
    {{- include "base.field" (list "manualSelector" $manualSelector "base.bool") }}
  {{- end }}

  {{- /* maxFailedIndexes int */ -}}
  {{- $maxFailedIndexes := include "base.getValue" (list . "maxFailedIndexes" "int") }}
  {{- if $maxFailedIndexes }}
    {{- include "base.field" (list "maxFailedIndexes" $maxFailedIndexes "base.int") }}
  {{- end }}

  {{- /* parallelism int */ -}}
  {{- $parallelism := include "base.getValue" (list . "parallelism" "int") }}
  {{- if $parallelism }}
    {{- include "base.field" (list "parallelism" $parallelism "base.int") }}
  {{- end }}

  {{- /* podFailurePolicy map */ -}}
  {{- $podFailurePolicyVal := include "base.getValue" (list . "podFailurePolicy") | fromYamlArray }}
  {{- if $podFailurePolicyVal }}
    {{- $podFailurePolicy := include "definitions.PodFailurePolicy" $podFailurePolicyVal | fromYaml }}
    {{- if $podFailurePolicy }}
      {{- include "base.field" (list "podFailurePolicy" $podFailurePolicy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* podReplacementPolicy string */ -}}
  {{- $podReplacementPolicy := include "base.getValue" (list . "podReplacementPolicy") }}
  {{- $podReplacementPolicyAllows := list "Failed" "TerminatingOrFailed" }}
  {{- if $podReplacementPolicy }}
    {{- include "base.field" (list "podReplacementPolicy" $podReplacementPolicy "base.string" $podReplacementPolicyAllows) }}
  {{- end }}

  {{- /* selector map */ -}}
  {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
  {{- /* 将 labels helmLabels name 追加到 selector 中一并传入 参考 definitions.ObjectMeta 中的 labels */ -}}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
  {{- if $isHelmLabels }}
    {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
  {{- end }}
  {{- if $labels }}
    {{- $_ := set $selectorVal "labels" $labels }}
  {{- end }}
  {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /* successPolicy map */ -}}
  {{- $successPolicyVal := include "base.getValue" (list . "successPolicy") | fromYamlArray }}
  {{- if $successPolicyVal }}
    {{- $successPolicy := include "definitions.SuccessPolicy" $successPolicyVal | fromYaml }}
    {{- if $successPolicy }}
      {{- include "base.field" (list "successPolicy" $successPolicy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* suspend bool */ -}}
  {{- $suspend := include "base.getValue" (list . "suspend") }}
  {{- if $suspend }}
    {{- include "base.field" (list "suspend" $suspend "base.bool") }}
  {{- end }}

  {{- /* template map */ -}}
  {{- $templateVal := include "base.getValue" (list . "template") | fromYaml }}
  {{- if $templateVal }}
    {{- $_ := set $templateVal "Values" .Values }}
    {{- if .Context }}
      {{- $_ := set $templateVal "Context" .Context }}
    {{- end }}
    {{- $template := include "metadata.PodTemplateSpec" $templateVal | fromYaml }}
    {{- if $template }}
      {{- include "base.field" (list "template" $template "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* ttlSecondsAfterFinished int */ -}}
  {{- $ttlSecondsAfterFinished := include "base.getValue" (list . "ttlSecondsAfterFinished") }}
  {{- if $ttlSecondsAfterFinished }}
    {{- include "base.field" (list "ttlSecondsAfterFinished" $ttlSecondsAfterFinished "base.int") }}
  {{- end }}
{{- end }}
