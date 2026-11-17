{{- /*
  渲染 Kubernetes EnvVar 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 必填): 必填取值并按 YAML 标量语义解码后以带引号标量输出，缺失或为空时中断。
    - value (string, 可选): 与 valueFrom 互斥；非 string 标量强制转为字符串后以带引号标量输出，对象与数组中断。
    - valueFrom (EnvVarSource, 可选): 原生 map 原样透传；字符串按关键字映射为单键 map；两种来源统一委托 definitions.envVarSource 渲染。

  边界:
    - 只输出 name、value 与 valueFrom，不包含父级键；env 数组的循环、条目合并与去重由调用方负责。
    - 除 name、value、valueFrom 以外的入参字段静默忽略。
    - value 只接受标量；string 与非 string 标量一律输出为双引号字符串，对象与数组按类型中断。
    - valueFrom 字符串只切分关键字与剩余原文两段，第二层字段拆分、校验与缺省由 definitions.envVarSource 负责。
    - 关键字不匹配或不足两段时跳过 valueFrom，仅输出 name，不中断渲染。
    - 两种来源的委托结果为空时不输出 valueFrom 字段。
    - definitions.envVarSource 当前未实现，其可用性由后续变更提供。

  入参: 上下文 map，可包含以下字段:
    - name      (string, 必填)       环境变量名
    - value     (string, 可选)       字面值；非 string 标量按字符串输出
    - valueFrom (EnvVarSource, 可选) 字段来源

  返回值: 可嵌入 env 数组项的 YAML 字段片段；value 与 valueFrom 均未提供时只输出 name。

  示例:
    {{- include "definitions.envVar" (dict "name" "FOO" "value" "bar") }}
    {{- include "definitions.envVar" (dict "name" "FOO" "valueFrom" "cm app-config LOG_LEVEL") }}
*/ -}}
{{- define "definitions.envVar" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* value 与 valueFrom（关联字段）: 先取原始输出，空输出统一视为未提供；value 以 toString 强制标量转字符串；两者同时非空时中断。 */ -}}
  {{- $_valueRaw := include "base.get" (list . "value" "toString") | trim }}
  {{- $_valueFromRaw := include "base.get" (list . "valueFrom") | trim }}
  {{- if and $_valueRaw $_valueFromRaw }}
    {{- fail "[definitions.envVar] valueFrom: mutually exclusive with 'value'" }}
  {{- end }}

  {{- /* name（string, 必填）: 必填取值并按 YAML 标量语义解码后以带引号标量输出，避免数字或布尔外观的名称改变 YAML 类型。 */ -}}
  {{- $_name := include "base.string.normalize" (include "base.get" (list . "name" "" "" true)) | trim }}
  {{- if not $_name }}
    {{- fail "[definitions.envVar] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" $_name "quote") }}

  {{- /* value（string, 可选）: 对象与数组按类型中断；标量按 YAML 标量语义解码后以带引号标量输出。 */ -}}
  {{- if $_valueRaw }}
    {{- $_isArray := ne (include "base.isFromYamlArrayError" (fromYamlArray $_valueRaw)) "true" }}
    {{- if or (ne (include "base.isFromYamlError" (fromYaml $_valueRaw)) "true") $_isArray }}
      {{- fail (printf "[definitions.envVar] value: must be scalar, got '%s'" (ternary "array" "object" $_isArray)) }}
    {{- end }}
    {{- include "base.field" (list "value" (include "base.string.normalize" $_valueRaw | trim) "quote") }}
  {{- end }}

  {{- /* valueFrom（EnvVarSource, 可选）: 原生 map 原样透传；字符串剥离 YAML 引号后按关键字映射为单键 map。 */ -}}
  {{- if $_valueFromRaw }}
    {{- $_valueFromCtx := dict }}
    {{- $_hasValueFrom := false }}
    {{- $_valueFromParsed := fromYaml $_valueFromRaw }}

    {{- /* fromYaml 报错说明输入是标量字符串，否则已保证结果是 map。 */ -}}
    {{- if eq (include "base.isFromYamlError" $_valueFromParsed) "true" }}
      {{- $_parts := mustRegexSplit $const.SPLIT.SPACE_COMMA (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_valueFromRaw "$1" | trim) 2 }}

      {{- if ge (len $_parts) 2 }}
        {{- $_keywords := dict "cm" "configMapKeyRef" "configmap" "configMapKeyRef" "field" "fieldRef" "file" "fileKeyRef" "resource" "resourceFieldRef" "secret" "secretKeyRef" }}
        {{- $_fieldName := get $_keywords (lower (index $_parts 0)) }}
        {{- if $_fieldName }}
          {{- $_valueFromCtx = dict $_fieldName (trim (index $_parts 1)) }}
          {{- $_hasValueFrom = true }}
        {{- end }}
      {{- end }}

    {{- else }}
      {{- $_valueFromCtx = $_valueFromParsed }}
      {{- $_hasValueFrom = true }}
    {{- end }}

    {{- /* 委托 definitions.envVarSource: 结果非法 YAML 时中断，非空时以 map 输出。 */ -}}
    {{- if $_hasValueFrom }}
      {{- $_rendered := include "definitions.envVarSource" $_valueFromCtx | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.envVar] valueFrom: invalid YAML output from definitions.envVarSource" }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list "valueFrom" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
