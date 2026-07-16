{{- /*
  渲染 Kubernetes DeploymentStrategy 资源。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentstrategy-v1-apps

  行为 (按 K8s API 规范字段顺序):
    - rollingUpdate (object/map/string, 可选): 仅在 type == "RollingUpdate" 且显式提供时渲染
      - 接收 object/map: 原样作为 dict 透传给 apps.rollingUpdateDeployment
      - 接收 string: 格式 "maxSurge maxUnavailable" (空格分隔), 通过正则 ^(\d+\%?)?(?:\s+(\d+\%?))?$ 解析为
        含 maxSurge / maxUnavailable 字段的 dict, 再委托给 apps.rollingUpdateDeployment
    - type (string, 可选): 始终渲染, 缺省时使用默认值 "RollingUpdate"

  核心字段: 上下文 dict, 由 apps.deploymentSpec 规整后透传, 可包含以下字段:
    - rollingUpdate  (object/map/string, 可选)   RollingUpdateDeployment 结构或 "maxSurge maxUnavailable" 字符串
    - type           (string, 可选)               Recreate / RollingUpdate, 缺省时填充为 "RollingUpdate"

  返回值: DeploymentStrategy 资源 YAML 键值对 (不含 strategy 父键), 由调用方包入 strategy 块

  示例:
    {{- include "apps.deploymentStrategy" . }}
*/ -}}
{{- define "apps.deploymentStrategy" -}}
  {{- /*
    Step 1: 计算 type (string, 可选)
    - 缺省或 nil 时填充默认值 "RollingUpdate"
    - 必填校验与枚举校验不放在本步, 统一延迟到 Step 3 渲染时由 base.field 配合 base.string + allows 完成
    - 顶层声明 $strategyType 避免 if 分支内的变量作用域限制
  */ -}}
  {{- $_typeRaw := include "base.get" (list . "type") }}
  {{- $strategyType := "RollingUpdate" }}
  {{- if and $_typeRaw (ne $_typeRaw "null") (ne $_typeRaw "") }}
    {{- $strategyType = $_typeRaw }}
  {{- end }}

  {{- /*
    Step 2: rollingUpdate (object/map/string, 可选)
    - 严格遵循 K8s 规范"仅在 DeploymentStrategyType = RollingUpdate 时才渲染"
    - Recreate 类型时即使上游传入了 rollingUpdate 也会被静默跳过
    - 入口通过 base.get 取值, 兼容三种"无值"情形 ("" / "null" / "{}") 并跳过渲染
    - 类型归一化 (string -> dict) 在本层完成, 委托 apps.rollingUpdateDeployment 时统一传 dict
    - 兼容 Helm 4.2.2 fromYaml 对 string 输入返回错误 map 的 BUG, 通过 base.isFromYamlError 检测
  */ -}}
  {{- if eq $strategyType "RollingUpdate" }}
    {{- $_rollingUpdateRaw := include "base.get" (list . "rollingUpdate") }}
    {{- if and $_rollingUpdateRaw (ne $_rollingUpdateRaw "null") (ne $_rollingUpdateRaw "{}") }}
      {{- $parsed := $_rollingUpdateRaw | fromYaml }}
      {{- $isErr := eq (include "base.isFromYamlError" $parsed) "true" }}
      {{- $isMap := and (kindIs "map" $parsed) (not $isErr) }}
      {{- $const := include "base.env" "" | fromYaml }}
      {{- $ruPattern := $const.APPS.DEPLOYMENT.ROLLING_UPDATE }}
      {{- $unquotePattern := $const.SYS.YAML_QUOTED }}
      {{- /* base.get 对含前后空白的字符串会包单引号 (YAML 转义), 先剥离单引号再 trim 内部残留空白 */ -}}
      {{- $rUnquoted := mustRegexReplaceAll $unquotePattern $_rollingUpdateRaw "$1" | trim }}
      {{- $isRuString := and $isErr (mustRegexMatch $ruPattern $rUnquoted) }}

      {{- /* case 1: 解析为 map (object/map 输入) -> 原样委托 */ -}}
      {{- if $isMap }}
        {{- $rollingUpdate := include "apps.rollingUpdateDeployment" $parsed | fromYaml }}
        {{- if $rollingUpdate }}
          {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
        {{- end }}

      {{- /* case 2: fromYaml 错误但原始字符串匹配 rollingUpdate 正则 (string 输入) -> 正则解析为 dict */ -}}
      {{- else if $isRuString }}
        {{- $maxSurge := mustRegexReplaceAll $ruPattern $rUnquoted "${1}" | trim }}
        {{- $maxUnavailable := mustRegexReplaceAll $ruPattern $rUnquoted "${2}" | trim }}
        {{- $ruDict := dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable }}
        {{- $rollingUpdate := include "apps.rollingUpdateDeployment" $ruDict | fromYaml }}
        {{- if $rollingUpdate }}
          {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
        {{- end }}

      {{- /* case 3: 其他类型 (slice / int / bool 等) -> 非法, 立即 fail */ -}}
      {{- else }}
        {{- fail (printf "[apps.deploymentStrategy] rollingUpdate: must be map or string type, got '%s' (kind: %s)" $rUnquoted (kindOf $parsed)) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /*
    Step 3: type (string, 可选)
    - 通过 base.field 调用 base.string 模板 + allows 列表完成渲染与枚举校验
    - 渲染前自动执行枚举校验: 值不在允许列表中时立即 fail
    - 始终渲染, 缺省时由 Step 1 填充为 "RollingUpdate"
  */ -}}
  {{- $typeAllows := list "Recreate" "RollingUpdate" }}
  {{- include "base.field" (list "type" $strategyType "base.string" $typeAllows) }}
{{- end -}}
