{{- /*
  渲染 Kubernetes GroupVersionForDiscovery 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/group-version-for-discovery-v1-meta/#GroupVersionForDiscovery

  行为 (按 K8s API 规范字段顺序):
    - groupVersion (string, 必填): "group/version" 形式, 渲染模板 base.string。
    - version (string, 必填): "version" 形式, 渲染模板 base.string。
    - 禁止渲染 status、metadata 字段 (GroupVersionForDiscovery 在 K8s 中无 ObjectMeta 语义)。

  核心字段: 上下文 map, 由 definitions.APIGroup 解析后传入, 可包含以下字段:
    - groupVersion    (string, 必填)  API group/version, 例如 "meta/v1"
    - version         (string, 必填)  版本字符串, 例如 "v1.23.0"

  返回值: GroupVersionForDiscovery 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "definitions.groupVersionForDiscovery" . }}
*/ -}}
{{- define "definitions.groupVersionForDiscovery" -}}
  {{- /* Step 1: groupVersion (string, 必填): "group/version" 形式, 上游 APIGroup 已通过 API_GROUP.GROUP_VERSION_DISCOVERY 正则分组提取 (${1}) */ -}}
  {{- $_groupVersion := include "base.get" (list . "groupVersion") }}
  {{- if or (not $_groupVersion) (eq $_groupVersion "null") }}
    {{- fail "[definitions.groupVersionForDiscovery] groupVersion: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "groupVersion" $_groupVersion "base.string") }}

  {{- /* Step 2: version (string, 必填): "version" 形式, 上游 APIGroup 已通过 API_GROUP.GROUP_VERSION_DISCOVERY 正则分组提取 (${2}) */ -}}
  {{- $_version := include "base.get" (list . "version") }}
  {{- if or (not $_version) (eq $_version "null") }}
    {{- fail "[definitions.groupVersionForDiscovery] version: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "version" $_version "base.string") }}
{{- end }}
