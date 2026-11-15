{{- /*
  从 Chart 内文件按字段路径读取内容并按顺序合并。

  行为:
    - fileRefs 入参可为 array 或 map；array 逐元素独立处理，map 视为单元素数组，两者结果等价。
    - filePath 必填，经 base.path 的 rel 模式归一化后读取 Files；绝对路径、空路径与 Chart 根目录逃逸路径中断。
    - filePath 指向的文件必须存在且非空，内容必须可解析为 YAML map。
    - fieldPaths 为点分路径数组，按数组顺序逐个取值；为空时以 filePath 的文件名去掉最后一个扩展名作为唯一路径，文件名不含扩展名时使用完整文件名。
    - 每条路径必须命中且结果可恢复为 YAML 值；未命中或无法恢复时中断。
    - 各项结果按读取顺序累加：两侧均为 map 时递归合并，slice、string 与其他基本类型整体覆盖。

  边界:
    - 只读取 Chart 内文件，不处理远程或绝对路径，不校验字段的业务语义。
    - 路径取值委托 base.map.dig，map 合并委托 mustMergeOverwrite；本模板只负责判定命中与结果恢复，不限定返回类型。
    - 不输出父级键，也不决定调用方如何使用合并结果；无有效项时输出空内容。

  入参: list [上下文, fileRefs 原始 YAML 字符串]；上下文必须含可用的 Files。

  返回值: 合并后内容的 YAML 字符串；类型与读取结果一致，可为 map、slice、string 或其他 YAML 值；无有效项时为空内容。

  示例:
    {{- include "base.fileRefs" (list . "filePath: _configs/resources.yaml") }}
*/ -}}
{{- define "base.fileRefs" -}}
  {{- /* Step 1: 参数校验 */ -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.fileRefs] parameter: must be slice type" }}
  {{- end }}
  {{- if ne (len .) 2 }}
    {{- fail (printf "[base.fileRefs] parameter: must contain 2 elements (context, raw), got '%d'" (len .)) }}
  {{- end }}

  {{- /* Step 2: 解析参数 */ -}}
  {{- $ctx := index . 0 }}
  {{- if not (kindIs "map" $ctx) }}
    {{- fail (printf "[base.fileRefs] parameter 0 (context): must be map type, got '%s'" (kindOf $ctx)) }}
  {{- end }}
  {{- $files := get $ctx "Files" }}
  {{- if not $files }}
    {{- fail "[base.fileRefs] parameter 0 (context): Files is required" }}
  {{- end }}
  {{- $_raw := index . 1 }}
  {{- if not (kindIs "string" $_raw) }}
    {{- fail (printf "[base.fileRefs] parameter 1 (raw): must be string type, got '%s'" (kindOf $_raw)) }}
  {{- end }}

  {{- /* Step 3: 形态归一: 先按 array 恢复，失败时按 map 恢复为单元素数组；其他形态中断。 */ -}}
  {{- $__items := $_raw | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $__items) "true" }}
    {{- $__items = $_raw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $__items) "true" }}
      {{- fail "[base.fileRefs] parameter 1 (raw): must be array or map type" }}
    {{- end }}
    {{- $__items = list $__items }}
  {{- end }}

  {{- /* Step 4: 逐项读取文件并按顺序合并 */ -}}
  {{- $result := "" }}
  {{- $hasResult := false }}
  {{- range $index, $_item := $__items }}
    {{- if not (kindIs "map" $_item) }}
      {{- fail (printf "[base.fileRefs] items[%d]: must be map type, got '%s'" $index (kindOf $_item)) }}
    {{- end }}

    {{- /* filePath（string, 必填）: 解码后判空；绝对路径由 base.path 的 rel 模式中断，根目录逃逸在此补充拒绝。 */ -}}
    {{- $filePath := include "base.string.normalize" (include "base.get" (list $_item "filePath")) | trim }}
    {{- if not $filePath }}
      {{- fail (printf "[base.fileRefs] items[%d].filePath: required field must not be blank" $index) }}
    {{- end }}
    {{- $_path := include "base.path" (list $filePath "rel") }}
    {{- if or (eq $_path "..") (hasPrefix "../" $_path) }}
      {{- fail (printf "[base.fileRefs] items[%d].filePath: must not escape the chart root, got '%s'" $index $filePath) }}
    {{- end }}

    {{- /* fieldPaths（string array, 可选）: 为空时以文件名去掉最后一个扩展名作为唯一路径。 */ -}}
    {{- $_fieldPathsRaw := include "base.get" (list $_item "fieldPaths") | trim }}
    {{- $fieldPaths := list }}
    {{- if $_fieldPathsRaw }}
      {{- $fieldPaths = $_fieldPathsRaw | fromYamlArray }}
      {{- if eq (include "base.isFromYamlArrayError" $fieldPaths) "true" }}
        {{- fail (printf "[base.fileRefs] items[%d].fieldPaths: must be array type" $index) }}
      {{- end }}
    {{- end }}
    {{- if not $fieldPaths }}
      {{- $_fileName := base $_path }}
      {{- $_nameParts := splitList "." $_fileName }}
      {{- if gt (len $_nameParts) 1 }}
        {{- $fieldPaths = list (mustInitial $_nameParts | join ".") }}
      {{- else }}
        {{- $fieldPaths = list $_fileName }}
      {{- end }}
    {{- end }}

    {{- /* 文件内容: 文件缺失、为空或无法解析为 YAML map 时中断。 */ -}}
    {{- $_content := $files.Get $_path }}
    {{- if not (trim $_content) }}
      {{- fail (printf "[base.fileRefs] items[%d].filePath: file must exist and not be empty, got '%s'" $index $_path) }}
    {{- end }}
    {{- $_document := $_content | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_document) "true" }}
      {{- fail (printf "[base.fileRefs] items[%d].filePath: file must be valid YAML mapping, got '%s'" $index $_path) }}
    {{- end }}

    {{- /* 逐路径取值: 委托 base.map.dig 按 `.` 取值，未命中输出空内容。 */ -}}
    {{- range $_fieldPath := $fieldPaths }}
      {{- if not (kindIs "string" $_fieldPath) }}
        {{- fail (printf "[base.fileRefs] items[%d].fieldPaths: each item must be string type, got '%s'" $index (kindOf $_fieldPath)) }}
      {{- end }}

      {{- $_digRaw := include "base.map.dig" (list $_document $_fieldPath "") | trim }}
      {{- if not $_digRaw }}
        {{- fail (printf "[base.fileRefs] items[%d].fieldPaths: '%s' not found in '%s'" $index $_fieldPath $_path) }}
      {{- end }}

      {{- /* 结果恢复: 依次按 sequence、mapping、scalar 恢复；均失败时中断。 */ -}}
      {{- $_node := $_digRaw | fromYamlArray }}
      {{- if eq (include "base.isFromYamlArrayError" $_node) "true" }}
        {{- $_node = $_digRaw | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_node) "true" }}
          {{- $_scalar := fromYaml (printf "v: %s" $_digRaw) }}
          {{- if eq (include "base.isFromYamlError" $_scalar) "true" }}
            {{- fail (printf "[base.fileRefs] items[%d].fieldPaths: '%s' is not a valid YAML value" $index $_fieldPath) }}
          {{- end }}
          {{- $_node = get $_scalar "v" }}
        {{- end }}
      {{- end }}

      {{- /* 累加: 首个有效结果直接采用；两侧均为 map 时递归合并，其他类型整体覆盖；后出现者优先。 */ -}}
      {{- if not $hasResult }}
        {{- $result = $_node }}
        {{- $hasResult = true }}
      {{- else if and (kindIs "map" $result) (kindIs "map" $_node) }}
        {{- $_ := mustMergeOverwrite $result $_node }}
      {{- else }}
        {{- $result = $_node }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Step 5: 按实际类型输出结果为 YAML；无有效项时输出空内容 */ -}}
  {{- if $hasResult }}
    {{- toYamlPretty $result }}
  {{- end }}
{{- end }}
