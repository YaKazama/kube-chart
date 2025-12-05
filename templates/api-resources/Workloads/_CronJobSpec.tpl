{{- define "workloads.CronJobSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "StatefulSetSpec" }}
  {{- $__kind := get . "_kind" }}

  {{- /* concurrencyPolicy string */ -}}
  {{- $concurrencyPolicy := include "base.getValue" (list . "concurrencyPolicy") }}
  {{- $concurrencyPolicyAllows := list "Allow" "Forbid" "Replace" }}
  {{- if $concurrencyPolicy }}
    {{- include "base.field" (list "concurrencyPolicy" $concurrencyPolicy "base.string" $concurrencyPolicyAllows) }}
  {{- end }}

  {{- /* failedJobsHistoryLimit int */ -}}
  {{- $failedJobsHistoryLimit := include "base.getValue" (list . "failedJobsHistoryLimit" "int") }}
  {{- if $failedJobsHistoryLimit }}
    {{- include "base.field" (list "failedJobsHistoryLimit" $failedJobsHistoryLimit "base.int") }}
  {{- end }}

  {{- /* jobTemplate map */ -}}
  {{- $jobTemplateVal := include "base.getValue" (list . "jobTemplate") | fromYaml }}
  {{- if $jobTemplateVal }}   {{- /* 透传 Context Values */ -}}
    {{- $_ := set $jobTemplateVal "Values" .Values }}
    {{- if .Context }}
      {{- $_ := set $jobTemplateVal "Context" .Context }}
    {{- end }}
    {{- $jobTemplate := include "definitions.JobTemplateSpec" $jobTemplateVal | fromYaml }}
    {{- if $jobTemplate }}
      {{- include "base.field" (list "jobTemplate" $jobTemplate "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* schedule string */ -}}
  {{- $schedule := include "base.getValue" (list . "schedule") }}
  {{- $const := include "base.env" $schedule | fromYaml }}
  {{- if regexMatch $const.regexCron $schedule }}
    {{- include "base.field" (list "schedule" $schedule "quote") }}
  {{- end }}

  {{- /* startingDeadlineSeconds int */ -}}
  {{- $startingDeadlineSeconds := include "base.getValue" (list . "startingDeadlineSeconds" "int") }}
  {{- if $startingDeadlineSeconds }}
    {{- include "base.field" (list "startingDeadlineSeconds" $startingDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* successfulJobsHistoryLimit int */ -}}
  {{- $successfulJobsHistoryLimit := include "base.getValue" (list . "successfulJobsHistoryLimit" "int") }}
  {{- if $successfulJobsHistoryLimit }}
    {{- include "base.field" (list "successfulJobsHistoryLimit" $successfulJobsHistoryLimit "base.int") }}
  {{- end }}

  {{- /* suspend bool */ -}}
  {{- $suspend := include "base.getValue" (list . "suspend") }}
  {{- if $suspend }}
    {{- include "base.field" (list "suspend" $suspend "base.bool") }}
  {{- end }}

  {{- /* timeZone timeZone */ -}}
  {{- $timeZone := include "base.getValue" (list . "timeZone") }}
  {{- if $timeZone }}
    {{- include "base.field" (list "timeZone" $timeZone) }}
  {{- end }}
{{- end }}
