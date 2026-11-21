{{- /*
  渲染 Kubernetes Capabilities 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - add (string array, 可选): 恢复数组后按分号、逗号或空白拆分，校验名称并统一大写后输出。
    - drop (string array, 可选): 与 add 同构处理。

  边界:
    - 只输出 add 与 drop，不输出父级 capabilities 键；无有效内容时输出空内容。
    - 缺失、null、空字符串或空数组视为未提供。
    - 非数组输入、非 string 元素与非法名称中断渲染。
    - 名称只校验字符形态，不校验是否为已知 Linux capability；CAP_ 前缀可选且大小写不敏感。
    - 清洗委托 base.slice.cleanup，其失败消息使用该能力自身前缀；本模板的失败消息使用 [definitions.capabilities] 前缀并携带字段名。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效；除 add、drop 及其同级别名以外的入参字段静默忽略。

  入参: 上下文 map，可包含以下字段:
    - add  (string array, 可选) 要添加的 capability 列表
    - drop (string array, 可选) 要移除的 capability 列表

  返回值: 可嵌入 securityContext 下 capabilities 的 YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.capabilities" (dict "add" (list "NET_ADMIN") "drop" (list "SYS_TIME")) }}
*/ -}}
{{- define "definitions.capabilities" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- range $key := list "add" "drop" }}
    {{- /* add/drop（string array, 可选）: 恢复数组并按 string 数组契约拒绝标量、map 与非 string 元素。 */ -}}
    {{- $__items := include "base.get" (list $ $key) | fromYamlArray }}
    {{- if or (eq (include "base.isFromYamlArrayError" $__items) "true") (and (eq (len $__items) 1) (hasSuffix "go value of type []interface {}" (lower (first $__items | toString)))) }}
      {{- fail (printf "[definitions.capabilities] %s: must be array type" $key) }}
    {{- end }}
    {{- range $_item := $__items }}
      {{- if not (kindIs "string" $_item) }}
        {{- fail (printf "[definitions.capabilities] %s: element must be string type, got '%s'" $key (kindOf $_item)) }}
      {{- end }}
    {{- end }}

    {{- /* add/drop（string array, 可选）: 拆分、空项移除与去重委托 base.slice.cleanup；名称正则校验与大写归一在本层完成。 */ -}}
    {{- $caps := list }}
    {{- range $_cap := include "base.slice.cleanup" (list $__items $const.SPLIT.SPACE_COMMA_SEMICOLON) | fromYamlArray }}
      {{- if not (mustRegexMatch $const.K8S.CAPABILITY_NAME (toString $_cap)) }}
        {{- fail (printf "[definitions.capabilities] %s: '%v' is not a valid capability name" $key $_cap) }}
      {{- end }}
      {{- $caps = mustAppend $caps (upper (toString $_cap)) }}
    {{- end }}
    {{- $caps = mustUniq $caps }}

    {{- if $caps }}
      {{- include "base.field" (list $key $caps "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}
