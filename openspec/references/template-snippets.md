# Helm 模板编码片段

本文件提供与当前实现和规则一致的内部片段，按需参考；它不替代 `rules/`、正式 SDD 或 Helm 渲染证据，也不创建需求或约束。

## API 类型表达

整体契约与字段注释使用官方字段表中的 API 类型；Schema 和 Helm/Go 表达只在各自语境中使用。

| 官方字段表 | 契约或字段注释 | Schema | Helm/Go 运行时 |
|---|---|---|---|
| `object` | `annotations (object, 可选)` | `type: object` | `map`、`map[string]string` |
| `integer` | `replicas (integer, 可选)` | `type: integer` | `int`、`int64`、`float64` |
| `boolean` | `paused (boolean, 可选)` | `type: boolean` | `bool` |
| `string array` | `finalizers (string array, 可选)` | `type: array` + `items.type: string` | `slice`、`[]string` |
| `OwnerReference array` | `ownerReferences (OwnerReference array, 可选)` | `type: array` + `items.$ref` | `slice`、`[]OwnerReference` |

数组类型保留元素类型，不简写为 `array`。

## 命名模板注释

整体契约依次说明功能、行为、边界、入参、返回值和最小示例。直接渲染 Kubernetes API 字段时，行为按 API 字段顺序概述官方类型、渲染条件或委托关系；`define` 内的字段注释说明字段名称、官方类型和当前层功能，不重复处理闭环的内部细节。

```gotemplate
{{- /*
  渲染 Kubernetes ExampleSpec 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - labels (object, 可选): 非空时渲染，值必须为 string 类型。
    - selector (LabelSelector, 必填): 委托 definitions.labelSelector 渲染。

  边界: 只输出当前层字段，不包含 spec 父键；selector 的结构校验由下层模板收口。

  入参: 上下文 map，可包含以下字段:
    - labels   (object, 可选)        标签键值
    - selector (LabelSelector, 必填) 标签选择器

  返回值: 可嵌入 spec 下的 ExampleSpec YAML 字段片段。

  示例:
    {{- include "example.spec" . }}
*/ -}}
{{- define "example.spec" -}}
  {{- /* labels（object）: 非空时渲染并校验值为 string 类型。 */ -}}
  ...

  {{- /* selector（LabelSelector）: 委托 definitions.labelSelector 渲染。 */ -}}
  ...
{{- end }}
```

## 固定资源身份

资源模板固定输出 API 版本和类型，不接受调用方覆盖。`nindent 0 ""` 控制顶层空白。

```gotemplate
{{- nindent 0 "" -}}apiVersion: "apps/v1"
{{- nindent 0 "" -}}kind: "Deployment"
```

## 必填 Map 委托

必填且要求非空的 map 须在 `fromYaml` 后依次检查错误 map、实际类型和恢复后的空值，再以 `base.field` 嵌入父字段。Helm 4.2.2 会把空输出和 `null` 恢复为空 map，不得在解析前重复检查原始字符串。

```gotemplate
{{- $metadata := include "definitions.objectMeta" . | fromYaml }}
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
{{- $labels := include "base.get" (list . "labels" "" "right") | fromYaml }}
{{- if eq (include "base.isFromYamlError" $labels) "true" }}
  {{- fail "[example.template] labels: must be map type" }}
{{- end }}
{{- if not (kindIs "map" $labels) }}
  {{- fail "[example.template] labels: must be map type" }}
{{- end }}
{{- if $labels }}
  {{- include "base.field" (list "labels" $labels "base.map") }}
{{- end }}
```

## 多类型字段规整

字段允许 map 与字符串简写时，按“有效 map / 其余输入统一按 string 简写全量匹配 / 不匹配即失败”分支。字符串先剥离 YAML 引号，再用单条正则一次性捕获全部位置槽，每个捕获值分别剥离外层引号后使用。

```gotemplate
{{- $_parsed := $_raw | fromYaml }}
{{- $_isErr := eq (include "base.isFromYamlError" $_parsed) "true" }}
{{- $_const := include "base.env" "" | fromYaml }}
{{- $value := dict }}

{{- if and (not $_isErr) (kindIs "map" $_parsed) }}
  {{- $value = $_parsed }}

{{- else }}
  {{- $_unquoted := mustRegexReplaceAll $_const.SYS.YAML_QUOTED ($_raw | trim) "$1" | trim }}
  {{- if not (mustRegexMatch $_const.APPS.DEPLOYMENT.STRATEGY $_unquoted) }}
    {{- fail "[example.template] value: string does not match the supported format" }}
  {{- end }}
  {{- $_type := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_unquoted "$1") "$1" | trim }}
  {{- $_maxSurge := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_unquoted "$2") "$1" | trim }}
  {{- $_maxUnavailable := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_unquoted "$3") "$1" | trim }}

  {{- if or $_type $_maxSurge $_maxUnavailable }}
    {{- $_ := set $value "type" (ternary "Recreate" "RollingUpdate" (eq "recreate" (lower $_type))) }}
    {{- if $_maxSurge }}
      {{- $_ := set $value "maxSurge" $_maxSurge }}
    {{- end }}
    {{- if $_maxUnavailable }}
      {{- $_ := set $value "maxUnavailable" $_maxUnavailable }}
    {{- end }}
  {{- end }}
{{- end }}
```

示例使用当前正式常量 `APPS.DEPLOYMENT.STRATEGY` 展示精确键读取：该常量为单次全量匹配，捕获组 1/2/3 依次对应 `type`、`maxSurge`、`maxUnavailable`。示例只表达槽位捕获与逐槽去引号的通用形态，具体字段生效条件、默认值与互斥关系由各自规格约束。实际模板只能使用当前 design 锁定的键路径；常量归属、行为规格、设计边界、匹配捕获与验证统一遵循 [`Helm 模板工程规则`](../rules/helm-templates.md#正则契约)。

不得省略 `fromYaml`/`fromYamlArray` 的错误与真实类型检查，也不得修改未经 `mustDeepCopy` 隔离的 `.Values` 或共享输入。
