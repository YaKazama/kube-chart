{{- /*
  渲染 Kubernetes ObjectFieldSelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - apiVersion (string, 可选): 按 YAML 标量语义解码后以带引号标量输出；缺省时不输出该字段，不补官方默认值 v1。
    - fieldPath (string, 必填): 解码后判空，再按官方支持的路径集校验，通过后以带引号标量输出。

  边界:
    - 只输出 apiVersion 与 fieldPath，不包含 fieldRef 父键。
    - 除上述两个字段以外的入参字段静默忽略。
    - fieldPath 的支持路径集由 base.env 的 K8S.FIELD_REF 常量收口，为 EnvVarSource 与 DownwardAPIVolumeFile 两处官方路径集的并集；不在集合内即中断。
    - 不校验 metadata.labels/annotations 括号内的键是否符合 Kubernetes 标签语法。
    - 不按调用方区分路径集：EnvVarSource 专属路径在 DownwardAPIVolumeFile 场景下会被 API Server 拒绝。
    - 不校验 apiVersion 的合法取值。

  入参: 上下文 map，可包含以下字段:
    - apiVersion (string, 可选) fieldPath 所属的 schema 版本
    - fieldPath  (string, 必填) 所选字段的路径

  返回值: 可嵌入 fieldRef 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.objectFieldSelector" (dict "fieldPath" "metadata.name") }}
    {{- include "definitions.objectFieldSelector" (dict "apiVersion" "v1" "fieldPath" "spec.nodeName") }}
*/ -}}
{{- define "definitions.objectFieldSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* apiVersion（string, 可选）: 非空时以带引号标量输出；缺省时跳过，不补官方默认值 v1。 */ -}}
  {{- $apiVersion := include "base.string.normalize" (include "base.get" (list . "apiVersion")) | trim }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion "quote") }}
  {{- end }}

  {{- /* fieldPath（string, 必填）: 解码后判空，再按 K8S.FIELD_REF 限定为官方支持的路径并集。 */ -}}
  {{- $fieldPath := include "base.string.normalize" (include "base.get" (list . "fieldPath")) | trim }}
  {{- if not $fieldPath }}
    {{- fail "[definitions.objectFieldSelector] fieldPath: required field is missing or empty" }}
  {{- end }}
  {{- if not (mustRegexMatch $const.K8S.FIELD_REF $fieldPath) }}
    {{- fail (printf "[definitions.objectFieldSelector] fieldPath: '%s' is not a supported field path" $fieldPath) }}
  {{- end }}
  {{- include "base.field" (list "fieldPath" $fieldPath "quote") }}
{{- end }}
