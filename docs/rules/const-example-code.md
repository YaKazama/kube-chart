# 示例代码

## 常用示例

注释：

```text
{{- /* 单行注释 */ -}}
{{- /*
  多行注释
  多行注释
*/ -}}
```

apiVersion 和 kind 字段：

```text
{{- nindent 0 "" -}}apiVersion: "meta/v1"
{{- nindent 0 "" -}}kind: "APIGroup"
```

metadata 字段, 示例：

```text
{{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
{{- if $metadata }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}
{{- end }}
```

组装 dict 并向下传递，正则拆分字符串取值并向下传递：

```text
{{- $const := include "base.env" "" | fromYaml }}
{{- $name := mustRegexReplaceAll $const.k8s.volume.configMap $volumeData "${1}" | trim | lower  }}
{{- $optional := mustRegexReplaceAll $const.k8s.volume.configMap $volumeData "${2}" | trim }}
{{- $defaultMode := mustRegexReplaceAll $const.k8s.volume.configMap $volumeData "${3}" | trim }}
{{- $items := mustRegexSplit $const.split.comma (mustRegexReplaceAll $const.k8s.volume.configMap $volumeData "${4}" | trim) -1 }}
{{- $val := dict "name" $name "optional" $optional "defaultMode" $defaultMode "items" $items }}
{{- $cm := include "definitions.A" $val | fromYaml }}
```

```text
{{- $const := include "base.env" "" | fromYaml }}
{{- $unquotePattern := $const.SYS.YAML_QUOTED }}
{{- $rUnquoted := mustRegexReplaceAll $unquotePattern $_rollingUpdateRaw "$1" | trim }}
```

base.get 取值：

```text
// 基础取值
{{- $targetVal := include "base.get" (list . "key") }}
// 强制类型 + 必填校验
{{- $repo := include "base.get" (list . "key" "" "" true) }}
// 字典右优覆盖合并
{{- $labels := include "base.get" (list . "key" "" "right") }}
```

base.field 渲染字段：

```text
// 常规渲染
{{- include "base.field" (list "replicas" $replicas) }}
{{- include "base.field" (list "replicas" $replicas "base.int") }}
{{- include "base.field" (list "replicas" $replicas "base.bool") }}
// 强制加引号
{{- include "base.field" (list "tag" $tag "quote") }}
// 枚举校验 (只允许 "Always" / "IfNotPresent")
{{- $allows := list "Always" "IfNotPresent" }}
{{- include "base.field" (list "pullPolicy" $policy "base.string" $allows) }}
```

spec 字段, 示例：

```text
  {{- $spec := include "workloads.DeploymentSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
```

template 字段委托 PodTemplateSpec 渲染，示例：

```text
{{- $template := include "core.podTemplateSpec" . | fromYaml }}
{{- if $template }}
  {{- include "base.field" (list "template" $template "base.map") }}
{{- end }}
```

## 禁止示例

```
{{- $in = dict
"maxSurge" (regexReplaceAll $const.APPS.DEPLOYMENT.ROLLING_UPDATE $rTrimmed "${1}" | trim)
"maxUnavailable" (regexReplaceAll $const.APPS.DEPLOYMENT.ROLLING_UPDATE $rTrimmed "${2}" | trim) }}
```
