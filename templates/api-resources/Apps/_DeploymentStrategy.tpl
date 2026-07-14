{{- /*
  渲染 Kubernetes DeploymentStrategy 资源。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#deploymentstrategy-v1-apps

  行为 (按 K8s API 规范字段顺序):
    - rollingUpdate (object, 可选): 仅在 DeploymentStrategyType = RollingUpdate 时渲染, 委托 apps.rollingUpdateDeployment 渲染。
    - type (string, 可选): default "RollingUpdate", 枚举校验 "Recreate" / "RollingUpdate"。

  核心字段: 上下文 dict, 可包含以下字段:
    - rollingUpdate   (object, 可选)   RollingUpdateDeployment 结构, 包括 maxSurge / maxUnavailable 字段
    - type            (string, 可选)   部署策略类型, default "RollingUpdate", 取值 "Recreate" / "RollingUpdate"

  返回值: DeploymentStrategy 资源 YAML 键值对 (不含 strategy 父键), 由调用方包入 strategy 块

  示例:
    {{- include "apps.deploymentStrategy" . }}
*/ -}}
{{- define "apps.deploymentStrategy" -}}
  {{- /* Step 1: 计算 type (string, 可选): default "RollingUpdate", 用于条件判断 rollingUpdate 是否渲染
       缺省或 nil 时填充默认值; 必填校验与枚举校验放在 Step 3 渲染时统一完成
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接比较 base.get 输出字符串 */ -}}
  {{- $_type := include "base.get" (list . "type") }}
  {{- $type := "RollingUpdate" }}
  {{- if and $_type (ne $_type "null") }}
    {{- $type = $_type }}
  {{- end }}

  {{- /*
    Step 2: rollingUpdate (object, 可选): 按 K8s API 顺序先渲染
    - 仅在 type = RollingUpdate 时渲染 (Recreate 类型时直接跳过)
    - 委托 apps.rollingUpdateDeployment 渲染
    - 上下文 dict 透传 (含 maxSurge / maxUnavailable 字段)
    - 必填项缺失或非 map 类型时立即中断并报错
    - 兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测
  */ -}}
  {{- if eq $type "RollingUpdate" }}
    {{- $_rollingUpdate := include "base.get" (list . "rollingUpdate") }}
    {{- if and $_rollingUpdate (ne $_rollingUpdate "null") }}
      {{- $rollingUpdateVal := $_rollingUpdate | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $rollingUpdateVal) "true" }}
        {{- fail "[apps.deploymentStrategy] rollingUpdate: must be map type" }}
      {{- end }}
      {{- if not (kindIs "map" $rollingUpdateVal) }}
        {{- fail "[apps.deploymentStrategy] rollingUpdate: must be map type" }}
      {{- end }}

      {{- $rollingUpdate := include "apps.rollingUpdateDeployment" $rollingUpdateVal | fromYaml }}
      {{- if $rollingUpdate }}
        {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Step 3: type (string, 可选): 按 K8s API 顺序后渲染
       枚举校验: 允许值 "Recreate" / "RollingUpdate", 缺省时使用 "RollingUpdate" */ -}}
  {{- $typeAllows := list "Recreate" "RollingUpdate" }}
  {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
{{- end -}}
