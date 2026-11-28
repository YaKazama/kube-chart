{{- /*
  渲染 Kubernetes VolumeProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - clusterTrustBundle  (ClusterTrustBundleProjection, 必填之一): 委托 definitions.clusterTrustBundleProjection。
    - configMap           (ConfigMapProjection, 必填之一): 委托 definitions.configMapProjection。
    - downwardAPI         (DownwardAPIProjection, 必填之一): 委托 definitions.downwardAPIProjection。
    - podCertificate      (PodCertificateProjection, 必填之一): 委托 definitions.podCertificateProjection。
    - secret              (SecretProjection, 必填之一): 委托 definitions.secretProjection。
    - serviceAccountToken (ServiceAccountTokenProjection, 必填之一): 委托 definitions.serviceAccountTokenProjection。

  边界:
    - 六个字段互斥且必须恰好出现一个；零个或多个时中断并列出实际字段名。
    - 唯一字段值必须为非空原生 map；空 map、null 或其他类型中断，不提供 string 简写。
    - 六个子模板当前不可用且不在本 change 创建，只保留调用占位；其输出为空或非法 YAML 时中断。
    - 其他输入字段静默忽略。

  入参: map，形如 `{configMap: {name: "cfg"}}`。

  返回值: 以唯一字段名为顶层键的单字段 YAML 片段。

  示例:
    {{- include "definitions.volumeProjection" (dict "configMap" (dict "name" "cfg")) }}
      // configMap:
      //   ...
*/ -}}
{{- define "definitions.volumeProjection" -}}
  {{- /* 六个互斥字段的配置表：字段名与子模板名，按 API 顺序排列。 */ -}}
  {{- $sources := list
    (dict "key" "clusterTrustBundle" "define" "definitions.clusterTrustBundleProjection")
    (dict "key" "configMap" "define" "definitions.configMapProjection")
    (dict "key" "downwardAPI" "define" "definitions.downwardAPIProjection")
    (dict "key" "podCertificate" "define" "definitions.podCertificateProjection")
    (dict "key" "secret" "define" "definitions.secretProjection")
    (dict "key" "serviceAccountToken" "define" "definitions.serviceAccountTokenProjection")
  }}

  {{- /* 互斥校验: 收集实际出现的字段，零个或多个时在渲染前中断。 */ -}}
  {{- $present := list }}
  {{- range $source := $sources }}
    {{- if hasKey $ $source.key }}
      {{- $present = mustAppend $present $source.key }}
    {{- end }}
  {{- end }}
  {{- if ne (len $present) 1 }}
    {{- fail (printf "[definitions.volumeProjection] fields: exactly one is required, got '%v'" (join ", " $present)) }}
  {{- end }}

  {{- /* 字段值校验: 唯一字段必须为非空原生 map。 */ -}}
  {{- $key := index $present 0 }}
  {{- $value := include "base.get" (list $ $key) | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $value) "true" }}
    {{- fail (printf "[definitions.volumeProjection] %s: must be object type" $key) }}
  {{- end }}
  {{- if not $value }}
    {{- fail (printf "[definitions.volumeProjection] %s: required field is missing or empty" $key) }}
  {{- end }}

  {{- /* 委托子模板: 空输出与非法 YAML 中断，结果按唯一字段名输出。 */ -}}
  {{- range $source := $sources }}
    {{- if eq $source.key $key }}
      {{- $_rendered := fromYaml (include $source.define $value) }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail (printf "[definitions.volumeProjection] %s: invalid YAML output from %s" $key $source.define) }}
      {{- end }}
      {{- if not $_rendered }}
        {{- fail (printf "[definitions.volumeProjection] %s: %s rendered empty content" $key $source.define) }}
      {{- end }}
      {{- include "base.field" (list $key $_rendered "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
