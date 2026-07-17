{{- /*
  渲染 Kubernetes ObjectMeta 元数据块。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#objectmeta-v1-meta

  行为:
    - 从上下文 (.Context > .Values > .Values.global) 逐字段取值并按 K8s API 规范输出。
    - 依据 _kind / _pkind 自动跳过不适用的字段:
        - PodTemplateSpec / JobTemplateSpec: 无独立 metadata，跳过 annotations / name / namespace
        - StatefulSetSpec: volumeClaimTemplates 共享 metadata，跳过 annotations / labels
        - Namespace / ClusterRole / ClusterRoleBinding / Role / RoleBinding: 集群级或特殊语义，跳过 namespace
    - 嵌套资源场景下 _pkind 优先于 _kind (例如 StatefulSet 调用 PersistentVolumeClaim 时 _pkind=StatefulSetSpec)。

  入参: 上下文 map，需包含以下字段:
    - _kind   (string)  当前资源类型
    - _pkind  (string, 可选)  父资源类型 (嵌套资源场景)
    - 其余字段从 .Context / .Values 取值 (annotations / generateName / labels / name / namespace)

  返回值: YAML 格式的 ObjectMeta 键值对 (不含 metadata 父键)，调用方自行包入 metadata 块。

  示例:
    {{- include "definitions.objectMeta" . }}
*/ -}}
{{- define "definitions.objectMeta" -}}
  {{- /* 取值顺序: _pkind > _kind; _pkind 大部分时候应为空，仅在嵌套资源 (如 StatefulSetSpec -> PersistentVolumeClaim) 时被设置 */ -}}
  {{- $_pkind := include "base.get" (list . "_pkind") }}
  {{- $_kind := include "base.get" (list . "_kind") }}
  {{- $_kind = coalesce $_pkind $_kind }}

  {{- /* annotations map: 字符串键值对，外部工具使用的非查询性元数据
       PodTemplateSpec / JobTemplateSpec / StatefulSetSpec 不渲染 (嵌套资源由父资源统一管理)
       兼容 Helm 4.2.2 fromYaml 对 string/slice 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测 */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "StatefulSetSpec")) }}
    {{- $annotations := include "base.get" (list . "annotations") | fromYaml }}
    {{- if and $annotations (eq (include "base.isFromYamlError" $annotations) "false") (kindIs "map" $annotations) }}
      {{- include "base.field" (list "annotations" $annotations "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* generateName string: 仅在 name 未指定时由服务器生成唯一名的可选前缀，校验规则同 name (RFC1035) */ -}}
  {{- $generateName := include "base.get" (list . "generateName") }}
  {{- if $generateName }}
    {{- $_ := include "base.rfc" (list $generateName "1035") }}
    {{- include "base.field" (list "generateName" $generateName "quote") }}
  {{- end }}

  {{- /* labels map: 用于组织与选择对象的字符串键值对
       StatefulSetSpec 不渲染 (其 spec.selector 与 pod template 共享标签)
       兼容 Helm 4.2.2 fromYaml 对 string/slice 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测 */ -}}
  {{- if ne $_kind "StatefulSetSpec" }}
    {{- $labels := include "base.labels" . | fromYaml }}
    {{- if and $labels (eq (include "base.isFromYamlError" $labels) "false") (kindIs "map" $labels) }}
      {{- include "base.field" (list "labels" $labels "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* name string: 命名空间内唯一标识
       PodTemplateSpec / JobTemplateSpec 不渲染 (无独立 metadata)
       RBAC 与 APIService 类型使用对应的校验模式 (允许大小写 / 多级域名) */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec")) }}
    {{- $_name := "" }}
    {{- if or (eq $_kind "ClusterRole") (eq $_kind "Role") (eq $_kind "ClusterRoleBinding") (eq $_kind "RoleBinding") }}
      {{- $_name = include "base.name" (list . "rbac") }}
    {{- else if eq $_kind "APIService" }}
      {{- $_name = include "base.name" (list . "apiservice") }}
    {{- else }}
      {{- $_name = include "base.name" . }}
    {{- end }}
    {{- if $_name }}
      {{- include "base.field" (list "name" $_name "quote") }}
    {{- end }}
  {{- end }}

  {{- /* namespace string: 命名空间定义值空间
       PodTemplateSpec / JobTemplateSpec 不渲染 (无独立 metadata)
       Namespace 自身的 namespace 为空; ClusterRole / ClusterRoleBinding 为集群级资源，无 namespace
       Role / RoleBinding 为命名空间级资源，同样排除 (由调用方按 RBAC 场景统一处理) */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "Namespace") (eq $_kind "ClusterRole") (eq $_kind "ClusterRoleBinding") (eq $_kind "Role") (eq $_kind "RoleBinding")) }}
    {{- $nsStr := include "base.get" (list . "namespace") }}
    {{- if $nsStr }}
      {{- $namespace := include "base.namespace" $nsStr }}
      {{- if $namespace }}
        {{- include "base.field" (list "namespace" $namespace "quote") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
