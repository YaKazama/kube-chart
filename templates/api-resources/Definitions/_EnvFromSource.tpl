{{- define "definitions.EnvFromSource" -}}
  {{- /*
    正则:
      configMap sourceName prefix true
      secret sourceName prefix true
  */ -}}
  {{- $regex := "^(configMap|secret)\\s+(\\S+)(?:\\s+(\\S+))?(?:\\s+(true|false))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "envFrom: error, must start with 'configMap|secret'. Values: %s, format: '<configMap|secret> sourceName [prefix] [optional]'" .) }}
  {{- end }}

  {{- /* prefix string */ -}}
  {{- $prefix := regexReplaceAll $regex . "${3}" }}
  {{- if $prefix }}
    {{- include "base.field" (list "prefix" $prefix) }}
  {{- end }}

  {{- /* configMapRef map */ -}}
  {{- if hasPrefix "configMap" . }}
    {{- $configMapRef := include "definitions.ConfigMapEnvSource" . | fromYaml }}
    {{- if $configMapRef }}
      {{- include "base.field" (list "configMapRef" $configMapRef "base.map") }}
    {{- end }}

  {{- /* secretRef map */ -}}
  {{- else if hasPrefix "secret" . }}
    {{- $secretRef := include "definitions.SecretEnvSource" . | fromYaml }}
    {{- if $secretRef }}
      {{- include "base.field" (list "secretRef" $secretRef "base.map") }}
    {{- end }}
  {{- end }}

{{- end }}
