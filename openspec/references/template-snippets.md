# Helm 模板编码片段

本文件提供与当前实现和规则一致的内部片段，按需参考；它不替代 `rules/`、正式 SDD 或 Helm 渲染证据，也不创建需求或约束。

## 固定资源身份

资源模板固定输出 API 版本和类型，不接受调用方覆盖。`nindent 0 ""` 控制顶层空白。

```gotemplate
{{- nindent 0 "" -}}apiVersion: "apps/v1"
{{- nindent 0 "" -}}kind: "Deployment"
```

## 必填 Map 委托

必填 map 须依次检查空输出、Helm 4.2.2 的 `fromYaml` 错误 map 和实际类型，再以 `base.field` 嵌入父字段。

```gotemplate
{{- $_metadataRaw := include "definitions.objectMeta" . }}
{{- if not $_metadataRaw }}
  {{- fail "[apps.deployment] metadata: required field is missing or empty" }}
{{- end }}
{{- $metadata := $_metadataRaw | fromYaml }}
{{- if eq (include "base.isFromYamlError" $metadata) "true" }}
  {{- fail "[apps.deployment] metadata: invalid YAML output from definitions.objectMeta" }}
{{- end }}
{{- if not (kindIs "map" $metadata) }}
  {{- fail "[apps.deployment] metadata: must be map type" }}
{{- end }}
{{- if not $metadata }}
  {{- fail "[apps.deployment] metadata: required field is missing or empty" }}
{{- end }}
{{- include "base.field" (list "metadata" $metadata "base.map") }}
```

## `base.get` 取值

`base.get` 返回 YAML 字符串。map/list 恢复后执行错误与类型检查。

```gotemplate
{{- $_labelsRaw := include "base.get" (list . "labels" "" "right") }}
{{- if $_labelsRaw }}
  {{- $labels := $_labelsRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $labels) "true" }}
    {{- fail "[example.template] labels: must be map type" }}
  {{- end }}
  {{- if not (kindIs "map" $labels) }}
    {{- fail "[example.template] labels: must be map type" }}
  {{- end }}
  {{- if $labels }}
    {{- include "base.field" (list "labels" $labels "base.map") }}
  {{- end }}
{{- end }}
```

## 多类型字段规整

字段允许 map 与字符串简写时，按“有效 map / 受正则约束的 string / 其他类型失败”分支。字符串先剥离 YAML 引号，再匹配并提取捕获组。

```gotemplate
{{- $_parsed := $_raw | fromYaml }}
{{- $_isErr := eq (include "base.isFromYamlError" $_parsed) "true" }}
{{- $_isMap := and (kindIs "map" $_parsed) (not $_isErr) }}
{{- $_const := include "base.env" "" | fromYaml }}
{{- $_unquoted := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_raw "$1" | trim }}
{{- $value := dict }}

{{- if $_isMap }}
  {{- $value = $_parsed }}

{{- else if and $_isErr (mustRegexMatch $pattern $_unquoted) }}
  {{- $_first := mustRegexReplaceAll $pattern $_unquoted "${1}" | trim }}
  {{- $_second := mustRegexReplaceAll $pattern $_unquoted "${2}" | trim }}
  {{- $value = dict "first" $_first "second" $_second }}

{{- else }}
  {{- fail "[example.template] value: must be map or supported string type" }}
{{- end }}
```

`$pattern` 必须来自当前 Spec 列出的 `templates/base/_env.tpl` 常量键，不得在模板中重复定义；正则使用 `must*` 变体，捕获结果必须 `trim`。

不得省略 `fromYaml`/`fromYamlArray` 的错误与真实类型检查，也不得修改未经 `mustDeepCopy` 隔离的 `.Values` 或共享输入。
