目标: 新增命名模板 `definitions.objectMeta`，`templates/api-resources/Definitions/_ObjectMeta.tpl`
需求:
- 入参只有一个上下文 `.`。
- 根据参考文档中的 Field 和 Description，生成新的字段。
- 注意：
  - `PodTemplateSpec`、`JobTemplateSpec`、`StatefulSetSpec` 对 `annotations` 字段的处理。
  - `StatefulSetSpec` 对 `annotations` 字段的处理。
  - `PodTemplateSpec`、`JobTemplateSpec` 对 `name` 字段的处理。
  - `PodTemplateSpec`、`JobTemplateSpec`、`Namespace`、`ClusterRole`、`ClusterRoleBinding`、`Role`、`RoleBinding` 对 `namespace` 字段的处理。
约束:
- 模板可以继续向下透传上下文 `.`。
- Time 类型调用 `base.time` 模板。
- 中文重写注释。
- 涉及 `base.env` 的正则表达式，参考 `docs/template/base/env.md`，只选取需要的写入 `templates/base/_env.tpl`；禁止将参考示例全量写入新文件。
- 完成后需要检查是否有隐性 BUG 并修复。
- 多行注释特别注意换行格式。
参考:
- 官方 API 文档：https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#objectmeta-v1-meta
- 示例代码：

  ```text
  {{- define "definitions.ObjectMeta" -}}
    {{- /* 取值顺序 _pkind > _kind */ -}}
    {{- /* _pkind 大部分时候应该为空值，在 StatefulSetSpec 调用 PersistentVolumeClaim 时会被设置为 StatefulSetSpec */ -}}
    {{- $_kind := coalesce (get . "_pkind") (get . "_kind") }}

    {{- /* annotations map */ -}}
    {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "StatefulSetSpec")) }}
      {{- $annotations := include "base.getValue" (list . "annotations") | fromYaml }}
      {{- if $annotations }}
        {{- include "base.field" (list "annotations" $annotations "base.map") }}
      {{- end }}
    {{- end }}

    {{- /* labels map */ -}}
    {{- if not (or (eq $_kind "StatefulSetSpec")) }}
      {{- $labels := include "base.labels" . | fromYaml }}
      {{- if $labels }}
        {{- include "base.field" (list "labels" $labels "base.map") }}
      {{- end }}
    {{- end }}

    {{- /* name string */ -}}
    {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec")) }}
      {{- $_name := "" }}
      {{- if or (eq $_kind "ClusterRole") (eq $_kind "Role") (eq $_kind "ClusterRoleBinding") (eq $_kind "RoleBinding") }}
        {{- $_name = include "base.name.rbac" . }}
      {{- else if eq $_kind "APIService" }}
        {{- $_name = include "base.name.apiservice" . }}
      {{- else }}
        {{- $_name = include "base.name" . }}
      {{- end }}
      {{- if $_name }}
        {{- include "base.field" (list "name" $_name) }}
      {{- end }}
    {{- end }}

    {{- /* namespace string */ -}}
    {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "Namespace") (eq $_kind "ClusterRole") (eq $_kind "ClusterRoleBinding")) }}
      {{- $namespace := include "base.namespace" . }}
      {{- if $namespace }}
        {{- include "base.field" (list "namespace" $namespace) }}
      {{- end }}
    {{- end }}
  {{- end }}
  ```
