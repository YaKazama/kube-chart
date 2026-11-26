{{- /*
  渲染 Kubernetes ISCSIVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - chapAuthDiscovery (boolean, 可选): 解码后 trim；空值跳过，非空时按 boolean 校验并输出小写。
    - chapAuthSession   (boolean, 可选): 同上。
    - fsType            (string, 可选): 解码后 trim；空值跳过，非空时大小写不敏感匹配 ext4/xfs/ntfs 并输出小写。
    - initiatorName     (string, 可选): 解码后 trim；空值跳过，非空时以带引号标量输出。
    - iqn               (string, 必填): 解码后 trim 判空，以带引号标量输出。
    - iscsiInterface    (string, 可选): 解码后 trim；空值跳过，非空时以带引号标量输出。
    - lun               (integer, 必填): 非负整数，显式 0 输出。
    - portals           (string array, 可选): 清洗并归一化；非法元素丢弃，空列表不输出。
    - readOnly          (boolean, 可选): 解码后 trim；空值跳过，非空时按 boolean 校验并输出小写。
    - secretRef         (LocalObjectReference, 可选): string 名称或 map；清洗为 map 后委托 definitions.localObjectReference。
    - targetPortal      (string, 必填): host:port 归一化，省略端口补全 :3260。

  边界:
    - 只输出当前层字段，不输出 iscsi 父键、apiVersion 或 kind。
    - 上下文为 ISCSIVolumeSource map；string 简写由父模板 definitions.volume 解析后传入。
    - map 只读取上述字段，未声明的键静默忽略；除 secretRef 外，base.get 默认开启别名。
    - secretRef 直接从上下文读取以区分 string 与 map，因此 secretRefAlias 不生效。
    - portals 的非法元素不中断渲染，仅丢弃；targetPortal 非法时中断。
    - 委托 definitions.localObjectReference 时保留其自身失败前缀。

  入参: 上下文 map，可包含以下字段:
    - chapAuthDiscovery (boolean, 可选)
    - chapAuthSession   (boolean, 可选)
    - fsType            (string, 可选)  ext4、xfs 或 ntfs
    - initiatorName     (string, 可选)
    - iqn               (string, 必填)
    - iscsiInterface    (string, 可选)
    - lun               (integer, 必填) 非负
    - portals           (string array, 可选)
    - readOnly          (boolean, 可选)
    - secretRef         (LocalObjectReference, 可选)
    - targetPortal      (string, 必填)

  返回值: 可嵌入 Volume.iscsi 位置的 ISCSIVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.iscsiVolumeSource" (dict "iqn" "iqn.1994-05.com.example:disk" "lun" 0 "targetPortal" "10.0.2.15") }}
      // iqn: "iqn.1994-05.com.example:disk"
      // lun: 0
      // targetPortal: "10.0.2.15:3260"
*/ -}}
{{- define "definitions.iscsiVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* chapAuthDiscovery（boolean, 可选）: 空值跳过，非空时按 boolean 校验并输出小写。 */ -}}
  {{- $_chapDiscoveryRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "chapAuthDiscovery") | trim) "$1" | trim }}
  {{- if $_chapDiscoveryRaw }}
    {{- include "base.field" (list "chapAuthDiscovery" (include "base.bool" (lower $_chapDiscoveryRaw)) "base.bool") }}
  {{- end }}

  {{- /* chapAuthSession（boolean, 可选）: 空值跳过，非空时按 boolean 校验并输出小写。 */ -}}
  {{- $_chapSessionRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "chapAuthSession") | trim) "$1" | trim }}
  {{- if $_chapSessionRaw }}
    {{- include "base.field" (list "chapAuthSession" (include "base.bool" (lower $_chapSessionRaw)) "base.bool") }}
  {{- end }}

  {{- /* fsType（string, 可选）: 空值跳过，非空时小写后按 ext4/xfs/ntfs 枚举校验。 */ -}}
  {{- $fsType := lower (include "base.string.normalize" (include "base.get" (list . "fsType")) | trim) }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" (list "ext4" "xfs" "ntfs")) }}
  {{- end }}

  {{- /* initiatorName（string, 可选）: 空值跳过，非空时以带引号标量输出。 */ -}}
  {{- $_initiatorName := include "base.string.normalize" (include "base.get" (list . "initiatorName")) | trim }}
  {{- if $_initiatorName }}
    {{- include "base.field" (list "initiatorName" $_initiatorName "quote") }}
  {{- end }}

  {{- /* iqn（string, 必填）: 解码后 trim 判空，以带引号标量输出。 */ -}}
  {{- $iqn := include "base.string.normalize" (include "base.get" (list . "iqn")) | trim }}
  {{- if not $iqn }}
    {{- fail "[definitions.iscsiVolumeSource] iqn: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "iqn" $iqn "quote") }}

  {{- /* iscsiInterface（string, 可选）: 空值跳过，非空时以带引号标量输出。 */ -}}
  {{- $_iscsiInterface := include "base.string.normalize" (include "base.get" (list . "iscsiInterface")) | trim }}
  {{- if $_iscsiInterface }}
    {{- include "base.field" (list "iscsiInterface" $_iscsiInterface "quote") }}
  {{- end }}

  {{- /* lun（integer, 必填）: 非负整数，显式 0 输出。 */ -}}
  {{- $_lunRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "lun") | trim) "$1" | trim }}
  {{- if not $_lunRaw }}
    {{- fail "[definitions.iscsiVolumeSource] lun: required field is missing or empty" }}
  {{- end }}
  {{- $lun := include "base.int.positive" $_lunRaw }}
  {{- include "base.field" (list "lun" $lun "base.int") }}

  {{- /* portals（string array, 可选）: 清洗后逐项归一化，非法元素丢弃，空列表不输出。 */ -}}
  {{- $_portalsRaw := include "base.get" (list . "portals" "toStrings") | trim }}
  {{- if $_portalsRaw }}
    {{- $_portalsParsed := $_portalsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_portalsParsed) "true" }}
      {{- fail "[definitions.iscsiVolumeSource] portals: must be string array" }}
    {{- end }}
    {{- $portals := list }}
    {{- range $_portalItem := include "base.slice.cleanup" (list $_portalsParsed $const.SPLIT.COMMA) | fromYamlArray }}
      {{- $_portal := toString $_portalItem }}
      {{- $_normalized := include "base.net.hostPort" (list $_portal "3260" false) }}
      {{- if and (mustRegexMatch $const.K8S.VOLUME.ISCSI_PORTAL $_portal) $_normalized }}
        {{- $portals = mustAppend $portals $_normalized }}
      {{- end }}
    {{- end }}
    {{- if $portals }}
      {{- include "base.field" (list "portals" $portals "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* readOnly（boolean, 可选）: 空值跳过，非空时按 boolean 校验并输出小写。 */ -}}
  {{- $_readOnlyRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "readOnly") | trim) "$1" | trim }}
  {{- if $_readOnlyRaw }}
    {{- include "base.field" (list "readOnly" (include "base.bool" (lower $_readOnlyRaw)) "base.bool") }}
  {{- end }}

  {{- /* secretRef（LocalObjectReference, 可选）: string 名称或 map 清洗为 map 后委托 definitions.localObjectReference。 */ -}}
  {{- $_secretRefRaw := get . "secretRef" }}
  {{- $secretRef := dict }}
  {{- if kindIs "string" $_secretRefRaw }}
    {{- $_secretName := include "base.string.normalize" $_secretRefRaw | trim }}
    {{- if $_secretName }}
      {{- $secretRef = dict "name" $_secretName }}
    {{- end }}

  {{- else if kindIs "map" $_secretRefRaw }}
    {{- $secretRef = $_secretRefRaw }}

  {{- else if not (kindIs "invalid" $_secretRefRaw) }}
    {{- fail (printf "[definitions.iscsiVolumeSource] secretRef: must be object or string type, got '%s'" (kindOf $_secretRefRaw)) }}
  {{- end }}
  {{- if $secretRef }}
    {{- $_secretRefRendered := include "definitions.localObjectReference" $secretRef | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_secretRefRendered) "true" }}
      {{- fail "[definitions.iscsiVolumeSource] secretRef: definitions.localObjectReference rendered invalid YAML" }}
    {{- end }}
    {{- if $_secretRefRendered }}
      {{- include "base.field" (list "secretRef" $_secretRefRendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* targetPortal（string, 必填）: host:port 归一化，省略端口补全 :3260。 */ -}}
  {{- $targetPortal := include "base.string.normalize" (include "base.get" (list . "targetPortal")) | trim }}
  {{- if not $targetPortal }}
    {{- fail "[definitions.iscsiVolumeSource] targetPortal: required field is missing or empty" }}
  {{- end }}
  {{- if not (mustRegexMatch $const.K8S.VOLUME.ISCSI_PORTAL $targetPortal) }}
    {{- fail (printf "[definitions.iscsiVolumeSource] targetPortal: '%s' is not a valid portal" $targetPortal) }}
  {{- end }}
  {{- include "base.field" (list "targetPortal" (include "base.net.hostPort" (list $targetPortal "3260" true)) "quote") }}
{{- end }}
