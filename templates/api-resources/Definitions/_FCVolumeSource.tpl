{{- /*
  渲染 Kubernetes FCVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - fsType     (string, 可选):       YAML 标量解码后 trim；空值跳过，仅 ext4、xfs、ntfs 合法，输出保持原值。
    - lun        (integer, 可选):      仅 targetWWNs 分支生效；缺失时中断，非负整数校验后输出，显式 0 生效。
    - readOnly   (boolean, 可选):      剥离 YAML 引号并 trim；显式 false 生效，其余交 base.bool 校验。
    - targetWWNs (string array, 可选): 与 wwids 互斥且优先；非空时选择本分支，元素必须为 string。
    - wwids      (string array, 可选): targetWWNs 为空时生效；本分支不渲染 lun，元素必须为 string。

  边界:
    - 只输出当前层字段，不输出 fc 父键、apiVersion、kind 或 status；未声明字段静默忽略。
    - 上下文可为原生 map 或父模板清洗后的 map，两种形态按同一契约渲染。
    - targetWWNs 与 wwids 缺失、为 null 或为空 array 时均视为未提供；两者都未提供时中断。
    - targetWWNs 已提供时 wwids 不参与输出与校验；wwids 分支下 lun 不参与输出与校验。
    - 本模板自身产生的失败消息使用 [definitions.fcVolumeSource] 前缀并带字段名；委托 base.* 时保留其自身前缀。
    - 字段生效判定基于归一化前取值，空字符串或 nil 不输出；不填充 fsType、lun 或 readOnly 默认值。

  入参: 上下文 map，可包含以下字段:
    - fsType     (string, 可选)       文件系统类型，取值为 ext4、xfs、ntfs
    - lun        (integer, 可选)      FC 目标 LUN 编号，非负
    - readOnly   (boolean, 可选)      是否只读挂载
    - targetWWNs (string array, 可选) FC 目标 WWN 列表
    - wwids      (string array, 可选) FC 卷 WWID 列表

  返回值: 可嵌入 Volume.fc 位置的 FCVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.fcVolumeSource" (dict "targetWWNs" (list "10:20:30:40:50:60:70:80") "lun" 0) }}
      // lun: 0
      // targetWWNs:
      //   - "10:20:30:40:50:60:70:80"
    {{- include "definitions.fcVolumeSource" (dict "wwids" (list "0x5001") "readOnly" true) }}
      // readOnly: true
      // wwids:
      //   - 0x5001
*/ -}}
{{- define "definitions.fcVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* fsType（string, 可选）: base.get 取值后按 YAML 标量解码并 trim；非空时由 base.field 的允许值列表校验 ext4、xfs、ntfs 并原样输出。 */ -}}
  {{- $fsType := include "base.string.normalize" (include "base.get" (list . "fsType")) | trim }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" (list "ext4" "xfs" "ntfs")) }}
  {{- end }}

  {{- /* targetWWNs（string array, 可选）: 优先取值并恢复为 list，排除解析错误后逐元素执行 string 门禁；非空时选择本分支，输出在本模板末尾按 API 顺序完成。 */ -}}
  {{- $targetWWNs := list }}
  {{- $_targetWWNsRaw := include "base.get" (list . "targetWWNs") | trim }}
  {{- if $_targetWWNsRaw }}
    {{- $targetWWNs = fromYamlArray $_targetWWNsRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $targetWWNs) "true" }}
      {{- fail "[definitions.fcVolumeSource] targetWWNs: must be string array type" }}
    {{- end }}
    {{- range $_target := $targetWWNs }}
      {{- if not (kindIs "string" $_target) }}
        {{- fail (printf "[definitions.fcVolumeSource] targetWWNs: elements must be strings, got '%v' (%s)" $_target (kindOf $_target)) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* wwids（string array, 可选）: 仅在 targetWWNs 未生效时取值；恢复、解析错误与元素类型处理同 targetWWNs，输出在本模板末尾完成。 */ -}}
  {{- $wwids := list }}
  {{- if not $targetWWNs }}
    {{- $_wwidsRaw := include "base.get" (list . "wwids") | trim }}
    {{- if $_wwidsRaw }}
      {{- $wwids = fromYamlArray $_wwidsRaw }}
      {{- if eq (include "base.isFromYamlArrayError" $wwids) "true" }}
        {{- fail "[definitions.fcVolumeSource] wwids: must be string array type" }}
      {{- end }}
      {{- range $_wwid := $wwids }}
        {{- if not (kindIs "string" $_wwid) }}
          {{- fail (printf "[definitions.fcVolumeSource] wwids: elements must be strings, got '%v' (%s)" $_wwid (kindOf $_wwid)) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* lun（integer, 可选）: 仅在 targetWWNs 分支生效；targetWWNs 非空而 lun 缺失时中断，非空时由 base.int.positive 完成非负整数校验并输出，显式 0 保留；wwids 分支忽略本字段。 */ -}}
  {{- if $targetWWNs }}
    {{- $_lunRaw := include "base.get" (list . "lun") | trim }}
    {{- if not $_lunRaw }}
      {{- fail "[definitions.fcVolumeSource] lun: required when targetWWNs is set" }}
    {{- end }}
    {{- include "base.field" (list "lun" $_lunRaw "base.int.positive") }}

  {{- else if not $wwids }}
    {{- fail "[definitions.fcVolumeSource] targetWWNs/wwids: at least one is required" }}
  {{- end }}

  {{- /* readOnly（boolean, 可选）: 剥离 YAML 引号并 trim 后非空则交 base.bool 校验并输出，显式 false 生效；空值跳过。 */ -}}
  {{- $_readOnly := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "readOnly") | trim) "$1" | trim }}
  {{- if $_readOnly }}
    {{- include "base.field" (list "readOnly" $_readOnly "base.bool") }}
  {{- end }}

  {{- /* targetWWNs / wwids（string array, 可选）: 当前分支列表按输入顺序以 base.slice 输出，未选中的 WWN 组不输出。 */ -}}
  {{- if $targetWWNs }}
    {{- include "base.field" (list "targetWWNs" $targetWWNs "base.slice") }}
  {{- else if $wwids }}
    {{- include "base.field" (list "wwids" $wwids "base.slice") }}
  {{- end }}
{{- end }}
