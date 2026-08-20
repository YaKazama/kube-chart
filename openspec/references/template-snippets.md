# Helm 模板编码片段

本文件只提供与当前 base 实现或迁移前资源模板相连的局部模式，不替代规格、工程规则或渲染验证。`examples/tpls-bak/` 中的资源模板只用于迁移对照，不表示对应能力当前可由 Chart 调用。

## 模板注释

```gotemplate
{{- /*
功能：渲染资源。
边界：必填输出为空或类型非法时失败。
入参：根上下文及 Context 业务配置。
返回：单个 YAML 资源。
示例：include "apps.deployment" $ctx
*/ -}}
```

迁移前实现：[`examples/tpls-bak/_Deployment.tpl`](../../examples/tpls-bak/_Deployment.tpl)。

## 顶层 YAML 换行

开启左侧空白裁剪后，使用 `nindent 0 ""` 显式建立顶层字段换行，避免相邻输出粘连。

```gotemplate
{{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . | quote }}
{{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service | default "Helm" | quote }}
```

参考实现：[`templates/base/_k8s.tpl`](../../templates/base/_k8s.tpl)。

## 必填 map 委托

```gotemplate
{{- $raw := include "definitions.objectMeta" . -}}
{{- $value := $raw | fromYaml -}}
{{- if or (empty $raw) (eq (include "base.isFromYamlError" $value) "true") (not (kindIs "map" $value)) -}}
  {{- fail "[apps.deployment] metadata: 必须为有效 map" -}}
{{- end -}}
{{- include "base.field" (list "metadata" $value "base.map") -}}
```

迁移前实现：[`examples/tpls-bak/_Deployment.tpl`](../../examples/tpls-bak/_Deployment.tpl)。

## 集合取值

```gotemplate
{{- $raw := include "base.get" (list . "selector" "" "" true) -}}
{{- $value := $raw | fromYaml -}}
{{- if or (eq (include "base.isFromYamlError" $value) "true") (not (kindIs "map" $value)) -}}
  {{- fail "[apps.deploymentSpec] selector: 必须为 map" -}}
{{- end -}}
```

list 使用 `fromYamlArray` 后，以 `base.isFromYamlArrayError` 和真实类型执行对应检查。

参考实现：[`templates/base/_get.tpl`](../../templates/base/_get.tpl)；迁移前资源实现：[`examples/tpls-bak/_DeploymentSpec.tpl`](../../examples/tpls-bak/_DeploymentSpec.tpl)。

## 隔离上下文

```gotemplate
{{- $ctx := mustDeepCopy . -}}
{{- $merged := mustMergeOverwrite (mustDeepCopy .Context.service) .Context -}}
{{- $ctx = mustMergeOverwrite $ctx (dict "Context" $merged) -}}
```

任何合并都以本次变更规格和目标模板的输入契约为前提，不得机械复制此片段。
