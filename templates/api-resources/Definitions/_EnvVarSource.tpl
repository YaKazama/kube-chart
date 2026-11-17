{{- /*
  渲染 Kubernetes EnvVarSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - configMapKeyRef (ConfigMapKeySelector, 可选): 值为 map 时原样透传；为 string 时按 name、key、optional 位次组装；委托 definitions.configMapKeySelector。
    - fieldRef (ObjectFieldSelector, 可选): 值为 map 时原样透传；为 string 时按 fieldPath、apiVersion 位次组装；委托 definitions.objectFieldSelector。
    - fileKeyRef (FileKeySelector, 可选): 值为 map 时原样透传；为 string 时按 volumeName、path、key、optional 位次组装；委托 definitions.fileKeySelector。
    - resourceFieldRef (ResourceFieldSelector, 可选): 值为 map 时原样透传；为 string 时按 resource、containerName、divisor 位次组装；委托 definitions.resourceFieldSelector。
    - secretKeyRef (SecretKeySelector, 可选): 值为 map 时原样透传；为 string 时按 name、key、optional 位次组装；委托 definitions.secretKeySelector。

  边界:
    - 只输出当前出现的那一个 *Ref 字段，不包含 valueFrom 父键；父键由调用方添加。
    - 五个字段互斥，同时出现两个及以上时中断并列出实际字段名；未出现任何字段时输出空内容。
    - 五个选择器子模板当前未实现，其可用性由后续变更提供。
    - 字段值的校验、类型转换与缺省处理由对应选择器子模板负责；本模板只做类型区分、位次组装与委托。
    - 字符串段数不足该字段必需段数时不组装，也不中断；超出可选段的多余段被忽略。

  入参: 上下文 map，可包含以下字段之一（互斥）:
    - configMapKeyRef (ConfigMapKeySelector, 可选)
    - fieldRef        (ObjectFieldSelector, 可选)
    - fileKeyRef      (FileKeySelector, 可选)
    - resourceFieldRef (ResourceFieldSelector, 可选)
    - secretKeyRef    (SecretKeySelector, 可选)

  返回值: 以字段名为顶层键的单字段 YAML 片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.envVarSource" (dict "configMapKeyRef" (dict "name" "cfg" "key" "k")) }}
    {{- include "definitions.envVarSource" (dict "secretKeyRef" "db-creds password true") }}
*/ -}}
{{- define "definitions.envVarSource" -}}
  {{- /* 五个互斥字段的配置表：字段名、选择器子模板、字符串位次字段、必需段数。 */ -}}
  {{- $sources := list
    (dict "key" "configMapKeyRef" "define" "definitions.configMapKeySelector" "slots" (list "name" "key" "optional") "required" 2)
    (dict "key" "fieldRef" "define" "definitions.objectFieldSelector" "slots" (list "fieldPath" "apiVersion") "required" 1)
    (dict "key" "fileKeyRef" "define" "definitions.fileKeySelector" "slots" (list "volumeName" "path" "key" "optional") "required" 2)
    (dict "key" "resourceFieldRef" "define" "definitions.resourceFieldSelector" "slots" (list "resource" "containerName" "divisor") "required" 1)
    (dict "key" "secretKeyRef" "define" "definitions.secretKeySelector" "slots" (list "name" "key" "optional") "required" 1)
  }}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 互斥校验: 先收集实际出现的字段，多个并存时在任何组装前中断。 */ -}}
  {{- $present := list }}
  {{- range $source := $sources }}
    {{- if hasKey $ $source.key }}
      {{- $present = mustAppend $present $source.key }}
    {{- end }}
  {{- end }}
  {{- if gt (len $present) 1 }}
    {{- fail (printf "[definitions.envVarSource] fields: mutually exclusive, got '%v'" (join ", " $present)) }}
  {{- end }}

  {{- range $source := $sources }}
    {{- if hasKey $ $source.key }}
      {{- $raw := get $ $source.key }}

      {{- /* 类型区分: map 原样透传；string 按位次组装；其余类型中断。 */ -}}
      {{- $selector := dict }}
      {{- if kindIs "map" $raw }}
        {{- $selector = $raw }}
      {{- else if kindIs "string" $raw }}
        {{- $_parts := mustWithout (mustRegexSplit $const.SPLIT.SPACE_COMMA (trim $raw) -1) "" }}
        {{- if ge (len $_parts) $source.required }}
          {{- range $i, $slot := $source.slots }}
            {{- if lt $i (len $_parts) }}
              {{- $_ := set $selector $slot (index $_parts $i) }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- else }}
        {{- fail (printf "[definitions.envVarSource] %s: must be object or string, got '%s'" $source.key (kindOf $raw)) }}
      {{- end }}

      {{- /* 委托选择器子模板: 空选择器与空结果均不输出字段。 */ -}}
      {{- if $selector }}
        {{- $_rendered := include $source.define $selector | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail (printf "[definitions.envVarSource] %s: invalid YAML output from %s" $source.key $source.define) }}
        {{- end }}
        {{- if $_rendered }}
          {{- include "base.field" (list $source.key $_rendered "base.map") }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
