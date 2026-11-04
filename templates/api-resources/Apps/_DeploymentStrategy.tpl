{{- /*
  渲染 Kubernetes DeploymentStrategy 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - rollingUpdate (RollingUpdateDeployment, 可选): type 不为 Recreate 且入参非空时委托 apps.rollingUpdateDeployment 渲染；子模板返回空时不输出该字段。
    - type (string, 可选): 入参为空时不输出该字段，由 Kubernetes API 采用 RollingUpdate；非空时按 Recreate、RollingUpdate 枚举校验，超出范围中断。

  边界:
    - 入参是父级已清洗的策略 map，本模板不解析字符串简写，不为 *Alias 增加专有处理，不校验入参形态与 rollingUpdate 内部结构。
    - type 为空时仅按隐式默认值 RollingUpdate 决定 rollingUpdate 是否渲染，不输出任何替代取值。
    - type 为 Recreate 时不读取 rollingUpdate，入参内容与类型均不判定。
    - 子模板返回的无效 YAML 由本模板中断；非 map 由 base.map 中断。
    - 不输出 status 或其他字段。

  入参: 上下文 map，可包含以下字段:
    - rollingUpdate (RollingUpdateDeployment, 可选) 滚动更新参数
    - type          (string, 可选)                  部署策略类型

  返回值: 可嵌入 spec.strategy 下的 DeploymentStrategy YAML 字段片段。

  示例:
    {{- include "apps.deploymentStrategy" (dict "type" "Recreate") }}
*/ -}}
{{- define "apps.deploymentStrategy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* type（string, 可选）: 剥离 YAML 标量引号后归并缺失、null 与空字符串，供字段生效条件与枚举校验使用。 */ -}}
  {{- $type := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "type") | trim) "$1" | trim }}
  {{- if eq $type "null" }}
    {{- $type = "" }}
  {{- end }}

  {{- /* rollingUpdate（RollingUpdateDeployment, 可选）: type 不为 Recreate 且入参非空时原样委托 apps.rollingUpdateDeployment，子模板返回空时不输出。 */ -}}
  {{- if ne $type "Recreate" }}
    {{- $rollingUpdate := include "base.get" (list . "rollingUpdate") | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $rollingUpdate) "true" }}
      {{- $rollingUpdate = dict }}
    {{- end }}

    {{- if $rollingUpdate }}
      {{- $_rollingUpdateRendered := include "apps.rollingUpdateDeployment" $rollingUpdate | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rollingUpdateRendered) "true" }}
        {{- fail "[apps.deploymentStrategy] rollingUpdate: apps.rollingUpdateDeployment returned invalid YAML" }}
      {{- end }}
      {{- if $_rollingUpdateRendered }}
        {{- include "base.field" (list "rollingUpdate" $_rollingUpdateRendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* type（string, 可选）: 为空时不输出该字段，非空时按 Recreate、RollingUpdate 枚举校验后渲染。 */ -}}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "" (list "Recreate" "RollingUpdate")) }}
  {{- end }}
{{- end }}
