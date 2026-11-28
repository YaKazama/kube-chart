{{- /*
  渲染 Kubernetes PodCertificateProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - certificateChainPath (string, 可选): 相对路径，与 keyPath 成对出现；以带引号标量输出。
    - credentialBundlePath (string, 可选): 相对路径，单文件布局；以带引号标量输出。
    - keyPath             (string, 可选): 相对路径，与 certificateChainPath 成对出现；以带引号标量输出。
    - keyType             (string, 必填): 仅允许 RSA3072、RSA4096、ECDSAP256、ECDSAP384、ECDSAP521、ED25519。
    - maxExpirationSeconds (integer, 可选): 3600-7862400 秒，越界或非整数时中断；空值省略。
    - signerName          (string, 必填): 解码后 trim 判空，以带引号标量输出。
    - userAnnotations     (object, 可选): 键为带 DNS 子域前缀的限定名，值为 string；键经 trim 与语法校验后输出，空 map 省略。

  边界:
    - keyPath 与 certificateChainPath 必须同时出现或同时缺失。
    - credentialBundlePath 单文件方式与 keyPath + certificateChainPath 双文件方式必须至少配置一种，可同时配置。
    - 三个路径字段配置时必须为相对路径。
    - 只读取上述七个字段，其他字段静默忽略；按 API 顺序输出已生效字段。

  入参: 原生 map，形如 `{signerName: "example.com/signer", keyType: "RSA3072", credentialBundlePath: "credential-bundle.pem"}`。

  返回值: 可嵌入 VolumeProjection.podCertificate 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.podCertificateProjection" (dict "signerName" "example.com/signer" "keyType" "RSA3072" "credentialBundlePath" "credential-bundle.pem") }}
      // credentialBundlePath: "credential-bundle.pem"
      // keyType: RSA3072
      // signerName: "example.com/signer"
*/ -}}
{{- define "definitions.podCertificateProjection" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* certificateChainPath、credentialBundlePath、keyPath（string, 可选, 相互关联）: 读取并 trim；keyPath 与 certificateChainPath 必须成对，且至少配置一种文件布局。 */ -}}
  {{- $certificateChainPath := include "base.string.normalize" (include "base.get" (list . "certificateChainPath")) | trim }}
  {{- $credentialBundlePath := include "base.string.normalize" (include "base.get" (list . "credentialBundlePath")) | trim }}
  {{- $keyPath := include "base.string.normalize" (include "base.get" (list . "keyPath")) | trim }}
  {{- if ne (empty $keyPath) (empty $certificateChainPath) }}
    {{- fail "[definitions.podCertificateProjection] fields: 'keyPath' and 'certificateChainPath' must be set together" }}
  {{- end }}
  {{- if and (not $credentialBundlePath) (not (and $keyPath $certificateChainPath)) }}
    {{- fail "[definitions.podCertificateProjection] fields: at least one of 'credentialBundlePath' or 'keyPath' with 'certificateChainPath' is required" }}
  {{- end }}

  {{- /* certificateChainPath（string, 可选）: 相对路径，以带引号标量输出。 */ -}}
  {{- if $certificateChainPath }}
    {{- include "base.field" (list "certificateChainPath" (include "base.path" (list $certificateChainPath "rel")) "quote") }}
  {{- end }}

  {{- /* credentialBundlePath（string, 可选）: 相对路径，以带引号标量输出。 */ -}}
  {{- if $credentialBundlePath }}
    {{- include "base.field" (list "credentialBundlePath" (include "base.path" (list $credentialBundlePath "rel")) "quote") }}
  {{- end }}

  {{- /* keyPath（string, 可选）: 相对路径，以带引号标量输出。 */ -}}
  {{- if $keyPath }}
    {{- include "base.field" (list "keyPath" (include "base.path" (list $keyPath "rel")) "quote") }}
  {{- end }}

  {{- /* keyType（string, 必填）: 解码后 trim 判空，仅允许六个枚举值。 */ -}}
  {{- $keyType := include "base.string.normalize" (include "base.get" (list . "keyType")) | trim }}
  {{- if not $keyType }}
    {{- fail "[definitions.podCertificateProjection] keyType: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "keyType" $keyType "" (list "RSA3072" "RSA4096" "ECDSAP256" "ECDSAP384" "ECDSAP521" "ED25519")) }}

  {{- /* maxExpirationSeconds（integer, 可选）: 剥离 YAML 引号后归一化为整数并校验 3600-7862400，空值省略。 */ -}}
  {{- $_maxExpirationSecondsRaw := include "base.get" (list . "maxExpirationSeconds") | trim }}
  {{- if $_maxExpirationSecondsRaw }}
    {{- $maxExpirationSeconds := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_maxExpirationSecondsRaw "$1" | trim }}
    {{- if $maxExpirationSeconds }}
      {{- $maxExpirationSeconds = int (include "base.int" $maxExpirationSeconds) }}
      {{- $maxExpirationSeconds = include "base.int.range" (list $maxExpirationSeconds 3600 7862400) }}
      {{- include "base.field" (list "maxExpirationSeconds" $maxExpirationSeconds "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* signerName（string, 必填）: 解码后 trim 判空，以带引号标量输出。 */ -}}
  {{- $signerName := include "base.string.normalize" (include "base.get" (list . "signerName")) | trim }}
  {{- if not $signerName }}
    {{- fail "[definitions.podCertificateProjection] signerName: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "signerName" $signerName "quote") }}

  {{- /* userAnnotations（object, 可选）: 值为 string；键经 trim 与限定名校验并要求 DNS 子域前缀，空 map 省略。 */ -}}
  {{- $userAnnotations := fromYaml (include "base.get" (list . "userAnnotations")) }}
  {{- if eq (include "base.isFromYamlError" $userAnnotations) "true" }}
    {{- fail "[definitions.podCertificateProjection] userAnnotations: must be object type" }}
  {{- end }}
  {{- $normalizedAnnotations := dict }}
  {{- range $key, $value := $userAnnotations }}
    {{- if not (kindIs "string" $value) }}
      {{- fail (printf "[definitions.podCertificateProjection] userAnnotations.%s: expected string type, got %s" $key (kindOf $value)) }}
    {{- end }}
    {{- $_validKey := include "base.labelKey" (list $key "definitions.podCertificateProjection" (printf "userAnnotations.%s" $key)) }}
    {{- if not (contains "/" $_validKey) }}
      {{- fail (printf "[definitions.podCertificateProjection] userAnnotations.%s: annotation key must be domain-prefixed" $key) }}
    {{- end }}
    {{- $_ := set $normalizedAnnotations $_validKey $value }}
  {{- end }}
  {{- if $normalizedAnnotations }}
    {{- include "base.field" (list "userAnnotations" $normalizedAnnotations "base.map") }}
  {{- end }}
{{- end }}
