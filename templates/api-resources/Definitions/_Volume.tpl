{{- /*
  渲染 Kubernetes Volume 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - 入参为 `{name, <source>}`：name 必填，name 以外恰好一个受支持的 source 键。
    - configMap             (object|string): 委托 definitions.configMapVolumeSource。
    - csi                   (object|string): 委托 definitions.csiVolumeSource。
    - downwardAPI           (object|string): 委托 definitions.downwardAPIVolumeSource。
    - emptyDir              (object|string): 委托 definitions.emptyDirVolumeSource。
    - ephemeral             (object):        委托 definitions.ephemeralVolumeSource；不接受 string。
    - fc                    (object|string): 委托 definitions.fcVolumeSource。
    - hostPath              (object|string): 委托 definitions.hostPathVolumeSource。
    - image                 (object|string): 委托 definitions.imageVolumeSource。
    - iscsi                 (object|string): 委托 definitions.iscsiVolumeSource。
    - name                  (string, 必填): 小写后按 RFC1123 Label 校验，以带引号标量输出。
    - nfs                   (object|string): 委托 definitions.nfsVolumeSource。
    - persistentVolumeClaim (object|string): 委托 definitions.persistentVolumeClaimVolumeSource。
    - projected             (object):        委托 definitions.projectedVolumeSource；不接受 string。
    - secret                (object|string): 委托 definitions.secretVolumeSource。

  边界:
    - 只输出 name 与唯一 source 键；name 以外零个、多个或名单外键中断。
    - source 值可为原始 map、string 或 nil；map 原样透传，string 由本模板解析为子模板上下文，nil 按空 map 处理。
    - 子模板不在本模板实现；子模板输出为空、null 或非 map 时输出 `source: {}`；非法 YAML 中断。
    - 字符串 source 的顶层位置段以空白分隔，括号内 array 元素以逗号分隔；关键字与枚举过滤不区分大小写。
    - 由子模板或更下游模板消费的捕获值原样下传；本层只做顶层结构拆分、显式关键字归属和规格列出的校验，不构造 items 元素、fieldRef/resourceFieldRef、nodePublishSecretRef/secretRef 等孙模板 map。
    - 不为 ephemeral、projected 提供 string 简写；其 string 值在入口中断。
    - map 只读取 name 与 13 个 source 键，其他键按名单外 source 中断。

  入参: map，形如 `{name: "data", emptyDir: {}}` 或 `{name: "cfg", configMap: "cm TRUE 0644 items (key path)"}`。

  返回值: 可嵌入 PodSpec.volumes 元素的 Volume YAML 字段片段。

  示例:
    {{- include "definitions.volume" (dict "name" "data" "emptyDir" (dict)) }}
      // emptyDir: {}
      // name: "data"
    {{- include "definitions.volume" (dict "name" "cfg" "configMap" "cm TRUE 0644 items (key path)") }}
      // configMap:
      //   ...
      // name: "cfg"
*/ -}}
{{- define "definitions.volume" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $fields := list "configMap" "csi" "downwardAPI" "emptyDir" "ephemeral" "fc" "hostPath" "image" "iscsi" "name" "nfs" "persistentVolumeClaim" "projected" "secret" }}
  {{- $_ := "" }}

  {{- /* 入参类型: 只接受 map，其他类型中断。 */ -}}
  {{- if not (kindIs "map" .) }}
    {{- fail (printf "[definitions.volume] input: must be object type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- /* name（string, 必填）: 小写后按 RFC1123 Label 校验。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim | lower }}
  {{- if not $name }}
    {{- fail "[definitions.volume] name: required field is missing or empty" }}
  {{- end }}
  {{- $name = include "base.rfc" (list $name "1123") }}

  {{- /* source 唯一性: name 以外必须恰好一个受支持 source 键。 */ -}}
  {{- $source := "" }}
  {{- $sourceValue := "" }}
  {{- range $_key, $_value := . }}
    {{- if ne $_key "name" }}
      {{- if not (has $_key $fields) }}
        {{- fail (printf "[definitions.volume] input: unsupported volume source '%s'" $_key) }}
      {{- end }}
      {{- if $source }}
        {{- fail (printf "[definitions.volume] input: '%s' and '%s' are mutually exclusive volume sources" $source $_key) }}
      {{- end }}
      {{- $source = $_key }}
      {{- $sourceValue = $_value }}
    {{- end }}
  {{- end }}
  {{- if not $source }}
    {{- fail "[definitions.volume] input: exactly one volume source is required" }}
  {{- end }}

  {{- /* source 分派: map 只读透传，nil 按空 map，string 按 source 语法解析为子模板上下文。 */ -}}
  {{- $context := dict }}
  {{- if kindIs "map" $sourceValue }}
    {{- $context = $sourceValue }}

  {{- else if kindIs "string" $sourceValue }}
    {{- if or (eq $source "ephemeral") (eq $source "projected") }}
      {{- fail (printf "[definitions.volume] %s: string input is not supported, use object/map format" $source) }}
    {{- end }}

    {{- /* configMap/secret: <name> [optional] [defaultMode] [items (<key> <path> [mode], ...)]。 */ -}}
    {{- if or (eq $source "configMap") (eq $source "secret") }}
      {{- $_pattern := $const.K8S.VOLUME.KEY_TO_PATH_SOURCE }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] %s: '%s' does not match '<name> [optional] [defaultMode] [items (<key> <path> [mode], ...)]'" $source $sourceValue) }}
      {{- end }}
      {{- $_sourceName := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_optionalRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_defaultMode := mustRegexReplaceAll $_pattern $sourceValue "$3" | trim }}
      {{- $_itemsKeyword := mustRegexReplaceAll $_pattern $sourceValue "$4" | trim }}
      {{- $_itemsRaw := mustRegexReplaceAll $_pattern $sourceValue "$5" }}

      {{- $context = dict }}
      {{- if eq $source "configMap" }}
        {{- $_ = set $context "name" $_sourceName }}
      {{- else }}
        {{- $_ = set $context "secretName" $_sourceName }}
      {{- end }}
      {{- if $_optionalRaw }}
        {{- $_ = set $context "optional" (include "base.bool" (lower $_optionalRaw)) }}
      {{- end }}
      {{- if $_defaultMode }}
        {{- $_ = set $context "defaultMode" $_defaultMode }}
      {{- end }}
      {{- if $_itemsKeyword }}
        {{- $_itemPattern := $const.K8S.VOLUME.KEY_TO_PATH_ITEM }}
        {{- $items := list }}
        {{- range $_itemText := mustRegexSplit $const.SPLIT.COMMA (trim $_itemsRaw) -1 }}
          {{- $__itemText := trim $_itemText }}
          {{- if $__itemText }}
            {{- if not (mustRegexMatch $_itemPattern $__itemText) }}
              {{- fail (printf "[definitions.volume] %s: item '%s' does not match '<key> <path> [mode]'" $source $__itemText) }}
            {{- end }}
            {{- $items = mustAppend $items $__itemText }}
          {{- end }}
        {{- end }}
        {{- if not $items }}
          {{- fail (printf "[definitions.volume] %s: items must contain at least one element" $source) }}
        {{- end }}
        {{- $_ = set $context "items" $items }}
      {{- end }}

    {{- /* csi: <driver> [nodePublishSecretRef] [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]，nodePublishSecretRef 位置命中 fsType 枚举时归属 fsType。 */ -}}
    {{- else if eq $source "csi" }}
      {{- $_pattern := $const.K8S.VOLUME.CSI }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] csi: '%s' does not match '<driver> [nodePublishSecretRef] [fsType] [readOnly] [attr|volumeAttributes (key value, ...)]'" $sourceValue) }}
      {{- end }}
      {{- $_driver := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_secretRefRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_fsTypeRaw := mustRegexReplaceAll $_pattern $sourceValue "$3" | trim }}
      {{- $_readOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$4" | trim }}
      {{- $_attrKeyword := mustRegexReplaceAll $_pattern $sourceValue "$5" | trim }}
      {{- $_attrRaw := mustRegexReplaceAll $_pattern $sourceValue "$6" }}

      {{- /* 位置归属: RE2 无法在捕获时排除枚举字面量，命中 ext4/xfs/ntfs 时把该位置前移为 fsType，两个位置同时给出则中断。 */ -}}
      {{- if and $_secretRefRaw (has (lower $_secretRefRaw) (list "ext4" "xfs" "ntfs")) }}
        {{- if $_fsTypeRaw }}
          {{- fail (printf "[definitions.volume] csi: fsType is set twice, got '%s' and '%s'" $_secretRefRaw $_fsTypeRaw) }}
        {{- end }}
        {{- $_fsTypeRaw = $_secretRefRaw }}
        {{- $_secretRefRaw = "" }}
      {{- end }}

      {{- $context = dict "driver" $_driver }}
      {{- if $_secretRefRaw }}
        {{- $_ = set $context "nodePublishSecretRef" $_secretRefRaw }}
      {{- end }}
      {{- if $_fsTypeRaw }}
        {{- $_ = set $context "fsType" (lower $_fsTypeRaw) }}
      {{- end }}
      {{- if $_readOnlyRaw }}
        {{- $_ = set $context "readOnly" (include "base.bool" (lower $_readOnlyRaw)) }}
      {{- end }}
      {{- if $_attrKeyword }}
        {{- $_attrPattern := $const.K8S.VOLUME.CSI_ATTRIBUTE }}
        {{- $attributes := dict }}
        {{- range $_attrText := mustRegexSplit $const.SPLIT.COMMA (trim $_attrRaw) -1 }}
          {{- $__attrText := trim $_attrText }}
          {{- if $__attrText }}
            {{- if not (mustRegexMatch $_attrPattern $__attrText) }}
              {{- fail (printf "[definitions.volume] csi: attribute '%s' does not match '<key> <value>'" $__attrText) }}
            {{- end }}
            {{- $_attrKey := mustRegexReplaceAll $_attrPattern $__attrText "$1" | trim }}
            {{- $_attrValue := mustRegexReplaceAll $_attrPattern $__attrText "$2" | trim }}
            {{- if not $_attrValue }}
              {{- fail (printf "[definitions.volume] csi: attribute '%s' is missing a value" $__attrText) }}
            {{- end }}
            {{- $_ = set $attributes $_attrKey $_attrValue }}
          {{- end }}
        {{- end }}
        {{- if not $attributes }}
          {{- fail "[definitions.volume] csi: volumeAttributes must contain at least one element" }}
        {{- end }}
        {{- $_ = set $context "volumeAttributes" $attributes }}
      {{- end }}

    {{- /* downwardAPI: [defaultMode] [items (<item>, ...)]，item 支持 field 与 resource 两种形态。 */ -}}
    {{- else if eq $source "downwardAPI" }}
      {{- $_pattern := $const.K8S.VOLUME.DOWNWARD_API }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] downwardAPI: '%s' does not match '[defaultMode] [items (<item>, ...)]'" $sourceValue) }}
      {{- end }}
      {{- $_defaultMode := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_itemsKeyword := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_itemsRaw := mustRegexReplaceAll $_pattern $sourceValue "$3" }}
      {{- $_itemsOnlyKeyword := mustRegexReplaceAll $_pattern $sourceValue "$4" | trim }}
      {{- $_itemsOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$5" }}

      {{- $context = dict }}
      {{- if $_defaultMode }}
        {{- $_ = set $context "defaultMode" $_defaultMode }}
      {{- end }}
      {{- if or $_itemsKeyword $_itemsOnlyKeyword }}
        {{- $_itemsContent := $_itemsRaw }}
        {{- if $_itemsOnlyKeyword }}
          {{- $_itemsContent = $_itemsOnlyRaw }}
        {{- end }}
        {{- $items := list }}
        {{- range $_itemText := mustRegexSplit $const.SPLIT.COMMA (trim $_itemsContent) -1 }}
          {{- $__itemText := trim $_itemText }}
          {{- if $__itemText }}
            {{- if not (or (mustRegexMatch $const.K8S.VOLUME.DOWNWARD_API_FIELD_ITEM $__itemText) (mustRegexMatch $const.K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM $__itemText)) }}
              {{- fail (printf "[definitions.volume] downwardAPI: item '%s' does not match '<path> [mode] field <fieldPath> [apiVersion]' or '<path> [mode] resource <resource> [containerName] [divisor]'" $__itemText) }}
            {{- end }}
            {{- $items = mustAppend $items $__itemText }}
          {{- end }}
        {{- end }}
        {{- if not $items }}
          {{- fail "[definitions.volume] downwardAPI: items must contain at least one element" }}
        {{- end }}
        {{- $_ = set $context "items" $items }}
      {{- end }}

    {{- /* emptyDir: [medium] [sizeLimit]。 */ -}}
    {{- else if eq $source "emptyDir" }}
      {{- $_pattern := $const.K8S.VOLUME.EMPTY_DIR }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] emptyDir: '%s' does not match '[medium] [sizeLimit]'" $sourceValue) }}
      {{- end }}
      {{- $_mediumRaw := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_sizeLimitRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}

      {{- $context = dict }}
      {{- if $_mediumRaw }}
        {{- $_ = set $context "medium" "Memory" }}
      {{- end }}
      {{- if $_sizeLimitRaw }}
        {{- $_sizeLimit := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_sizeLimitRaw "$1" | trim }}
        {{- if $_sizeLimit }}
          {{- $_ = set $context "sizeLimit" (include "base.quantity" $_sizeLimit) }}
        {{- end }}
      {{- end }}

    {{- /* fc: [lun] <fsType> [readOnly] [targetWWNs (<value>, ...)] [wwids (<value>, ...)]。
       lun 仅在 targetWWNs 出现时以原生整数写入上下文；targetWWNs 缺 lun 时由 definitions.fcVolumeSource 中断；
       wwids 分支忽略 lun；两组共存时由子模板按 targetWWNs 优先抑制 wwids。 */ -}}
    {{- else if eq $source "fc" }}
      {{- $_pattern := $const.K8S.VOLUME.FC }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] fc: '%s' does not match '[lun] <fsType> [readOnly] [targetWWNs (<value>, ...)] [wwids (<value>, ...)]'" $sourceValue) }}
      {{- end }}
      {{- $_lunRaw := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_fsTypeRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_readOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$3" | trim }}
      {{- $_targetKeyword := mustRegexReplaceAll $_pattern $sourceValue "$4" | trim }}
      {{- $_targetRaw := mustRegexReplaceAll $_pattern $sourceValue "$5" }}
      {{- $_wwidsKeyword := mustRegexReplaceAll $_pattern $sourceValue "$6" | trim }}
      {{- $_wwidsRaw := mustRegexReplaceAll $_pattern $sourceValue "$7" }}

      {{- $context = dict "fsType" (lower $_fsTypeRaw) }}
      {{- if $_lunRaw }}
        {{- $_lun := int (include "base.int.positive" $_lunRaw) }}
        {{- if $_targetKeyword }}
          {{- $_ = set $context "lun" $_lun }}
        {{- end }}
      {{- end }}
      {{- if $_readOnlyRaw }}
        {{- $_ = set $context "readOnly" (include "base.bool" (lower $_readOnlyRaw)) }}
      {{- end }}
      {{- if $_targetKeyword }}
        {{- $targets := list }}
        {{- range $_target := mustRegexSplit $const.SPLIT.COMMA (trim $_targetRaw) -1 }}
          {{- $__target := trim $_target }}
          {{- if $__target }}
            {{- $targets = mustAppend $targets $__target }}
          {{- end }}
        {{- end }}
        {{- if not $targets }}
          {{- fail "[definitions.volume] fc: targetWWNs must contain at least one element" }}
        {{- end }}
        {{- $_ = set $context "targetWWNs" $targets }}
      {{- end }}
      {{- if $_wwidsKeyword }}
        {{- $wwids := list }}
        {{- range $_wwid := mustRegexSplit $const.SPLIT.COMMA (trim $_wwidsRaw) -1 }}
          {{- $__wwid := trim $_wwid }}
          {{- if $__wwid }}
            {{- $wwids = mustAppend $wwids $__wwid }}
          {{- end }}
        {{- end }}
        {{- if not $wwids }}
          {{- fail "[definitions.volume] fc: wwids must contain at least one element" }}
        {{- end }}
        {{- $_ = set $context "wwids" $wwids }}
      {{- end }}
      {{- if and (not $_targetKeyword) (not $_wwidsKeyword) }}
        {{- fail "[definitions.volume] fc: targetWWNs or wwids is required" }}
      {{- end }}

    {{- /* hostPath: <path> [type]，type 允许显式空字符串。 */ -}}
    {{- else if eq $source "hostPath" }}
      {{- $_pattern := $const.K8S.VOLUME.HOST_PATH }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] hostPath: '%s' does not match '<path> [type]'" $sourceValue) }}
      {{- end }}
      {{- $_path := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_typeRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}

      {{- $context = dict "path" $_path }}
      {{- if $_typeRaw }}
        {{- $_type := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_typeRaw "$1" | trim }}
        {{- if $_type }}
          {{- $types := dict "blockdevice" "BlockDevice" "chardevice" "CharDevice" "directory" "Directory" "directoryorcreate" "DirectoryOrCreate" "file" "File" "fileorcreate" "FileOrCreate" "socket" "Socket" }}
          {{- $_canonicalType := get $types (lower $_type) }}
          {{- if not $_canonicalType }}
            {{- fail (printf "[definitions.volume] hostPath: type '%s' is not one of \"\", BlockDevice, CharDevice, Directory, DirectoryOrCreate, File, FileOrCreate, Socket" $_type) }}
          {{- end }}
          {{- $_ = set $context "type" $_canonicalType }}
        {{- else }}
          {{- $_ = set $context "type" "" }}
        {{- end }}
      {{- end }}

    {{- /* image: <reference> [pullPolicy]。 */ -}}
    {{- else if eq $source "image" }}
      {{- $_pattern := $const.K8S.VOLUME.IMAGE }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] image: '%s' does not match '<reference> [pullPolicy]'" $sourceValue) }}
      {{- end }}
      {{- $_reference := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_pullPolicyRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}

      {{- $context = dict "reference" $_reference }}
      {{- if $_pullPolicyRaw }}
        {{- $_ = set $context "pullPolicy" (get (dict "always" "Always" "ifnotpresent" "IfNotPresent" "never" "Never") (lower $_pullPolicyRaw)) }}
      {{- end }}

    {{- /* iscsi: <iqn> <lun> [targetPortal] [fsType] [readOnly] [iscsiInterface] [initiatorName] [chap (...)] [portals (...)] [secretRef.name]。 */ -}}
    {{- else if eq $source "iscsi" }}
      {{- $_pattern := $const.K8S.VOLUME.ISCSI }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] iscsi: '%s' does not match '<iqn> <lun> [targetPortal] [fsType] [readOnly] [iscsiInterface] [initiatorName] [chap (<chapAuthDiscovery>, <chapAuthSession>)] [portals (<ip>, ...)] [secretRef.name]'" $sourceValue) }}
      {{- end }}
      {{- $_iqn := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_lunRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_targetPortalRaw := mustRegexReplaceAll $_pattern $sourceValue "$3" | trim }}
      {{- $_fsTypeRaw := mustRegexReplaceAll $_pattern $sourceValue "$4" | trim }}
      {{- $_readOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$5" | trim }}
      {{- $_iscsiInterfaceRaw := mustRegexReplaceAll $_pattern $sourceValue "$6" | trim }}
      {{- $_initiatorNameRaw := mustRegexReplaceAll $_pattern $sourceValue "$7" | trim }}
      {{- $_chapKeyword := mustRegexReplaceAll $_pattern $sourceValue "$8" | trim }}
      {{- $_chapDiscoveryRaw := mustRegexReplaceAll $_pattern $sourceValue "$9" | trim }}
      {{- $_chapSessionRaw := mustRegexReplaceAll $_pattern $sourceValue "$10" | trim }}
      {{- $_portalsKeyword := mustRegexReplaceAll $_pattern $sourceValue "$11" | trim }}
      {{- $_portalsRaw := mustRegexReplaceAll $_pattern $sourceValue "$12" }}
      {{- $_secretRefRaw := mustRegexReplaceAll $_pattern $sourceValue "$13" | trim }}

      {{- $context = dict "iqn" $_iqn "lun" (include "base.int.positive" $_lunRaw) }}

      {{- $_targetPortal := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_targetPortalRaw "$1" | trim }}
      {{- if $_targetPortal }}
        {{- if not (mustRegexMatch $const.K8S.VOLUME.ISCSI_PORTAL $_targetPortal) }}
          {{- fail (printf "[definitions.volume] iscsi: targetPortal '%s' must be an IPv4 address or port number, optionally with ':port'" $_targetPortal) }}
        {{- end }}
        {{- $_ = set $context "targetPortal" $_targetPortal }}
      {{- end }}

      {{- $_fsType := lower (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_fsTypeRaw "$1" | trim) }}
      {{- if $_fsType }}
        {{- if not (has $_fsType (list "ext4" "xfs" "ntfs")) }}
          {{- fail (printf "[definitions.volume] iscsi: fsType '%s' is not one of ext4, xfs, ntfs" $_fsType) }}
        {{- end }}
        {{- $_ = set $context "fsType" $_fsType }}
      {{- end }}

      {{- $_readOnly := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_readOnlyRaw "$1" | trim }}
      {{- if $_readOnly }}
        {{- $_ = set $context "readOnly" (include "base.bool" (lower $_readOnly)) }}
      {{- end }}

      {{- $_iscsiInterface := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_iscsiInterfaceRaw "$1" | trim }}
      {{- if $_iscsiInterface }}
        {{- $_ = set $context "iscsiInterface" $_iscsiInterface }}
      {{- end }}

      {{- $_initiatorName := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_initiatorNameRaw "$1" | trim }}
      {{- if $_initiatorName }}
        {{- $_ = set $context "initiatorName" $_initiatorName }}
      {{- end }}

      {{- if $_chapKeyword }}
        {{- $_chapDiscovery := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_chapDiscoveryRaw "$1" | trim }}
        {{- $_chapSession := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_chapSessionRaw "$1" | trim }}
        {{- if or (not $_chapDiscovery) (not $_chapSession) }}
          {{- fail "[definitions.volume] iscsi: chap requires both chapAuthDiscovery and chapAuthSession values" }}
        {{- end }}
        {{- $_ = set $context "chapAuthDiscovery" (include "base.bool" (lower $_chapDiscovery)) }}
        {{- $_ = set $context "chapAuthSession" (include "base.bool" (lower $_chapSession)) }}
      {{- end }}

      {{- if $_portalsKeyword }}
        {{- $portals := list }}
        {{- range $_portal := mustRegexSplit $const.SPLIT.COMMA (trim $_portalsRaw) -1 }}
          {{- $__portal := trim $_portal }}
          {{- if $__portal }}
            {{- if not (mustRegexMatch $const.K8S.VOLUME.ISCSI_PORTAL $__portal) }}
              {{- fail (printf "[definitions.volume] iscsi: portal '%s' must be an IPv4 address or port number, optionally with ':port'" $__portal) }}
            {{- end }}
            {{- $portals = mustAppend $portals $__portal }}
          {{- end }}
        {{- end }}
        {{- if not $portals }}
          {{- fail "[definitions.volume] iscsi: portals must contain at least one element" }}
        {{- end }}
        {{- $_ = set $context "portals" $portals }}
      {{- end }}

      {{- if $_secretRefRaw }}
        {{- $_ = set $context "secretRef" $_secretRefRaw }}
      {{- end }}

    {{- /* nfs: <server> <path> [readOnly]。 */ -}}
    {{- else if eq $source "nfs" }}
      {{- $_pattern := $const.K8S.VOLUME.NFS }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] nfs: '%s' does not match '<server> <path> [readOnly]'" $sourceValue) }}
      {{- end }}
      {{- $_server := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_path := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}
      {{- $_readOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$3" | trim }}

      {{- $context = dict "server" (include "base.net" (list $_server "dns")) "path" $_path }}
      {{- if $_readOnlyRaw }}
        {{- $_ = set $context "readOnly" (include "base.bool" (lower $_readOnlyRaw)) }}
      {{- end }}

    {{- /* persistentVolumeClaim: <claimName> [readOnly]。 */ -}}
    {{- else if eq $source "persistentVolumeClaim" }}
      {{- $_pattern := $const.K8S.VOLUME.PERSISTENT_VOLUME_CLAIM }}
      {{- if not (mustRegexMatch $_pattern $sourceValue) }}
        {{- fail (printf "[definitions.volume] persistentVolumeClaim: '%s' does not match '<claimName> [readOnly]'" $sourceValue) }}
      {{- end }}
      {{- $_claimName := mustRegexReplaceAll $_pattern $sourceValue "$1" | trim }}
      {{- $_readOnlyRaw := mustRegexReplaceAll $_pattern $sourceValue "$2" | trim }}

      {{- $context = dict "claimName" $_claimName }}
      {{- if $_readOnlyRaw }}
        {{- $_ = set $context "readOnly" (include "base.bool" (lower $_readOnlyRaw)) }}
      {{- end }}
    {{- end }}

  {{- else if eq (kindOf $sourceValue) "invalid" }}
    {{- $context = dict }}

  {{- else }}
    {{- fail (printf "[definitions.volume] %s: must be object, string, or empty type, got '%s'" $source (kindOf $sourceValue)) }}
  {{- end }}

  {{- /* 字段渲染: 按 API 顺序输出 name 与唯一 source；子模板输出按 map 契约处理。 */ -}}
  {{- range $_field := $fields }}
    {{- if eq $_field "name" }}
      {{- include "base.field" (list "name" $name "quote") }}
    {{- else if eq $_field $source }}
      {{- $_rendered := include (printf "definitions.%sVolumeSource" $_field) $context }}
      {{- $_wrapped := printf "body:\n%s" (indent 2 $_rendered) | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_wrapped) "true" }}
        {{- fail (printf "[definitions.volume] %s: rendered source is not valid YAML" $_field) }}
      {{- end }}
      {{- $_body := index $_wrapped "body" }}
      {{- if not (kindIs "map" $_body) }}
        {{- $_body = dict }}
      {{- end }}
      {{- include "base.field" (list $_field $_body "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
