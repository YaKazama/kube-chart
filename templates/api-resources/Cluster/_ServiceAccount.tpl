{{- define "cluster.ServiceAccount" -}}
  {{- $_ := set . "_kind" "ServiceAccount" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "ServiceAccount") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* automountServiceAccountToken bool */ -}}
  {{- $automountServiceAccountToken := include "base.getValue" (list . "automountServiceAccountToken") }}
  {{- if $automountServiceAccountToken }}
    {{- include "base.field" (list "automountServiceAccountToken" $automountServiceAccountToken "base.bool") }}
  {{- end }}

  {{- /* imagePullSecrets array */ -}}
  {{- $imagePullSecretsVal := include "base.getValue" (list . "imagePullSecrets") | fromYamlArray }}
  {{- $imagePullSecrets := list }}
  {{- range $imagePullSecretsVal }}
    {{- $val := dict "name" . }}
    {{- $imagePullSecrets = append $imagePullSecrets (include "definitions.LocalObjectReference" $val | fromYaml) }}
  {{- end }}
  {{- $imagePullSecrets = $imagePullSecrets | mustUniq | mustCompact }}
  {{- if $imagePullSecrets }}
    {{- include "base.field" (list "imagePullSecrets" $imagePullSecrets "base.slice") }}
  {{- end }}

  {{- /* secrets array */ -}}
  {{- $secretsVal := include "base.getValue" (list . "secrets") | fromYamlArray }}
  {{- $secrets := list }}
  {{- range $secretsVal }}
    {{- $secrets = append $secrets (include "definitions.ObjectReference" . | fromYaml) }}
  {{- end }}
  {{- $secrets = $secrets | mustUniq | mustCompact }}
  {{- if $secrets }}
    {{- include "base.field" (list "secrets" $secrets "base.slice") }}
  {{- end }}
{{- end }}
