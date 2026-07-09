{{- /*
  解析并校验 Kubernetes 资源名称。

  行为:
    - 接受单一上下文，或 list [context, mode]。
    - context 为字典时，按 fullname > name > 自动生成默认值的优先级解析；
      解析结果统一转小写、去除空白、去除尾部连字符。
    - context 为字符串时，按同样规则标准化后直接校验。
    - mode 选择校验规则:
        "name"       RFC1035 Label（默认），最多 63 字符
        "rbac"       允许大小写字母、数字、点、下划线、中划线、冒号，最多 253 字符
        "apiservice" DNS-1123 Subdomain 风格，允许数字开头/结尾，每段最多 63 字符，总长不超过 253
    - 未知 mode 立即失败。
    - 不符合规则时立即失败。

  入参:
    - context (map|string): 包含 fullname/name 的字典，或需要直接校验的字符串
    - mode    (string, 可选): "name" | "rbac" | "apiservice"

  返回值: 校验通过的标准化名称字符串；非法入参中断渲染。

  示例:
    {{- include "base.name" (dict "fullname" "My-App") }}                       // my-app
    {{- include "base.name" (list (dict "name" "role:admin") "rbac") }}          // role:admin
    {{- include "base.name" (list "v1beta1.metrics.k8s.io" "apiservice") }}      // v1beta1.metrics.k8s.io
    {{- include "base.name" (dict "name" "bad_name") }}                         // [base.name] 'bad_name' does not match RFC1035 (...)
*/ -}}
{{- define "base.name" -}}
  {{- /* 区分单一入参与 list [context, mode] */ -}}
  {{- $ctx := . }}
  {{- $mode := "name" }}
  {{- if kindIs "slice" . }}
    {{- $ctx = index . 0 }}
    {{- if ge (len .) 2 }}
      {{- $mode = index . 1 }}
    {{- end }}
  {{- end }}

  {{- /* mode 类型校验: 仅接受 string 类型, 其他类型立即失败 */ -}}
  {{- if ne (kindOf $mode) "string" }}
    {{- fail (printf "[base.name] parameter 1 (mode): expected string type, got '%v' (kind: %s)" $mode (kindOf $mode)) }}
  {{- end }}

  {{- /* 解析原始名称; name/apiservice 模式统一标准化 (小写 + 去空白 + 去尾连字符), rbac 模式仅去空白保留大小写 */ -}}
  {{- $name := "" }}
  {{- $ctxType := kindOf $ctx }}
  {{- if eq $ctxType "map" }}
    {{- $_fullname := include "base.get" (list $ctx "fullname" "toString") }}
    {{- $_name := include "base.get" (list $ctx "name" "toString") }}
    {{- $raw := coalesce $_fullname $_name (printf "helm4-name-%s" (randAlpha 8)) }}
    {{- if eq $mode "rbac" }}
      {{- $name = $raw | nospace }}
    {{- else }}
      {{- $name = $raw | lower | nospace | trimSuffix "-" }}
    {{- end }}
  {{- else if eq $ctxType "string" }}
    {{- if eq $mode "rbac" }}
      {{- $name = $ctx | nospace }}
    {{- else }}
      {{- $name = $ctx | lower | nospace | trimSuffix "-" }}
    {{- end }}
  {{- else }}
    {{- fail (printf "[base.name] unsupported context type, got '%v' (kind: %s)" $ctx $ctxType) }}
  {{- end }}

  {{- /* 加载 base.env 中的正则常量 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 根据 mode 选择校验规则与长度限制 */ -}}
  {{- $regex := "" }}
  {{- $modeLabel := "" }}
  {{- $maxLen := 0 }}
  {{- if eq $mode "name" }}
    {{- $regex = $const.RFC.RFC1035 }}
    {{- $modeLabel = "RFC1035" }}
    {{- $maxLen = 63 }}
  {{- else if eq $mode "rbac" }}
    {{- $regex = $const.RFC.RFC1035_RBAC }}
    {{- $modeLabel = "RFC1035_RBAC" }}
    {{- $maxLen = 253 }}
  {{- else if eq $mode "apiservice" }}
    {{- $regex = $const.RFC.APISERVICE }}
    {{- $modeLabel = "APISERVICE" }}
    {{- $maxLen = 253 }}
  {{- else }}
    {{- fail (printf "[base.name] unknown mode '%s', expected one of: name, rbac, apiservice" $mode) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- if not (mustRegexMatch $regex $name) }}
    {{- fail (printf "[base.name] '%s' does not match %s (%s)" $name $modeLabel $regex) }}
  {{- end }}

  {{- /* 长度校验: name 最多 63，rbac/apiservice 最多 253 */ -}}
  {{- if and (gt $maxLen 0) (gt (len $name) $maxLen) }}
    {{- fail (printf "[base.name] '%s' exceeds %d characters" $name $maxLen) }}
  {{- end }}

  {{- $name }}
{{- end }}


{{- /*
  解析并校验 Kubernetes namespace。

  行为:
    - 接受字符串或字典上下文。
    - 字符串时直接作为 namespace 值，标准化后（转小写、去空白、去尾连字符）校验。
    - 字典时按 namespace > "default" 优先级取值，标准化后校验。
    - 必须符合 RFC1123 DNS Label 规范（最多 63 字符）。
    - 不符合规则或类型非法时立即失败。

  入参:
    - context (map|string): 包含 namespace 的字典，或需要直接使用的字符串

  返回值: 校验通过的标准化 namespace 字符串；非法入参中断渲染。

  示例:
    {{- include "base.namespace" "My-NS" }}                    // my-ns
    {{- include "base.namespace" (dict "namespace" "Prod ") }} // prod
    {{- include "base.namespace" . }}                          // 从上下文取值
    {{- include "base.namespace" "bad_ns" }}                   // [base.namespace] namespace: 'bad_ns' does not match RFC1123 (...)
*/ -}}
{{- define "base.namespace" -}}
  {{- $namespace := "default" }}
  {{- $ctxType := kindOf . }}
  {{- if eq $ctxType "string" }}
    {{- $namespace = . | lower | nospace | trimSuffix "-" }}
  {{- else if eq $ctxType "map" }}
    {{- $_ns := include "base.get" (list . "namespace" "toString") | fromYaml }}
    {{- $namespace = coalesce $_ns "default" | lower | nospace | trimSuffix "-" }}
  {{- else }}
    {{- fail (printf "[base.namespace] context: expected map or string type, got '%v' (kind: %s)" . $ctxType) }}
  {{- end }}

  {{- /* 加载正则常量并校验 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (mustRegexMatch $const.RFC.RFC1123 $namespace) }}
    {{- fail (printf "[base.namespace] namespace: '%s' does not match RFC1123 (%s)" $namespace $const.RFC.RFC1123) }}
  {{- end }}

  {{- /* 长度校验: RFC1123 label 最多 63 字符 */ -}}
  {{- if gt (len $namespace) 63 }}
    {{- fail (printf "[base.namespace] namespace: '%s' exceeds 63 characters" $namespace) }}
  {{- end }}

  {{- $namespace }}
{{- end }}


{{- /*
  按 RFC 规则校验字符串。

  行为:
    - 接受字符串或 list [value, mode]。
    - 字符串时使用默认 mode = "1035" (RFC1035 Label)。
    - list 时按 mode 选择校验规则:
        "1035"  RFC1035 Label，最多 63 字符
        "1123"  RFC1123 Label (DNS Label)，最多 63 字符
        "rbac"  RBAC Subject 风格 (RFC1035_RBAC)，最多 253 字符
    - 未知 mode 或非字符串入参立即失败。
    - 不符合规则时立即失败。

  入参:
    - value (string): 待校验字符串
    - mode  (string, 可选): "1035" | "1123" | "rbac"，默认 "1035"

  返回值: 校验通过的字符串；非法入参中断渲染。

  示例:
    {{- include "base.rfc" "my-app" }}                                  // my-app
    {{- include "base.rfc" (list "v1beta1.metrics.k8s.io" "1123") }}    // v1beta1.metrics.k8s.io
    {{- include "base.rfc" (list "role:admin" "rbac") }}                // role:admin
    {{- include "base.rfc" "bad_name" }}                                // [base.rfc] value: 'bad_name' does not match RFC1035 (...)
*/ -}}
{{- define "base.rfc" -}}
  {{- $value := . }}
  {{- $mode := "1035" }}
  {{- if kindIs "slice" . }}
    {{- if eq (len .) 0 }}
      {{- fail "[base.rfc] parameter: empty list is not allowed" }}
    {{- end }}
    {{- $value = index . 0 }}
    {{- if ge (len .) 2 }}
      {{- $mode = index . 1 }}
    {{- end }}
  {{- end }}

  {{- /* 入参类型校验 */ -}}
  {{- if not (kindIs "string" $value) }}
    {{- fail (printf "[base.rfc] value: expected string type, got '%v' (kind: %s)" $value (kindOf $value)) }}
  {{- end }}
  {{- if not (kindIs "string" $mode) }}
    {{- fail (printf "[base.rfc] mode: expected string type, got '%v' (kind: %s)" $mode (kindOf $mode)) }}
  {{- end }}

  {{- /* 加载正则常量并按 mode 选择校验规则与长度限制 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $regex := "" }}
  {{- $modeLabel := "" }}
  {{- $maxLen := 0 }}
  {{- if eq $mode "1035" }}
    {{- $regex = $const.RFC.RFC1035 }}
    {{- $modeLabel = "RFC1035" }}
    {{- $maxLen = 63 }}
  {{- else if eq $mode "1123" }}
    {{- $regex = $const.RFC.RFC1123 }}
    {{- $modeLabel = "RFC1123" }}
    {{- $maxLen = 63 }}
  {{- else if eq $mode "rbac" }}
    {{- $regex = $const.RFC.RFC1035_RBAC }}
    {{- $modeLabel = "RFC1035_RBAC" }}
    {{- $maxLen = 253 }}
  {{- else }}
    {{- fail (printf "[base.rfc] mode: unknown mode '%s', expected one of: 1035, 1123, rbac" $mode) }}
  {{- end }}

  {{- /* 空字符串拦截 */ -}}
  {{- if eq $value "" }}
    {{- fail (printf "[base.rfc] value: empty string is not allowed for %s" $modeLabel) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- if not (mustRegexMatch $regex $value) }}
    {{- fail (printf "[base.rfc] value: '%s' does not match %s (%s)" $value $modeLabel $regex) }}
  {{- end }}

  {{- /* 长度校验 */ -}}
  {{- if gt (len $value) $maxLen }}
    {{- fail (printf "[base.rfc] value: '%s' exceeds %d characters" $value $maxLen) }}
  {{- end }}

  {{- $value }}
{{- end }}


{{- /*
  生成符合 RFC1035 的 chart 名称。

  行为:
    - 优先使用 .Chart.Name 和 .Chart.Version 拼接，格式为 "name-version"。
    - 将 "+" 替换为 "_"，截断至 63 字符，移除所有尾部连字符。
    - 若 .Chart 信息缺失，生成 "chart-" 前缀 + 8 位随机小写字母。

  入参:
    - . (context): Helm 模板上下文，需包含 .Chart.Name 和 .Chart.Version

  返回值: 符合 RFC1035 的 chart 名称字符串（最多 63 字符）

  示例:
    {{- include "base.chart" . }}  // my-app-1.0.0 或 chart-a1b2c3d4
*/ -}}
{{- define "base.chart" -}}
  {{- if and .Chart .Chart.Name .Chart.Version }}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "chart-%s" (randAlpha 8 | lower) }}
  {{- end }}
{{- end }}


{{- /*
  生成 Helm 标准标签（YAML 格式字符串，可通过 fromYaml 解析为字典）。参考 https://helm.sh/docs/chart_best_practices/labels/#standard-labels

  行为:
    - 输出 helm.sh/chart、app.kubernetes.io/version、app.kubernetes.io/managed-by 三个标准标签。
    - helm.sh/chart: 调用 base.chart 生成。
    - app.kubernetes.io/version: 优先使用 .Chart.AppVersion，缺失时用 "ver-<8位随机数字>" 兜底。
    - app.kubernetes.io/managed-by: 优先使用 .Release.Service，缺失时用 "Helm" 兜底。
    - 所有值均加双引号，确保 fromYaml 解析为字符串类型。

  入参:
    - . (context): Helm 模板上下文，应包含 .Chart 和 .Release

  返回值: YAML 格式的标签字符串，每行一个键值对

  示例:
    {{- include "base.helmLabels" . | fromYaml }}  // map[helm.sh/chart:my-app-1.0.0 ...]
*/ -}}
{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . | quote }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion | default (printf "ver-%s" (randNumeric 8)) | quote }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service | default "Helm4" | quote }}
{{- end }}


{{- /*
  统一处理 Kubernetes labels（YAML 格式字符串，可通过 fromYaml 解析为字典）。

  行为:
    - 支持三种模式，按优先级互斥:
      1. justNameLabel=true: 仅输出 name 标签（调用 base.name 生成）
      2. labels 存在: 合并用户自定义 labels，若 helmLabels=true 则追加标准标签
      3. 兜底: 若以上均不满足，强制输出 name 标签
    - 所有字典合并均使用 mustDeepCopy 隔离，严禁污染 .Values。

  入参:
    - context (map): 包含以下字段的字典:
      - justNameLabel (bool, 可选): 仅输出 name 标签
      - labels (map, 可选): 用户自定义标签
      - helmLabels (bool, 可选): 追加 Helm 标准标签

  返回值: toYamlPretty 格式化后的标签 YAML 字符串

  示例:
    {{- include "base.labels" (dict "justNameLabel" true) }}  // name: my-app
    {{- include "base.labels" (dict "labels" (dict "app" "test")) }}  // app: test
*/ -}}
{{- define "base.labels" -}}
  {{- $isHelmLabels := include "base.get" (list . "helmLabels") | fromYaml }}
  {{- $isJustNameLabel := include "base.get" (list . "justNameLabel") | fromYaml }}

  {{- $labels := dict }}
  {{- if $isJustNameLabel }}
    {{- $_ := set $labels "name" (include "base.name" .) }}
  {{- else }}
    {{- $customLabels := include "base.get" (list . "labels") | fromYaml }}
    {{- $labels = mustMerge $labels $customLabels }}
    {{- if $isHelmLabels }}
      {{- $helmLabels := include "base.helmLabels" . | fromYaml }}
      {{- $labels = mustMerge $labels $helmLabels }}
    {{- end }}
  {{- end }}

  {{- /* 保底：如果最终字典为空，强制写入 name */ -}}
  {{- if empty $labels }}
    {{- $_ := set $labels "name" (include "base.name" .) }}
  {{- end }}

  {{- /* 输出最终的 YAML 字符串 */ -}}
  {{- with $labels }}
    {{- toYamlPretty . }}
  {{- end }}
{{- end }}


{{- /*
  校验 Kubernetes Quantity 格式是否合法。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#quantity-resource-core

  行为:
    - 接受字符串或数字类型的入参。
    - 使用正则校验是否符合 Kubernetes Quantity 规范（支持 SI 后缀和二进制后缀）。
    - 合法时返回原值，非法时立即失败。

  入参:
    - value (string|int|float64): 待校验的 Quantity 值

  返回值: 校验通过的原始值（字符串或数字）；非法入参中断渲染。

  示例:
    {{- include "base.quantity" "100m" }}      // 100m
    {{- include "base.quantity" "1Gi" }}       // 1Gi
    {{- include "base.quantity" 500 }}         // 500
    {{- include "base.quantity" "invalid" }}   // [base.quantity] value: 'invalid' does not match K8S Quantity (...)
*/ -}}
{{- define "base.quantity" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- if mustRegexMatch $const.K8S.QUANTITY (toString .) }}
    {{- . }}
  {{- else }}
    {{- fail (printf "[base.quantity] value: '%v' does not match K8S Quantity (%s)" . $const.K8S.QUANTITY) }}
  {{- end }}
{{- end }}


{{- /*
  校验并转换 Kubernetes Time 格式。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#time-v1-meta

  行为:
    - 数字类型（int/int64/float64）：视为秒数，通过 duration 转换为 Go duration 字符串。
    - 字符串类型：
      - 匹配 TYPES.INT 正则：视为秒数字符串，转换后通过 duration 输出。
      - 匹配 K8S.TIME 正则：直接返回原值（如 "300ms"、"1h30m"）。
      - 均不匹配：立即失败。
    - 其他类型：立即失败。

  入参:
    - value (int|int64|float64|string): 待校验的时间值

  返回值: Go duration 格式的字符串（如 "5m0s"）或原始时间字符串；非法入参中断渲染。

  示例:
    {{- include "base.time" 300 }}         // 5m0s
    {{- include "base.time" "1h30m" }}     // 1h30m
    {{- include "base.time" "500ms" }}     // 500ms
    {{- include "base.time" "invalid" }}   // [base.time] value: 'invalid' does not match Time (...)
*/ -}}
{{- define "base.time" -}}
  {{- $type := kindOf . }}
  {{- if or (eq $type "int") (eq $type "int64") (eq $type "float64") }}
    {{- duration (int .) }}
  {{- else if eq $type "string" }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- if mustRegexMatch $const.TYPES.INT . }}
      {{- duration (atoi .) }}
    {{- else if mustRegexMatch $const.K8S.TIME . }}
      {{- . }}
    {{- else }}
      {{- fail (printf "[base.time] value: '%s' does not match K8S Time (%s)" . $const.K8S.TIME) }}
    {{- end }}
  {{- else }}
    {{- fail (printf "[base.time] value: expected number or string type, got '%v' (kind: %s)" . $type) }}
  {{- end }}
{{- end }}


{{- /*
  校验 Kubernetes FieldsV1 格式是否合法。参考 https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#fieldsv1-v1-meta

  行为:
    - 接受字符串类型的入参。
    - 使用正则校验是否符合 Kubernetes FieldsV1 规范（字段管理器标识符）。
    - 合法格式包括：`.`（根）、`f:fieldName`（字段）、`i:index`（索引）、`v:value`（值）、`k:key`（键）。
    - 合法时返回原值，非法时立即失败。

  入参:
    - value (string): 待校验的 FieldsV1 字符串

  返回值: 校验通过的原始字符串；非法入参中断渲染。

  示例:
    {{- include "base.fieldsV1" "." }}           // .
    {{- include "base.fieldsV1" "f:metadata" }}  // f:metadata
    {{- include "base.fieldsV1" "i:0" }}         // i:0
    {{- include "base.fieldsV1" "invalid" }}     // [base.fieldsV1] value: 'invalid' does not match FieldsV1 (...)
*/ -}}
{{- define "base.fieldsV1" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- if mustRegexMatch $const.K8S.FIELDS_V1 (toString .) }}
    {{- . }}
  {{- else }}
    {{- fail (printf "[base.fieldsV1] value: '%v' does not match K8S FieldsV1 (%s)" . $const.K8S.FIELDS_V1) }}
  {{- end }}
{{- end }}


{{- /*
  校验 RollingUpdate 配置值是否合法。

  行为:
    - 数字类型（int/int64/float64）：直接转换为 int 返回（表示副本数）。
    - 字符串类型：
      - 匹配 TYPES.PERCENT 正则（如 "25%"、"100%"）：直接返回原值。
      - 不匹配：立即失败。
    - 其他类型：立即失败。

  入参:
    - value (int|int64|float64|string): 待校验的 RollingUpdate 值

  返回值: int 类型（数字输入）或百分比字符串（如 "25%"）；非法入参中断渲染。

  示例:
    {{- include "base.rollingUpdate" 3 }}      // 3
    {{- include "base.rollingUpdate" "25%" }}  // 25%
    {{- include "base.rollingUpdate" "abc" }}  // [base.rollingUpdate] value: 'abc' does not match Percent (...)
*/ -}}
{{- define "base.rollingUpdate" -}}
  {{- $type := kindOf . }}
  {{- if or (eq $type "int") (eq $type "int64") (eq $type "float64") }}
    {{- int . }}
  {{- else if eq $type "string" }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- if mustRegexMatch $const.TYPES.PERCENT . }}
      {{- . }}
    {{- else }}
      {{- fail (printf "[base.rollingUpdate] value: '%s' does not match Percent (%s)" . $const.TYPES.PERCENT) }}
    {{- end }}
  {{- else }}
    {{- fail (printf "[base.rollingUpdate] value: expected number or string type, got '%v' (kind: %s)" . $type) }}
  {{- end }}
{{- end }}
