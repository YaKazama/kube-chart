{{- define "definitions.EnvFromSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* prefix string */ -}}
  {{- $prefix := include "base.getValue" (list . "prefix") }}
  {{- if $prefix }}
    {{- include "base.field" (list "prefix" $prefix) }}
  {{- end }}

  {{- /* configMapRef map */ -}}
  {{- $configMapRefVal := include "base.getValue" (list . "configMapRef") }}
  {{- if regexMatch $const.k8s.container.envFromConfigMap $configMapRefVal }}
    {{- $name := regexReplaceAll $const.k8s.container.envFromConfigMap $configMapRefVal "${1}" | trim }}
    {{- $optional := regexReplaceAll $const.k8s.container.envFromConfigMap $configMapRefVal "${2}" | trim }}
    {{- $val := dict "name" $name "optional" $optional }}

    {{- $configMapRef := include "definitions.ConfigMapEnvSource" $val | fromYaml }}
    {{- if $configMapRef }}
      {{- include "base.field" (list "configMapRef" $configMapRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* secretRef map */ -}}
  {{- $secretRefVal := include "base.getValue" (list . "secretRef") }}
  {{- if regexMatch $const.k8s.container.envFromSecret $secretRefVal }}
    {{- $name := regexReplaceAll $const.k8s.container.envFromSecret $secretRefVal "${1}" | trim }}
    {{- $optional := regexReplaceAll $const.k8s.container.envFromSecret $secretRefVal "${2}" | trim }}
    {{- $val := dict "name" $name "optional" $optional }}

    {{- $secretRef := include "definitions.SecretEnvSource" $val | fromYaml }}
    {{- if $secretRef }}
      {{- include "base.field" (list "secretRef" $secretRef "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
