{{- define "configStorage.ConfigMap" -}}
  {{- $_ := set . "_kind" "ConfigMap" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "ConfigMap") }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* binaryData object/map */ -}}
  {{- $binaryData := include "base.getValue" (list . "binaryData") | fromYaml }}
  {{- /*
    # 读取内容后与 binaryData 合并
    # 优先级 binaryData < binaryDataFileRefs 且 binaryDataFileRefs 列表顺序覆盖
  */ -}}
  {{- $binaryData := include "base.getValue" (list . "binaryData") | fromYaml }}
  {{- $binaryDataFileRefs := include "base.getValue" (list . "binaryDataFileRefs") | fromYamlArray }}
  {{- range $binaryDataFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "configStorage.ConfigMap: binaryDataFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $key := include "base.getValue" (list . "key") }}
    {{- if empty $key }}
      {{- $key = base $filePath }}
    {{- end }}

    {{- $val := dict $key $content }}
    {{- $binaryData = mergeOverwrite $binaryData $val }}
  {{- end }}
  {{- if $binaryData }}
    {{- include "base.field" (list "binaryData" $binaryData "base.map.b64enc") }}
  {{- end }}

  {{- /* data object/map */ -}}
  {{- $data := include "base.getValue" (list . "data") | fromYaml }}
  {{- /*
    # 读取内容后与 data 合并
    # 优先级 data < dataFileRefs 且 dataFileRefs 列表顺序覆盖
  */ -}}
  {{- $dataFileRefs := include "base.getValue" (list . "dataFileRefs") | fromYamlArray }}
  {{- range $dataFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "configStorage.ConfigMap: dataFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $key := include "base.getValue" (list . "key") }}
    {{- if empty $key }}
      {{- $key = base $filePath }}
    {{- end }}

    {{- $val := dict $key $content }}
    {{- $data = mergeOverwrite $data $val }}
  {{- end }}
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
