{{- /*
  渲染 Kubernetes RollingUpdateDeployment 配置。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#rollingupdatedeployment-v1-apps

  行为（按 K8s API 规范字段顺序）:
    - maxSurge（整数或百分比字符串，可选）：有值时直接渲染；空值时跳过；0 必须保留。
    - maxUnavailable（整数或百分比字符串，可选）：有值时直接渲染；空值时跳过；0 必须保留。
    - maxSurge 与 maxUnavailable 可同时为空；不能同时为 0 或 0%。
    - 不在本模板中执行正则校验；由调用方完成多类型输入的归一化。

  入参: dict，由 apps.deploymentStrategy 传递。
    - maxSurge       整数或百分比字符串，可选。
    - maxUnavailable 整数或百分比字符串，可选。

  返回值: RollingUpdateDeployment YAML 键值对（不含 rollingUpdate 父键）。

  示例:
    {{- include "apps.rollingUpdateDeployment" (dict "maxSurge" "25%" "maxUnavailable" 0) }}
*/ -}}
{{- define "apps.rollingUpdateDeployment" -}}
  {{- /* Step 1: 校验已由父模板归一化后的 dict 入参 */ -}}
  {{- if not (kindIs "map" .) }}
    {{- fail (printf "[apps.rollingUpdateDeployment] input: must be map type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- /* Step 2: 统一通过 base.get 读取可选字段，保留 0 等零值 */ -}}
  {{- $_maxSurge := include "base.get" (list . "maxSurge") }}
  {{- $_maxUnavailable := include "base.get" (list . "maxUnavailable") }}
  {{- $maxSurge := "" }}
  {{- $maxUnavailable := "" }}

  {{- /* Step 3: 排除未设置的空值与 nil，不对非空值做正则校验 */ -}}
  {{- if and $_maxSurge (ne $_maxSurge "null") }}
    {{- $maxSurge = include "base.string" $_maxSurge }}
  {{- end }}

  {{- if and $_maxUnavailable (ne $_maxUnavailable "null") }}
    {{- $maxUnavailable = include "base.string" $_maxUnavailable }}
  {{- end }}

  {{- /* Step 4: Kubernetes 约束：两个字段不能同时为语义零值 */ -}}
  {{- if and
        (or (eq $maxSurge "0") (eq $maxSurge "0%"))
        (or (eq $maxUnavailable "0") (eq $maxUnavailable "0%")) }}
    {{- fail "[apps.rollingUpdateDeployment] maxSurge/maxUnavailable: cannot both be zero" }}
  {{- end }}

  {{- /* Step 5: 按 API 字段顺序安全渲染，仅输出实际设置的字段 */ -}}
  {{- if $maxSurge }}
    {{- include "base.field" (list "maxSurge" $maxSurge "base.string") }}
  {{- end }}

  {{- if $maxUnavailable }}
    {{- include "base.field" (list "maxUnavailable" $maxUnavailable "base.string") }}
  {{- end }}
{{- end -}}
