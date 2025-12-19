{{- define "configStorage.Secret" -}}
  {{- $_ := set . "_kind" "Secret" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "Secret") }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Opaque" "kubernetes.io/service-account-token" "kubernetes.io/dockercfg" "kubernetes.io/dockerconfigjson" "kubernetes.io/basic-auth" "kubernetes.io/ssh-auth" "kubernetes.io/tls" "bootstrap.kubernetes.io/token" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* immutable bool */ -}}
  {{- $immutable := include "base.getValue" (list . "immutable") }}
  {{- if $immutable }}
    {{- include "base.field" (list "immutable" $immutable "base.bool") }}
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
      {{- fail "configStorage.Secret: dataFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $key := include "base.getValue" (list . "key") }}
    {{- if empty $key }}
      {{- $key = base $filePath }}
    {{- end }}

    {{- $val := dict $key $content }}
    {{- $data = mergeOverwrite $data $val }}
  {{- end }}
  {{- $_type := include "base.getValue" (list . "type") }}
  {{- if eq $_type "kubernetes.io/service-account-token" }}
    {{- /* 这里设置 annotations 的方式看着有点奇怪，但它确实能正常使用且不影响其他位置的定义 */ -}}
    {{- /* 此处定义的 kubernetes.io/service-account-name 优先级最高 */ -}}
    {{- $_ := set . "annotations" dict }}
    {{- $_ := set .annotations "kubernetes.io/service-account-name" (get $data "serviceAccount") }}
    {{- $data = omit $data "serviceAccount" }}

  {{- else if eq $_type "kubernetes.io/dockercfg" }}
    {{- $server := get $data "server" }}
    {{- $email := get $data "email" }}
    {{- $username := get $data "username" }}
    {{- $password := get $data "password" }}

    {{- if or (empty $server) (empty $username) (empty $password) }}
      {{- fail (printf "Secret: dockercfg error. server, username, password cannot be empty.") }}
    {{- end }}

    {{- $auth := printf "%v:%v" $username $password | b64enc }}
    {{- $data = dict ".dockercfg" (dict "auths" (dict $server (dict "username" $username "password" $password "email" $email "auth" $auth)) | toJson) }}

  {{- else if eq $_type "kubernetes.io/dockerconfigjson" }}
    {{- $server := get $data "server" }}
    {{- $email := get $data "email" }}
    {{- $username := get $data "username" }}
    {{- $password := get $data "password" }}

    {{- if or (empty $server) (empty $username) (empty $password) }}
      {{- fail (printf "Secret: dockerconfigjson error. server, username, password cannot be empty.") }}
    {{- end }}

    {{- $auth := printf "%v:%v" $username $password | b64enc }}
    {{- $data = dict ".dockerconfigjson" (dict "auths" (dict $server (dict "username" $username "password" $password "email" $email "auth" $auth)) | toJson) }}

  {{- else if eq $_type "kubernetes.io/basic-auth" }}
    {{- $username := get $data "username" }}
    {{- $password := get $data "password" }}
    {{- if or (empty $username) (empty $password) }}
      {{- fail (printf "Secret: basic-auth error. username, password cannot be empty.") }}
    {{- end }}

    {{- $data = pick $data "username" "password" }}

  {{- else if eq $_type "kubernetes.io/ssh-auth" }}
    {{- $sshPrivatekey := get $data "ssh-privatekey" }}
    {{- if empty $sshPrivatekey }}
      {{- fail (printf "Secret: ssh-auth error. ssh-privatekey cannot be empty.") }}
    {{- end }}

    {{- $data = pick $data "ssh-privatekey" }}

  {{- else if eq $_type "kubernetes.io/tls" }}
    {{- $crt := get $data "tls.crt" }}
    {{- $key := get $data "tls.key" }}
    {{- if or (empty $crt) (empty $key) }}
      {{- fail (printf "Secret: tls error. tls.crt, tls.key cannot be empty.") }}
    {{- end }}

    {{- $data = pick $data "tls.crt" "tls.key" }}

  {{- else if eq $_type "bootstrap.kubernetes.io/token" }}
    {{- $dataKeys := keys $data }}
    {{- $_usageBootstrapes := dict }}
    {{- range $dataKeys }}
      {{- if hasPrefix "usage-bootstrap-" . }}
        {{- $_usageBootstrapes = merge $_usageBootstrapes (pick $data .) }}
      {{- end }}
    {{- end }}

    {{- $data = pick $data "token-id" "token-secret" "description" "expiration" "auth-extra-groups" }}
    {{- $data = merge $data $_usageBootstrapes }}
  {{- end }}
  {{- if $data }}
    {{- include "base.field" (list "data" $data "base.map.b64enc") }}
  {{- end }}

  {{- /* stringData object/map */ -}}
  {{- $stringDataAllowTypes := list "Opaque" "kubernetes.io/dockercfg" "kubernetes.io/dockerconfigjson" }}
  {{- $_type := include "base.getValue" (list . "type") }}
  {{- if or (empty $_type) (has $type $stringDataAllowTypes) }}
    {{- $stringData := include "base.getValue" (list . "stringData") | fromYaml }}
    {{- /*
      # 读取内容后与 stringData 合并
      # 优先级 stringData < stringDataFileRefs 且 stringDataFileRefs 列表顺序覆盖
    */ -}}
      {{- $stringDataFileRefs := include "base.getValue" (list . "stringDataFileRefs") | fromYamlArray }}
      {{- range $stringDataFileRefs }}
        {{- $filePath := include "base.getValue" (list . "filePath") }}
        {{- $filePath = include "base.relPath" $filePath }}
        {{- if empty $filePath }}
          {{- fail "configStorage.Secret: stringDataFileRefs[].filePath cannot be empty" }}
        {{- end }}
        {{- $content := $.Files.Get $filePath }}

        {{- $key := include "base.getValue" (list . "key") }}
        {{- if empty $key }}
          {{- $key = base $filePath }}
        {{- end }}

        {{- $val := dict $key $content }}
        {{- $stringData = mergeOverwrite $stringData $val }}
      {{- end }}
    {{- if $stringData }}
      {{- include "base.field" (list "stringData" $stringData "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}
{{- end }}
