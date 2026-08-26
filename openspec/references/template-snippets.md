# Helm 模板编码片段

本文件展示与当前实现一致的内部模板写法，供规划和开发时按需参考。它不替代 `rules/` 的规则、资源正式 SDD 或 Helm 渲染证据，也不独立创建用户需求或工程约束。

## Go Template 注释

使用 Go Template 注释记录模板的功能、边界、入参和返回值；注释不会进入渲染结果。

```gotemplate
{{- /* 单行注释 */ -}}
{{- /*
  多行注释
*/ -}}
```

## 固定资源身份

资源级模板固定输出 API 版本和资源类型，不接受调用方覆盖。`nindent 0 ""` 用于控制顶层字段的空白。

```gotemplate
{{- nindent 0 "" -}}apiVersion: "apps/v1"
{{- nindent 0 "" -}}kind: "Deployment"
```

## 必填 Map 委托

委托模板返回 YAML 字符串。对于必填 map，必须同时检查空输出、Helm 4.2.2 的 `fromYaml` 错误 map 和实际类型，再以 `base.field` 嵌入父字段。

```gotemplate
{{- $metadata := include "definitions.objectMeta" . | fromYaml }}
{{- if not $metadata }}
  {{- fail "[apps.deployment] metadata: required field is missing or empty" }}
{{- end }}
{{- if eq (include "base.isFromYamlError" $metadata) "true" }}
  {{- fail "[apps.deployment] metadata: invalid YAML output from definitions.objectMeta" }}
{{- end }}
{{- if not (kindIs "map" $metadata) }}
  {{- fail "[apps.deployment] metadata: must be map type" }}
{{- end }}
{{- include "base.field" (list "metadata" $metadata "base.map") }}
```

## `base.get` 取值

`base.get` 返回 YAML 字符串。标量按对应类型安全转换；map 和 list 在解析后必须执行错误标识与类型检查。

```gotemplate
{{- $replicasRaw := include "base.get" (list . "replicas" "int") }}
{{- if $replicasRaw }}
  {{- $replicas := atoi $replicasRaw }}
  {{- include "base.field" (list "replicas" $replicas "base.int") }}
{{- end }}
```

```gotemplate
{{- $labelsRaw := include "base.get" (list . "labels" "" "right") }}
{{- if and $labelsRaw (ne $labelsRaw "{}") }}
  {{- $labels := $labelsRaw | fromYaml }}
  {{- if or (eq (include "base.isFromYamlError" $labels) "true") (not (kindIs "map" $labels)) }}
    {{- fail "[example.template] labels: must be map type" }}
  {{- end }}
{{- end }}
```

## `base.field` 渲染

`base.field` 统一处理字段排版、类型渲染、强制引号和枚举校验。

```gotemplate
{{- include "base.field" (list "replicas" $replicas "base.int") }}
{{- include "base.field" (list "paused" $paused "base.bool") }}
{{- include "base.field" (list "tag" $tag "quote") }}

{{- $allows := list "Always" "IfNotPresent" }}
{{- include "base.field" (list "pullPolicy" $policy "base.string" $allows) }}
```

## 多类型字段规整

一个字段同时允许 map 与字符串简写时，必须按“有效 map / 受正则约束的 string / 其他类型失败”分支处理。字符串路径先剥离 `base.get` 的 YAML 引号，再执行 `mustRegexMatch` 与捕获组提取。

```gotemplate
{{- $parsed := $raw | fromYaml }}
{{- $isErr := eq (include "base.isFromYamlError" $parsed) "true" }}
{{- $isMap := and (kindIs "map" $parsed) (not $isErr) }}
{{- $const := include "base.env" "" | fromYaml }}
{{- $unquoted := mustRegexReplaceAll $const.SYS.YAML_QUOTED $raw "$1" | trim }}
{{- $value := dict }}

{{- if $isMap }}
  {{- $value = $parsed }}

{{- else if and $isErr (mustRegexMatch $pattern $unquoted) }}
  {{- $first := mustRegexReplaceAll $pattern $unquoted "${1}" | trim }}
  {{- $second := mustRegexReplaceAll $pattern $unquoted "${2}" | trim }}
  {{- $value = dict "first" $first "second" $second }}

{{- else }}
  {{- fail "[example.template] value: must be map or supported string type" }}
{{- end }}
```

`$pattern` 必须来自当前 Spec 明确列出的 `templates/base/_env.tpl` 常量键，不能在模板中重复定义正则。

## 避免的写法

不要使用非 `must*` 正则函数；应使用 `mustRegexReplaceAll`，以便正则执行错误及时中断。

```gotemplate
{{- $maxSurge := mustRegexReplaceAll $const.APPS.DEPLOYMENT.ROLLING_UPDATE $raw "${1}" | trim }}
{{- $maxUnavailable := mustRegexReplaceAll $const.APPS.DEPLOYMENT.ROLLING_UPDATE $raw "${2}" | trim }}
```

不要省略 `fromYaml` / `fromYamlArray` 的错误标识与真实类型检查，也不要修改未经 `mustDeepCopy` 隔离的 `.Values` 或共享输入对象。
