{{- /*
  渲染 Kubernetes ObjectMeta 字段片段。

  边界:
    - 只输出 annotations、generateName、labels、name 和 namespace，不包含 metadata 外层键。
    - _pkind 优先于 _kind 决定资源身份，两个控制字段均只读且不进入输出。
    - 专用注解来源、名称模式和 namespace 排除范围由资源身份决定。

  入参:
    - . (map): 包含资源身份、ObjectMeta 字段和 base 能力所需上下文的字典

  返回值: 可嵌入 metadata 下的 ObjectMeta YAML 字段片段；非法入参中断渲染。

  示例:
    {{- include "definitions.objectMeta" (dict "_kind" "Deployment" "name" "demo") }}
*/ -}}
{{- define "definitions.objectMeta" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail (printf "[definitions.objectMeta] context: expected map type, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}

  {{- $_pkind := include "base.get" (list . "_pkind") }}
  {{- $_kind := include "base.get" (list . "_kind") }}
  {{- $effectiveKind := coalesce $_pkind $_kind }}

  {{- /* annotations（map[string]string）: 按有效资源身份选择专用或通用注解来源。 */ -}}
  {{- $annotationsPath := "annotations" }}
  {{- if eq $effectiveKind "PodTemplateSpec" }}
    {{- $annotationsPath = "podAnnotations" }}

  {{- else if eq $effectiveKind "JobTemplateSpec" }}
    {{- $annotationsPath = "jobAnnotations" }}

  {{- else if eq $effectiveKind "PersistentVolumeClaim" }}
    {{- $annotationsPath = "pvcAnnotations" }}
  {{- end }}

  {{- $_annotationsRaw := include "base.get" (list . $annotationsPath) }}
  {{- if $_annotationsRaw }}
    {{- $_annotationsParsed := fromYaml $_annotationsRaw }}
    {{- if eq (include "base.isFromYamlError" $_annotationsParsed) "true" }}
      {{- fail (printf "[definitions.objectMeta] %s: expected map[string]string, got invalid YAML" $annotationsPath) }}
    {{- end }}
    {{- if not (kindIs "map" $_annotationsParsed) }}
      {{- fail (printf "[definitions.objectMeta] %s: expected map[string]string, got %s" $annotationsPath (kindOf $_annotationsParsed)) }}
    {{- end }}
    {{- range $key, $value := $_annotationsParsed }}
      {{- if not (kindIs "string" $value) }}
        {{- fail (printf "[definitions.objectMeta] %s.%s: expected string type, got %s" $annotationsPath $key (kindOf $value)) }}
      {{- end }}
    {{- end }}
    {{- $annotations := $_annotationsParsed }}
    {{- if $annotations }}
      {{- include "base.field" (list "annotations" $annotations "base.map") }}
    {{- end }}
  {{- end }}

  {{- $_nameRaw := include "base.get" (list . "name") }}
  {{- $_generateNameRaw := include "base.get" (list . "generateName") }}
  {{- $useGenerateName := and (empty $_nameRaw) (not (empty $_generateNameRaw)) }}

  {{- /* generateName（string）: 仅在 name 解析为空时按 RFC1035 校验并渲染。 */ -}}
  {{- if $useGenerateName }}
    {{- $generateName := include "base.rfc" (list $_generateNameRaw "1035") }}
    {{- include "base.field" (list "generateName" $generateName) }}
  {{- end }}

  {{- /* labels（map[string]string）: 原样委托 base.labels 并验证其结构化返回值。 */ -}}
  {{- $_labelsRaw := required "[definitions.objectMeta] labels: base.labels returned empty output" (include "base.labels" .) }}
  {{- $_labelsParsed := fromYaml $_labelsRaw }}
  {{- if eq (include "base.isFromYamlError" $_labelsParsed) "true" }}
    {{- fail "[definitions.objectMeta] labels: expected map[string]string, got invalid YAML" }}
  {{- end }}
  {{- if not (kindIs "map" $_labelsParsed) }}
    {{- fail (printf "[definitions.objectMeta] labels: expected map[string]string, got %s" (kindOf $_labelsParsed)) }}
  {{- end }}
  {{- $labels := $_labelsParsed }}
  {{- range $key, $value := $labels }}
    {{- if not (kindIs "string" $value) }}
      {{- fail (printf "[definitions.objectMeta] labels.%s: expected string type, got %s" $key (kindOf $value)) }}
    {{- end }}
  {{- end }}
  {{- include "base.field" (list "labels" $labels "base.map") }}

  {{- /* name（string）: 按资源身份委托 base.name，嵌套模板或 generateName 生效时省略。 */ -}}
  {{- if and (not $useGenerateName) (not (has $effectiveKind (list "PodTemplateSpec" "JobTemplateSpec"))) }}
    {{- $nameMode := "name" }}
    {{- if has $effectiveKind (list "ClusterRole" "Role" "ClusterRoleBinding" "RoleBinding") }}
      {{- $nameMode = "rbac" }}

    {{- else if eq $effectiveKind "APIService" }}
      {{- $nameMode = "apiservice" }}
    {{- end }}

    {{- $name := "" }}
    {{- if eq $nameMode "name" }}
      {{- $name = include "base.name" . }}

    {{- else }}
      {{- $name = include "base.name" (list . $nameMode) }}
    {{- end }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* namespace（string）: 除嵌套、PVC 与集群级对象外原样委托 base.namespace。 */ -}}
  {{- if not (has $effectiveKind (list "PodTemplateSpec" "JobTemplateSpec" "PersistentVolumeClaim" "ClusterRole" "ClusterRoleBinding")) }}
    {{- $namespace := include "base.namespace" . }}
    {{- include "base.field" (list "namespace" $namespace) }}
  {{- end }}
{{- end }}
