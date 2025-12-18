{{- define "definitions.EnvVarSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* configMapKeyRef map */ -}}
  {{- $configMapKeyRefVal := include "base.getValue" (list . "configMapKeyRef") }}
  {{- if regexMatch $const.k8s.container.envVarConfigMap $configMapKeyRefVal }}
    {{- $name := regexReplaceAll $const.k8s.container.envVarConfigMap $configMapKeyRefVal "${1}" | trim }}
    {{- $key := regexReplaceAll $const.k8s.container.envVarConfigMap $configMapKeyRefVal "${2}" | trim }}
    {{- $optional := regexReplaceAll $const.k8s.container.envVarConfigMap $configMapKeyRefVal "${3}" | trim }}
    {{- $val := dict "name" $name "key" $key "optional" $optional }}

    {{- $configMapKeyRef := include "definitions.ConfigMapKeySelector" $val | fromYaml }}
    {{- if $configMapKeyRef }}
      {{- include "base.field" (list "configMapKeyRef" $configMapKeyRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* fieldRef map */ -}}
  {{- $fieldRefVal := include "base.getValue" (list . "configMapKeyRef") }}
  {{- if regexMatch $const.k8s.container.envVarField $fieldRefVal }}
    {{- $fieldPath := regexReplaceAll $const.k8s.container.envVarField $fieldRefVal "${1}" | trim }}
    {{- $apiVersion := regexReplaceAll $const.k8s.container.envVarField $fieldRefVal "${2}" | trim }}
    {{- $val := dict "fieldPath" $fieldPath "apiVersion" $apiVersion }}

    {{- $fieldRef := include "definitions.ObjectFieldSelector" $val | fromYaml }}
    {{- if $fieldRef }}
      {{- include "base.field" (list "fieldRef" $fieldRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* fileKeyRef map */ -}}
  {{- $fileKeyRefVal := include "base.getValue" (list . "fileKeyRef") }}
  {{- if regexMatch $const.k8s.container.envVarFile $fileKeyRefVal }}
    {{- $volumeName := regexReplaceAll $const.k8s.container.envVarFile $fileKeyRefVal "${1}" | trim }}
    {{- $path := regexReplaceAll $const.k8s.container.envVarFile $fileKeyRefVal "${2}" | trim }}
    {{- $key := regexReplaceAll $const.k8s.container.envVarFile $fileKeyRefVal "${3}" | trim }}
    {{- $optional := regexReplaceAll $const.k8s.container.envVarFile $fileKeyRefVal "${4}" | trim }}
    {{- $val := dict "volumeName" $volumeName "path" $path "key" $key "optional" $optional }}

    {{- $fileKeyRef := include "definitions.FileKeySelector" $val | fromYaml }}
    {{- if $fileKeyRef }}
      {{- include "base.field" (list "fileKeyRef" $fileKeyRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* resourceFieldRef map */ -}}
  {{- $resourceFieldRefVal := include "base.getValue" (list . "resourceFieldRef") }}
  {{- if regexMatch $const.k8s.container.envVarResource $resourceFieldRefVal }}
    {{- $resource := regexReplaceAll $const.k8s.container.envVarResource $resourceFieldRefVal "${1}" | trim }}
    {{- $containerName := regexReplaceAll $const.k8s.container.envVarResource $resourceFieldRefVal "${2}" | trim }}
    {{- $divisor := regexReplaceAll $const.k8s.container.envVarResource $resourceFieldRefVal "${3}" | trim }}
    {{- $val := dict "resource" $resource "containerName" $containerName "divisor" $divisor }}

    {{- $resourceFieldRef := include "definitions.ResourceFieldSelector" $val | fromYaml }}
    {{- if $resourceFieldRef }}
      {{- include "base.field" (list "resourceFieldRef" $resourceFieldRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* secretKeyRef map */ -}}
  {{- $secretKeyRefVal := include "base.getValue" (list . "secretKeyRef") }}
  {{- if regexMatch $const.k8s.container.envVarSecret $secretKeyRefVal }}
    {{- $name := regexReplaceAll $const.k8s.container.envVarSecret $secretKeyRefVal "${1}" | trim }}
    {{- $key := regexReplaceAll $const.k8s.container.envVarSecret $secretKeyRefVal "${2}" | trim }}
    {{- $optional := regexReplaceAll $const.k8s.container.envVarSecret $secretKeyRefVal "${3}" | trim }}
    {{- $val := dict "name" $name "key" $key "optional" $optional }}

    {{- $secretKeyRef := include "definitions.SecretKeySelector" $val | fromYaml }}
    {{- if $secretKeyRef }}
      {{- include "base.field" (list "secretKeyRef" $secretKeyRef "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
