{{- /*
  渲染 Kubernetes NFSVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - path     (string, 必填): 解码后 trim 判空，经绝对路径归一化后以带引号标量输出。
    - readOnly (boolean, 可选): 剥离 YAML 引号并 trim；空值跳过，非空时按 boolean 校验并输出小写。
    - server   (string, 必填): 解码后 trim 判空，经 IP/hostname 校验，以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 nfs 父键、apiVersion 或 kind；path 与 server 必输出。
    - 上下文可为原生 map 或父模板清洗后的 map，两种形态按同一契约渲染。
    - map 只读取 path、readOnly 与 server，未声明的键静默忽略；base.get 默认开启别名，因此 pathAlias、readOnlyAlias、serverAlias 隐式生效。
    - path 与 server 只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - path 的绝对路径归一化由 base.path 中断；server 的格式校验由 base.net 中断；readOnly 的类型校验由 base.bool 中断。
    - 本模板自身产生的失败消息使用 [definitions.nfsVolumeSource] 前缀并带字段名；委托 base.* 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - path     (string, 必填)  NFS 服务器导出的绝对路径
    - readOnly (boolean, 可选) 是否以只读权限挂载
    - server   (string, 必填)  NFS 服务器主机名或 IP 地址

  返回值: 可嵌入 Volume.nfs 位置的 NFSVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.nfsVolumeSource" (dict "server" "10.0.0.1" "path" "/data") }}
      // path: "/data"
      // server: "10.0.0.1"
    {{- include "definitions.nfsVolumeSource" (dict "server" "nfs.example.com" "path" "/data" "readOnly" true) }}
      // path: "/data"
      // readOnly: true
      // server: "nfs.example.com"
*/ -}}
{{- define "definitions.nfsVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* path（string, 必填）: 解码后 trim 判空，经 abs 模式归一化后以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.nfsVolumeSource] path: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "path" (include "base.path" (list $path "abs")) "quote") }}

  {{- /* readOnly（boolean, 可选）: 剥离 YAML 引号并 trim；空值跳过，非空时按 boolean 校验并输出小写。 */ -}}
  {{- $_readOnlyRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "readOnly") | trim) "$1" | trim }}
  {{- if $_readOnlyRaw }}
    {{- include "base.field" (list "readOnly" (include "base.bool" (lower $_readOnlyRaw)) "base.bool") }}
  {{- end }}

  {{- /* server（string, 必填）: 解码后 trim 判空，经 dns 模式校验，以带引号标量输出。 */ -}}
  {{- $server := include "base.string.normalize" (include "base.get" (list . "server")) | trim }}
  {{- if not $server }}
    {{- fail "[definitions.nfsVolumeSource] server: required field is missing or empty" }}
  {{- end }}
  {{- $_ := include "base.net" (list $server "dns") }}
  {{- include "base.field" (list "server" $server "quote") }}
{{- end }}
