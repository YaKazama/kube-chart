{{- define "definitions.EnvVarSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexEnvVarSource . -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.EnvVarSource: env.valueFrom: error, must start with 'configMap|field|file|resource|secret'. Values: %s" .) }}
  {{- end }}

  {{- /* configMapKeyRef map */ -}}
  {{- if hasPrefix "configMap" . }}
    {{- $configMapKeyRef := include "definitions.ConfigMapKeySelector" . | fromYaml }}
    {{- if $configMapKeyRef }}
      {{- include "base.field" (list "configMapKeyRef" $configMapKeyRef "base.map") }}
    {{- end }}

  {{- /* fieldRef map */ -}}
  {{- else if hasPrefix "field" . }}
    {{- $fieldRef := include "definitions.ObjectFieldSelector" . | fromYaml }}
    {{- if $fieldRef }}
      {{- include "base.field" (list "fieldRef" $fieldRef "base.map") }}
    {{- end }}

  {{- /* fileKeyRef map */ -}}
  {{- else if hasPrefix "file" . }}
    {{- $fileKeyRef := include "definitions.FileKeySelector" . | fromYaml }}
    {{- if $fileKeyRef }}
      {{- include "base.field" (list "fileKeyRef" $fileKeyRef "base.map") }}
    {{- end }}

  {{- /* resourceFieldRef map */ -}}
  {{- else if hasPrefix "resource" . }}
    {{- $resourceFieldRef := include "definitions.ResourceFieldSelector" . | fromYaml }}
    {{- if $resourceFieldRef }}
      {{- include "base.field" (list "resourceFieldRef" $resourceFieldRef "base.map") }}
    {{- end }}

  {{- /* secretKeyRef map */ -}}
  {{- else if hasPrefix "secret" . }}
    {{- $secretKeyRef := include "definitions.SecretKeySelector" . | fromYaml }}
    {{- if $secretKeyRef }}
      {{- include "base.field" (list "secretKeyRef" $secretKeyRef "base.map") }}
    {{- end }}
  {{- end }}

{{- end }}
