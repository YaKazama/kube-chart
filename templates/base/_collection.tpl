{{- /*
  嵌套字典取值：使用点分路径（a.b.c）从 Map 中提取值，类似 dig 函数。

  入参: list [map, keyPath(string), default(string)]
    map       Map 数据源，必填
    keyPath   点分路径字符串（如 "a.b.c"），必填，分隔符使用 base.env 中的 SPLIT.ALL
    default   默认值，可选，路径不存在时返回，默认为空字符串

  返回值: toYamlPretty 格式化后的 YAML 字符串或默认值

  示例:
    {{- $val := include "base.map.dig" (list .Values "image.repository") | fromYaml }}
    {{- $val := include "base.map.dig" (list .Values "a.b.c" "fallback") | fromYaml }}
*/ -}}
{{- define "base.map.dig" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.map.dig] parameter: must be slice type" }}
  {{- end }}
  {{- $sliceLen := len . }}
  {{- if or (lt $sliceLen 2) (gt $sliceLen 3) }}
    {{- fail (printf "[base.map.dig] parameter: at least 2 elements required (map, keyPath), got '%d'" $sliceLen) }}
  {{- end }}

  {{- $m := index . 0 }}
  {{- if not (kindIs "map" $m) }}
    {{- fail (printf "[base.map.dig] parameter 0: must be map type, got '%s'" (kindOf $m)) }}
  {{- end }}
  {{- $keyPath := index . 1 }}
  {{- if not (kindIs "string" $keyPath) }}
    {{- fail (printf "[base.map.dig] parameter 1: must be string type, got '%s'" (kindOf $keyPath)) }}
  {{- end }}

  {{- $const := include "base.env" "" | fromYaml }}
  {{- $default := $const.EMPTY_STR }}
  {{- if ge $sliceLen 3 }}
    {{- $default = index . 2 }}
  {{- end }}

  {{- $keys := mustRegexSplit $const.SPLIT.ALL $keyPath -1 }}

  {{- /* 将拆分后的 keys 列表传递给 helper 模板进行递归 */ -}}
  {{- include "base.map.dig.helper" (list $m $keys $default) }}
{{- end }}


{{- /*
  内部辅助模板：递归遍历 keys 列表逐层深入 Map 取值，由 base.map.dig 调用。

  入参: list [map, keys(slice), default(string)]
    map       当前层级的 Map 数据源
    keys      待遍历的键名列表（每层取 mustFirst 作为当前键，mustRest 传入下一层递归）
    default   路径不存在或中间节点非 map 时返回的默认值

  返回值: 末级 key 命中时返回 toYamlPretty 格式化后的 YAML 字符串，否则返回 default

  注意: 仅供 base.map.dig 内部使用，禁止外部直接调用
*/ -}}
{{- define "base.map.dig.helper" -}}
  {{- $m := index . 0 }}
  {{- $keys := index . 1 }}
  {{- $default := index . 2 }}

  {{- $first := mustFirst $keys }}
  {{- $rest := mustRest $keys }}

  {{- if kindIs "map" $m }}
    {{- if hasKey $m $first }}
      {{- $val := get $m $first }}
      {{- if eq (len $rest) 0 }}
        {{- /* 末级 key，格式化输出 */ -}}
        {{- toYamlPretty $val }}
      {{- else }}
        {{- /* 递归传递剩余的 keys 列表，避免重新 join 字符串 */ -}}
        {{- include "base.map.dig.helper" (list $val $rest $default) }}
      {{- end }}
    {{- else }}
      {{- $default }}
    {{- end }}
  {{- else }}
    {{- /* 中间节点不是 map，无法继续深入，返回默认值 */ -}}
    {{- $default }}
  {{- end }}
{{- end }}


{{- /*
  Map 值 Base64 编码：对 Map 中所有值进行 base64 编码后输出。

  入参: Map 数据源，空 Map 也合法
    - 所有值必须是标量类型（string/int/float64/bool）
    - nil 或非标量类型（map/slice）会报错

  返回值: toYamlPretty 格式化后的 YAML 字符串，键保持不变，值为带双引号的 base64 字符串

  用途: 用于 Secret 的 data 字段编码

  示例:
    {{- $encoded := include "base.map.b64enc" .Values.data }}
*/ -}}
{{- define "base.map.b64enc" -}}
  {{- if kindIs "map" . }}
    {{- $val := dict }}
    {{- range $k, $v := . }}
      {{- /* 拦截未定义或无效的值 */ -}}
      {{- if kindIs "invalid" $v }}
        {{- fail (printf "[base.map.b64enc] key '%s': value must not be nil" $k) }}
      {{- end }}

      {{- /* 拦截 nil、map、slice 等非标量类型 */ -}}
      {{- if or (kindIs "map" $v) (kindIs "slice" $v) (kindIs "nil" $v) }}
        {{- fail (printf "[base.map.b64enc] key '%s': value must be scalar type, got '%s'" $k (kindOf $v)) }}
      {{- end }}
      {{- $_ := set $val $k ($v | toString | b64enc) }}
    {{- end }}
    {{- toYamlPretty $val }}
  {{- else }}
    {{- fail (printf "[base.map.b64enc] parameter: must be map type, got '%s'" (kindOf .)) }}
  {{- end }}
{{- end }}


{{- /*
  Map 值校验：对 Map 中每个值进行正则校验，不符合的值报错。

  入参: list [dict, regex(string)]
    dict    Map 数据源，必填，空 Map 也合法
    regex   正则表达式字符串，可选，用于校验每个值是否合法；空字符串则跳过校验

  返回值: toYamlPretty 格式化后的 YAML 字符串，键和校验通过的值

  用途: 用于 resources.requests 和 resources.limits 的值校验

  示例:
    {{- $verified := include "base.map.verify" (list .Values.resources "^\\d+(m|Mi|Gi)?$") }}
*/ -}}
{{- define "base.map.verify" -}}
  {{- if or (not (kindIs "slice" .)) (ne (len .) 2) }}
    {{- fail (printf "[base.map.verify] parameter: must be slice with 2 elements, got '%d'" (len .)) }}
  {{- end }}

  {{- $data := index . 0 }}
  {{- if not (kindIs "map" $data) }}
    {{- fail (printf "[base.map.verify] parameter 0: must be map type, got '%s'" (kindOf $data)) }}
  {{- end }}
  {{- $regex := default "" (index . 1) }}
  {{- if and $regex (not (kindIs "string" $regex)) }}
    {{- fail (printf "[base.map.verify] parameter 1: must be string type, got '%s'" (kindOf $regex)) }}
  {{- end }}

  {{- $val := dict }}
  {{- range $k, $v := $data }}
    {{- if $regex }}
      {{- if not (mustRegexMatch $regex (toString $v)) }}
        {{- fail (printf "[base.map.verify] key '%s': value '%s' does not match regex '%s'" $k $v $regex) }}
      {{- end }}
    {{- end }}
    {{- $_ := set $val $k $v }}
  {{- end }}
  {{- toYamlPretty $val }}
{{- end }}


{{- /*
  索引 Map 构建：从多个 Map 中提取指定字段的值作为新键，将整个 Map 作为值，构建索引 Map。
  支持覆盖策略控制，用于处理重复键的冲突。

  入参: list [key, overwrite(bool), map1, map2, ...]
    key         用于提取新键的字段名，必填，string 类型；该字段的值必须为 string 类型
    overwrite   是否启用覆盖模式，必填，bool 类型
                  false: 左侧优先，重复键保留首次出现的 Map
                  true:  右侧优先，重复键使用最后出现的 Map 覆盖
    map1...     待处理的 Map 列表，至少 1 个；不包含指定 key 的元素会被跳过

  返回值: toYamlPretty 格式化后的索引 Map
    - 键: 指定字段的值（string 类型）
    - 值: 原始 Map 的完整内容

  示例:
    {{- $indexed := include "base.map.merge" (list "name" true .Values.map1 .Values.map2) }}
    {{- /* 输入: [{name: "web", port: 80}, {name: "db", port: 5432}] */ -}}
    {{- /* 输出: {web: {name: "web", port: 80}, db: {name: "db", port: 5432}} */ -}}
*/ -}}
{{- define "base.map.merge" -}}
  {{- if or (not (kindIs "slice" .)) (lt (len .) 3) }}
    {{- fail (printf "[base.map.merge] parameter: must be slice with at least 3 elements, got '%d'" (len .)) }}
  {{- end }}

  {{- $key := index . 0 }}
  {{- if not (kindIs "string" $key) }}
    {{- fail (printf "[base.map.merge] parameter 0: must be string type, got '%s'" (kindOf $key)) }}
  {{- end }}
  {{- $overwrite := index . 1 }}
  {{- if not (kindIs "bool" $overwrite) }}
    {{- fail (printf "[base.map.merge] parameter 1: must be bool type, got '%s'" (kindOf $overwrite)) }}
  {{- end }}
  {{- $maps := mustSlice . 2 }}
  {{- range $i, $m := $maps }}
    {{- if not (kindIs "map" $m) }}
      {{- fail (printf "[base.map.merge] parameter %d: must be map type, got '%s'" (add $i 2) (kindOf $m)) }}
    {{- end }}
  {{- end }}

  {{- /* 初始化结果 Map */ -}}
  {{- $rslt := dict }}

  {{- /* 遍历所有 Map，提取指定字段值作为新键，构建索引 */ -}}
  {{- range $m := $maps }}
    {{- if hasKey $m $key }}
      {{- $keyVal := get $m $key }}
      {{- /* 校验键值必须为 string 类型，避免 set 函数 panic */ -}}
      {{- if not (kindIs "string" $keyVal) }}
        {{- fail (printf "[base.map.merge] key field '%s': value must be string type, got '%s'" $key (kindOf $keyVal)) }}
      {{- end }}
      {{- if or $overwrite (not (hasKey $rslt $keyVal)) }}
        {{- $_ := set $rslt $keyVal $m }} {{/* set 直接设置，覆盖模式或键不存在时设置 */}}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 输出索引 Map（YAML 格式） */ -}}
  {{- toYamlPretty $rslt }}
{{- end }}


{{- /*
  IP 列表校验：校验 Slice 中每个值是否为合法 IP 地址（IPv4/IPv6），去重后输出。

  入参: Slice 数据源，必填
    - 元素类型必须为 string，非 string 元素会立即报错
    - 空 Slice 合法，输出空列表

  返回值: toYamlPretty 格式化后的合法 IP 地址列表（已去重）

  示例:
    {{- $ips := include "base.slice.ips" .Values.ipList }}
      输入: ["192.168.1.1", "10.0.0.1", "192.168.1.1", "::1"]
      输出: [192.168.1.1, 10.0.0.1, ::1]
*/ -}}
{{- define "base.slice.ips" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail (printf "[base.slice.ips] parameter: must be slice type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- $val := list }}
  {{- range $v := . }}
    {{- if not (kindIs "string" $v) }}
      {{- fail (printf "[base.slice.ips] element: must be string type, got '%s'" (kindOf $v)) }}
    {{- end }}
    {{- $val = mustAppend $val (include "base.net" (list $v "ip")) }}
  {{- end }}
  {{- toYamlPretty ($val | mustUniq) }}
{{- end }}


{{- /*
  白名单过滤：从数据源列表中过滤出在允许范围内的值，不在范围内的值被丢弃，最后去重输出。

  入参: list [value(slice), allowsList(slice)]
    value       待过滤的数据源列表，必填，必须是 slice 类型
    allowsList  允许值列表，必填，必须是 slice 类型；仅保留在此列表中出现的值

  返回值: toYamlPretty 格式化后的过滤结果列表（已去重）

  示例:
    {{- $filtered := include "base.slice.allows" (list .Values.items (list "a" "b" "c")) }}
      输入: [["a", "b", "x", "a", "y"], ["a", "b", "c"]]
      输出: [a, b]
*/ -}}
{{- define "base.slice.allows" -}}
  {{- if not (and (kindIs "slice" .) (eq (len .) 2)) }}
    {{- fail (printf "[base.slice.allows] parameter: must be slice with 2 elements, format: '[value(slice) allowsList(slice)]', got '%d'" (len .)) }}
  {{- end }}

  {{- $data := index . 0 }}
  {{- if not (kindIs "slice" $data) }}
    {{- fail (printf "[base.slice.allows] parameter 0: must be slice type, got '%s'" (kindOf $data)) }}
  {{- end }}
  {{- $allows := index . 1 }}
  {{- if not (kindIs "slice" $allows) }}
    {{- fail (printf "[base.slice.allows] parameter 1: must be slice type, got '%s'" (kindOf $allows)) }}
  {{- end }}

  {{- $val := list }}
  {{- range $v := $data }}
    {{- if mustHas $v $allows }}
      {{- $val = mustAppend $val $v }}
    {{- end }}
  {{- end }}
  {{- toYamlPretty ($val | mustUniq) }}
{{- end }}


{{- /*
  混合类型数据清洗：递归归一化为标准列表，支持字符串拆分、整型转换、正则校验与自定义处理。

  入参: list [s, r, c, define, sep, empty]
    s       数据源，必填（位置 0），支持类型：
              - string:    "a, b,c d"（按 r 拆分）
              - slice:     [a, b, c] 或 [{k: v}, ...]（递归清洗）
              - int/int64/float64: 标量或列表（直接追加）
              - map:       {k: v}（直接追加）
    r       拆分正则，可选（位置 1，string），默认 base.env.SPLIT.ALL
              常用：","、"."、":"、"|"、"/"、"*"、"^"、"@"、"#"、"\s"
    c       校验正则，可选（位置 2，string），元素未匹配则立即报错
    define  自定义处理模板名，可选（位置 3，string），对每个元素单独调用
    sep     输出分隔符，可选（位置 4，string），非空时按 join 输出字符串
    empty   是否保留空字符串，可选（位置 5，bool），默认 false 时仅剔除空字符串

  返回值:
    - 未指定 sep：toYamlPretty 格式化后的列表
    - 指定 sep：join 拼接后的字符串
    - 元素类型保留原始类型，纯数字字符串自动转 int
    - 末尾自动 mustUniq 去重；empty=false 时仅去除空字符串，不影响 0/false

  示例:
    字符串拆分：默认分隔符
    {{- $cleaned := include "base.slice.cleanup" (list .Values.items) | fromYaml }}
    自定义分隔符
    {{- $cleaned := include "base.slice.cleanup" (list "a,b,c" ",") | fromYaml }}
    输出 join 字符串
    {{- $joined := include "base.slice.cleanup" (list .Values.items "" "" "" "-") }}
      输入: ["a, b", "c"]
      输出: [a, b, c]
*/ -}}
{{- define "base.slice.cleanup" -}}
  {{- /* Step 1: 入参形态校验 */ -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.slice.cleanup] parameter: must be slice type" }}
  {{- end }}
  {{- $sliceLen := len . }}
  {{- if or (lt $sliceLen 1) (gt $sliceLen 6) }}
    {{- fail (printf "[base.slice.cleanup] parameter: count must be 1-6, format: '[s r c define sep empty]', got '%d'" $sliceLen) }}
  {{- end }}

  {{- /* Step 2: 解析入参（按位置显式赋值，避免 default 吞掉显式传参） */ -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $s := index . 0 }}
  {{- $r := $const.SPLIT.ALL }}
  {{- $c := "" }}
  {{- $define := "" }}
  {{- $sep := "" }}
  {{- $empty := false }}

  {{- if ge $sliceLen 2 }}
    {{- $r = index . 1 }}
  {{- end }}
  {{- if ge $sliceLen 3 }}
    {{- $c = index . 2 }}
  {{- end }}
  {{- if ge $sliceLen 4 }}
    {{- $define = index . 3 }}
  {{- end }}
  {{- if ge $sliceLen 5 }}
    {{- $sep = index . 4 }}
  {{- end }}
  {{- if ge $sliceLen 6 }}
    {{- $empty = index . 5 }}
  {{- end }}

  {{- /* Step 3: 类型校验（fail-fast，避免到 range 阶段才报错） */ -}}
  {{- $sKind := kindOf $s }}
  {{- if not (or (eq $sKind "string") (eq $sKind "slice") (eq $sKind "map") (eq $sKind "int") (eq $sKind "int64") (eq $sKind "float64")) }}
    {{- fail (printf "[base.slice.cleanup] parameter 0 (s): unsupported type '%s'" $sKind) }}
  {{- end }}
  {{- if not (kindIs "string" $r) }}
    {{- fail (printf "[base.slice.cleanup] parameter 1 (r): must be string type, got '%s'" (kindOf $r)) }}
  {{- end }}
  {{- if ge $sliceLen 3 }}
    {{- if not (kindIs "string" $c) }}
      {{- fail (printf "[base.slice.cleanup] parameter 2 (c): must be string type, got '%s'" (kindOf $c)) }}
    {{- end }}
  {{- end }}
  {{- if ge $sliceLen 4 }}
    {{- if not (kindIs "string" $define) }}
      {{- fail (printf "[base.slice.cleanup] parameter 3 (define): must be string type, got '%s'" (kindOf $define)) }}
    {{- end }}
  {{- end }}
  {{- if ge $sliceLen 5 }}
    {{- if not (kindIs "string" $sep) }}
      {{- fail (printf "[base.slice.cleanup] parameter 4 (sep): must be string type, got '%s'" (kindOf $sep)) }}
    {{- end }}
  {{- end }}
  {{- if ge $sliceLen 6 }}
    {{- if not (kindIs "bool" $empty) }}
      {{- fail (printf "[base.slice.cleanup] parameter 5 (empty): must be bool type, got '%s'" (kindOf $empty)) }}
    {{- end }}
  {{- end }}

  {{- /* Step 4: 归一化为列表（string/数值/map 都包一层：避免 range 数值时按 0..n 展开，range map 时按 values 展开） */ -}}
  {{- $data := $s }}
  {{- if not (kindIs "slice" $s) }}
    {{- $data = list $s }}
  {{- end }}

  {{- /* Step 5: 元素清洗（拆分、转 int、递归、汇总） */ -}}
  {{- $clean := list }}
  {{- range $v := $data }}
    {{- if kindIs "slice" $v }}
      {{- /* 递归时强制 $sep="", 避免内层 join 出字符串导致外层 fromYamlArray 解析失败 */ -}}
      {{- $clean = concat $clean (include "base.slice.cleanup" (list $v $r $c $define "" $empty) | fromYamlArray) }}
    {{- else if kindIs "map" $v }}
      {{- $clean = mustAppend $clean $v }}
    {{- else if kindIs "string" $v }}
      {{- $valTmp := list }}
      {{- range $part := mustRegexSplit $r $v -1 }}
        {{- $trimmed := trim $part }}
        {{- /* 数字字符串自动转 int 类型 */ -}}
        {{- if mustRegexMatch $const.TYPES.INT $trimmed }}
          {{- $valTmp = mustAppend $valTmp ($trimmed | int) }}
        {{- else }}
          {{- $valTmp = mustAppend $valTmp $trimmed }}
        {{- end }}
      {{- end }}
      {{- $clean = concat $clean $valTmp }}
    {{- else if or (kindIs "float64" $v) (kindIs "int" $v) (kindIs "int64" $v) }}
      {{- $clean = mustAppend $clean $v }}
    {{- else }}
      {{- fail (printf "[base.slice.cleanup] element: unsupported type '%s'" (kindOf $v)) }}
    {{- end }}
  {{- end }}

  {{- /* Step 6: 正则校验 + 自定义处理（合并为单次遍历） */ -}}
  {{- $val := list }}
  {{- range $v := $clean }}
    {{- if $c }}
      {{- if not (mustRegexMatch $c (toString $v)) }}
        {{- fail (printf "[base.slice.cleanup] value '%v': does not match regex '%s'" $v $c) }}
      {{- end }}
    {{- end }}
    {{- if $define }}
      {{- $val = mustAppend $val (include $define $v | fromYaml) }}
    {{- else }}
      {{- $val = mustAppend $val $v }}
    {{- end }}
  {{- end }}

  {{- /* Step 7: 末尾去重 + 按需剔除空字符串（不误删 0/false） */ -}}
  {{- $val = mustUniq $val }}
  {{- if not $empty }}
    {{- $val = mustWithout $val "" }}
  {{- end }}

  {{- /* Step 8: 输出（始终输出，不走 if $val 包裹；空列表对应 toYamlPretty→"[]" / join→""，均可被安全解析） */ -}}
  {{- if $sep }}
    {{- join $sep $val }}
  {{- else }}
    {{- toYamlPretty $val }}
  {{- end }}
{{- end }}


{{- /*
  slice 强类型守卫：仅接受 slice 类型，序列化后强制将所有单引号替换为双引号。

  入参: slice 数据源，必填
    - 元素可为任意可 YAML 序列化类型（string/int/float64/bool/map/slice）
    - 非 slice 类型立即报错（fail-fast）

  返回值: toYamlPretty 格式化的字符串，所有单引号已被替换为双引号
    - 空 slice 同样合法，输出 "[]"

  用途: 适配部分 K8s/CRD 字段不接受单引号字符串的场景，强制统一为双引号。

  示例:
    {{- $quoted := include "base.slice.quote" (list "a" "b") }}
      输入: ["a", "b"]
      输出: - a\n- b（双引号风格）
*/ -}}
{{- define "base.slice.quote" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail (printf "[base.slice.quote] parameter: must be slice type, got '%s'" (kindOf .)) }}
  {{- end }}
  {{- toYamlPretty . | replace "'" "\"" }}
{{- end }}
