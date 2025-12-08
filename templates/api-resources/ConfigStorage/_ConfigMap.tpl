{{- define "configStorage.ConfigMap" -}}
  {{- $_ := set . "_kind" "ConfigMap" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "ConfigMap") }}

  {{- /* binaryData object/map */ -}}
  {{- $binaryData := include "base.getValue" (list . "binaryData") | fromYaml }}
  {{- if $binaryData }}
    {{- include "base.field" (list "binaryData" $binaryData "base.map.b64enc") }}
  {{- end }}

  {{- /* data object/map */ -}}
  {{- $data := include "base.getValue" (list . "data") | fromYaml }}
  {{- if $data }}
    {{- include "base.field" (list "data" $data "base.map") }}
  {{- end }}

  {{- /* immutable bool */ -}}
  {{- $immutable := include "base.getValue" (list . "immutable") }}
  {{- if $immutable }}
    {{- include "base.field" (list "immutable" $immutable "base.bool") }}
  {{- end }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}
{{- end }}
