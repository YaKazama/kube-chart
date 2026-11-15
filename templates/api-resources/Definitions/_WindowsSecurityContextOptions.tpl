{{- /*
  渲染 Kubernetes WindowsSecurityContextOptions 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - gmsaCredentialSpec (string, 可选): 归一后非空时以带引号标量输出。
    - gmsaCredentialSpecName (string, 可选): 同 gmsaCredentialSpec。
    - hostProcess (boolean, 可选): 按 base.bool 语义校验，仅 true 时按布尔输出。
    - runAsUserName (string, 可选): 同 gmsaCredentialSpec。

  边界:
    - 只输出当前层字段，不输出 windowsOptions 父键、apiVersion 或 kind；四个字段均不生效时输出空内容。
    - 字段缺失、为 null、为空字符串或只含空白时跳过该字段；不因全部跳过而失败。
    - 字符串字段不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - hostProcess 既非布尔也不是 "true"/"false" 时由 base.bool 中断；false 视为未启用，不输出该字段。
    - 字符串字段统一以双引号输出，避免 on、yes、true 等文本在父级回收后被解析为布尔。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效。
    - 除四个字段及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可全部省略以下字段:
    - gmsaCredentialSpec     (string, 可选) GMSA 准入 webhook 内联的凭据规格内容
    - gmsaCredentialSpecName (string, 可选) 使用的 GMSA 凭据规格名称
    - hostProcess            (boolean, 可选) 是否以 Host Process 容器运行
    - runAsUserName          (string, 可选) 容器进程入口使用的 Windows 用户名

  返回值: 可嵌入 windowsOptions 下的 WindowsSecurityContextOptions YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.windowsSecurityContextOptions" (dict "gmsaCredentialSpecName" "gmsa" "hostProcess" true) }}
      // gmsaCredentialSpecName: "gmsa"
      // hostProcess: true
*/ -}}
{{- define "definitions.windowsSecurityContextOptions" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* gmsaCredentialSpec（string, 可选）: 归一后非空时以带引号标量输出。 */ -}}
  {{- $gmsaCredentialSpec := include "base.string.normalize" (include "base.get" (list . "gmsaCredentialSpec")) | trim }}
  {{- if $gmsaCredentialSpec }}
    {{- include "base.field" (list "gmsaCredentialSpec" $gmsaCredentialSpec "quote") }}
  {{- end }}

  {{- /* gmsaCredentialSpecName（string, 可选）: 归一后非空时以带引号标量输出。 */ -}}
  {{- $gmsaCredentialSpecName := include "base.string.normalize" (include "base.get" (list . "gmsaCredentialSpecName")) | trim }}
  {{- if $gmsaCredentialSpecName }}
    {{- include "base.field" (list "gmsaCredentialSpecName" $gmsaCredentialSpecName "quote") }}
  {{- end }}

  {{- /* hostProcess（boolean, 可选）: 取到值才校验，剥离 YAML 引号后由 base.bool 门禁，仅 true 输出。 */ -}}
  {{- $_hostProcessRaw := include "base.get" (list . "hostProcess") | trim }}
  {{- if $_hostProcessRaw }}
    {{- $hostProcess := include "base.bool" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_hostProcessRaw "$1" | trim) }}
    {{- if eq $hostProcess "true" }}
      {{- include "base.field" (list "hostProcess" $hostProcess "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* runAsUserName（string, 可选）: 归一后非空时以带引号标量输出。 */ -}}
  {{- $runAsUserName := include "base.string.normalize" (include "base.get" (list . "runAsUserName")) | trim }}
  {{- if $runAsUserName }}
    {{- include "base.field" (list "runAsUserName" $runAsUserName "quote") }}
  {{- end }}
{{- end }}
