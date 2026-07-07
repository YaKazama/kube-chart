{{- /*
  安全渲染 YAML 键值对，处理引号、枚举及特殊类型。

  入参: list <key> <value> [渲染模板] [允许值列表枚举]
    key               键名，字符串，必填
    value             需要渲染的值，任意类型，必填
    渲染模板          用来处理 value 的命名模板名称，可选
                      - "base.string"：默认值，自动添加双引号/转义符
                      - "quote"：强制添加双引号
                      - "containers.env"：容器 env 变量专用，为 0/true/false/数值 自动添加双引号
                      - 其他模板名：调用对应模板处理
    允许值列表枚举    值校验列表，可选
                      - 匹配成功则保留，匹配失败则丢弃，都不匹配则报错
                      - 指定时，渲染模板强制使用 "base.string"

  返回值: 序列化后的 YAML 格式内容（key: value 形式）

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
  特定定义：专用于处理 containers.env 中的 value 引号问题。
  为 0/true/false/数值 等布尔值和数字自动添加双引号，保持字符串原样。

  入参: slice 容器环境变量列表
    每个元素为 dict，包含 name 和 value/valueFrom 字段

  返回值: toYamlPretty 格式化后的 YAML 字符串

  示例:
    {{- include "base.process.containers.env" .Values.env }}
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
        {{- $result = append $result (dict "name" $name "value" $value) }}
      {{- else }}
        {{- /* 非字符串类型：转为字符串并强制加引号 */}}
        {{- $strVal := print $value | quote }}
        {{- $result = append $result (dict "name" $name "value" $strVal) }}
      {{- end }}

    {{- else if hasKey . "valueFrom" }}
      {{- /* valueFrom 保持原样 */}}
      {{- $result = append $result . }}
    {{- else }}
      {{- fail (printf "[base.process.containers.env] environment variable '%s' missing value or valueFrom field" $name) }}
    {{- end }}
  {{- end }}

  {{- /* 返回 YAML 格式 */}}
  {{- toYamlPretty $result }}
{{- end }}
