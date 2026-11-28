{{- /*
  渲染 Kubernetes DownwardAPIProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - items (DownwardAPIVolumeFile array, 可选): 原生 map 逐项委托 definitions.downwardAPIVolumeFile，空结果剔除，完全相同结果保留首个；空数组或全空结果省略。

  边界:
    - 只读取 items，其他字段静默忽略。
    - items 不是数组、条目不是 map 或子模板输出非法 YAML 时中断。
    - items 的 fieldRef、resourceFieldRef、mode、path 校验由 definitions.downwardAPIVolumeFile 负责；本模板不重复其内部结构。
    - definitions.downwardAPIVolumeFile 对合法输入不产生空输出；空结果剔除仅作为父模板容错。

  入参: 原生 map，形如 `{items: [{path: "meta/name", fieldRef: "metadata.name"}]}`。

  返回值: 可嵌入 VolumeProjection.downwardAPI 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.downwardAPIProjection" (dict "items" (list (dict "path" "meta/name" "fieldRef" "metadata.name"))) }}
      // items:
      //   - fieldRef:
      //       fieldPath: "metadata.name"
      //     path: "meta/name"
*/ -}}
{{- define "definitions.downwardAPIProjection" -}}
  {{- /* items（DownwardAPIVolumeFile array, 可选）: 原生 map 逐项委托 definitions.downwardAPIVolumeFile，空结果剔除并去重；空数组或全空结果省略。 */ -}}
  {{- $_items := fromYamlArray (include "base.get" (list . "items")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
    {{- fail "[definitions.downwardAPIProjection] items: must be array type" }}
  {{- end }}
  {{- $items := list }}
  {{- range $_item := $_items }}
    {{- if not (kindIs "map" $_item) }}
      {{- fail (printf "[definitions.downwardAPIProjection] items: each item must be object type, got '%s'" (kindOf $_item)) }}
    {{- end }}
    {{- $_rendered := fromYaml (include "definitions.downwardAPIVolumeFile" $_item) }}
    {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
      {{- fail "[definitions.downwardAPIProjection] items: definitions.downwardAPIVolumeFile rendered invalid YAML" }}
    {{- end }}
    {{- if $_rendered }}
      {{- $items = mustAppend $items $_rendered }}
    {{- end }}
  {{- end }}
  {{- $items = mustUniq $items }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}
{{- end }}
