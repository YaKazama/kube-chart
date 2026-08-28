{{- /*
  渲染 YAML 键值对，统一处理引号、枚举校验与多种类型输出。

  行为:
    - 入参必须为长度为 2-4 的 slice，否则快速失败
    - 解析 key(必填字符串,非空) / rawValue(任意类型) / define(渲染模板名,可选) / allows(枚举列表,可选)
    - define 关键字 "quote" 转为强制加引号; "containers.env" 转为容器 env 专用处理
    - 指定 allows 时强制使用 base.string 作为渲染模板, 渲染前先做枚举校验
    - 渲染后仅当 val 非空时输出; 单行引号 / 多行块标量 / 复杂类型按需切换输出格式

  入参: list [键名, 原始值, 渲染模板, 允许值列表]；前两项必填，后两项可选。

  边界:
    - 只处理单个键值对，不负责上层字段的取值、默认值或跨字段校验。
    - 渲染模板可使用 base.string、quote、containers.env 或其他已定义的命名模板。

  返回值: 序列化后的 YAML 键值对 (key: value 形式, 复杂类型换行缩进, 多行字符串使用 |- 块标量)

  示例:
    {{- include "base.field" (list "replicas" $replicas "base.int") }}
    {{- include "base.field" (list "tag" $tag "quote") }}
    {{- $allows := list "Always" "IfNotPresent" }}
    {{- include "base.field" (list "pullPolicy" $policy "base.string" $allows) }}
*/ -}}
{{- define "base.field" -}}
  {{- /* Step 1: 参数校验 */}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.field] parameter must be slice type" }}
  {{- end }}
  {{- $sliceLen := len . }}
  {{- if or (lt $sliceLen 2) (gt $sliceLen 4) }}
    {{- fail (printf "[base.field] invalid parameter count: expected 2-4, got '%d'" $sliceLen) }}
  {{- end }}

  {{- /* Step 2: 解析参数 */}}
  {{- $key := index . 0 }}
  {{- if not (kindIs "string" $key) }}
    {{- fail "[base.field] 'key' must be string type" }}
  {{- end }}
  {{- if eq $key "" }}
    {{- fail "[base.field] 'key' cannot be empty" }}
  {{- end }}

  {{- $rawValue := index . 1 }}
  {{- $define := "base.string" }}
  {{- $allows := list }}

  {{- if ge $sliceLen 3 }}
    {{- $define = index . 2 }}
  {{- end }}
  {{- if ge $sliceLen 4 }}
    {{- $allows = index . 3 }}
  {{- end }}

  {{- /* Step 3: 处理特殊渲染模板 */}}
  {{- $isQuote := false }}
  {{- if eq $define "quote" }}
    {{- $isQuote = true }}
    {{- $define = "base.string" }}
  {{- else if eq $define "containers.env" }}
    {{- $define = "base.process.containers.env" }}
  {{- end }}

  {{- /* 有枚举列表时，强制使用 base.string */}}
  {{- if $allows }}
    {{- $define = "base.string" }}
  {{- end }}

  {{- /* Step 4: 枚举校验（在渲染前进行，避免类型不匹配） */}}
  {{- if $allows }}
    {{- $strValue := toString $rawValue }}
    {{- $matched := false }}
    {{- range $allows }}
      {{- if eq (toString .) $strValue }}
        {{- $matched = true }}
      {{- end }}
    {{- end }}
    {{- if not $matched }}
      {{- fail (printf "[base.field] %s: value '%v' not in allowed list '%v'" $key $rawValue $allows) }}
    {{- end }}
  {{- end }}

  {{- /* Step 5: 调用渲染模板处理值 */}}
  {{- $val := include $define $rawValue }}

  {{- /* Step 6: 判断是否输出 */}}
  {{- if ne $val "" }}
    {{- /* Step 7: 处理引号（仅对单行字符串） */}}
    {{- $isMultiLine := or (contains "\n" $val) (contains "\r\n" $val) }}
    {{- $finalVal := $val }}
    {{- if and $isQuote (not $isMultiLine) }}
      {{- $finalVal = $val | quote }}
    {{- end }}

    {{- /* Step 8: 判断值类型以决定输出格式 */}}
    {{- $isMap := kindIs "map" $rawValue }}
    {{- $isSlice := kindIs "slice" $rawValue }}
    {{- $isEnv := eq $define "base.process.containers.env" }}

    {{- /* Step 9: 输出 YAML */}}
    {{- if or $isMap $isSlice $isEnv }}
      {{- /* 复杂类型：换行缩进 */}}
      {{- nindent 0 "" -}}{{ $key }}:
        {{- $finalVal | nindent 2 }}
    {{- else if $isMultiLine }}
      {{- /* 多行字符串：使用 |- 块标量标识 */}}
      {{- nindent 0 "" -}}{{ $key }}: |-
        {{- $finalVal | nindent 2 }}
    {{- else }}
      {{- /* 单行/非字符串：直接输出 */}}
      {{- nindent 0 "" -}}{{ $key }}: {{ $finalVal }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  处理 containers.env 中的 value 引号问题，由 base.field 路由调用。

  行为:
    - 入参必须为 slice, 否则快速失败
    - 遍历每个元素, 必须为 dict, 必须包含 name 字段
    - 字符串类型 value 保持原样; 非字符串类型 value 转为字符串并强制加引号, 防止 YAML 解析错误
    - valueFrom 字段保持原样; 同时缺少 value 和 valueFrom 时快速失败
    - value 与 valueFrom 互斥, 优先处理 value

  入参: EnvVar Map 组成的 slice；每项必须包含 name 与 value 或 valueFrom。

  边界:
    - 只处理 EnvVar 列表，不校验 valueFrom 的内部结构。
    - 仅由 base.field 的 containers.env 路由调用。

  返回值: toYamlPretty 格式化后的环境变量 YAML 列表

  示例:
    {{- include "base.field" (list "env" $envList "containers.env") }}
*/ -}}
{{- define "base.process.containers.env" -}}
  {{- /* 参数校验 */}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.process.containers.env] parameter must be slice type" }}
  {{- end }}

  {{- $result := list }}

  {{- range . }}
    {{- if not (kindIs "map" .) }}
      {{- fail "[base.process.containers.env] each environment variable must be map type" }}
    {{- end }}

    {{- $name := get . "name" }}
    {{- if not $name }}
      {{- fail "[base.process.containers.env] environment variable missing name field" }}
    {{- end }}

    {{- /* 处理 value 和 valueFrom 互斥 */}}
    {{- if hasKey . "value" }}
      {{- $value := get . "value" }}

      {{- /* 字符串类型保持原样，其他类型必须加引号防止 YAML 解析错误 */}}
      {{- if kindIs "string" $value }}
        {{- $result = mustAppend $result (dict "name" $name "value" $value) }}
      {{- else }}
        {{- /* 非字符串类型：转为字符串并强制加引号 */}}
        {{- $strVal := print $value | quote }}
        {{- $result = mustAppend $result (dict "name" $name "value" $strVal) }}
      {{- end }}

    {{- else if hasKey . "valueFrom" }}
      {{- /* valueFrom 保持原样 */}}
      {{- $result = mustAppend $result . }}
    {{- else }}
      {{- fail (printf "[base.process.containers.env] environment variable '%s' missing value or valueFrom field" $name) }}
    {{- end }}
  {{- end }}

  {{- /* 返回 YAML 格式 */}}
  {{- toYamlPretty $result }}
{{- end }}
