{{- /*
  渲染 Kubernetes Lifecycle 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - postStart (LifecycleHandler, 可选): 非空 map 时原样委托 definitions.lifecycleHandler，非空结果作为字段值输出。
    - preStop (LifecycleHandler, 可选): 同 postStart，复用同一委托逻辑。
    - stopSignal (string, 可选): 非空时要求 os.name 非空，并按 Kubernetes v1.36 官方枚举大小写敏感校验后输出。

  边界:
    - 只输出当前层字段，不输出 os、lifecycle 父键、apiVersion 或 kind；无有效内容时为空内容。
    - postStart/preStop 的 exec、httpGet、sleep、tcpSocket 及孙模板内容全部由 definitions.lifecycleHandler 处理，本模板不解析也不约束。
    - 原生 Handler map 与抽象结构均按原 map 传递，不做归一化。
    - definitions.lifecycleHandler 由外部实现，本模板只按名称调用，不创建其 define。
    - stopSignal 的适用性和枚举校验在本模板完成，不委托 Handler 或孙模板。
    - base.get 默认开启别名识别，因此 postStart、preStop、stopSignal 及 os.name 的同级别名隐式生效。
    - 失败消息使用 [definitions.lifecycle] 前缀并携带字段名；委托 base.* 和 definitions.lifecycleHandler 时保留其自身前缀。

  入参: 上下文 map，由 definitions.container 传入 Lifecycle 字段并注入同源 os，可包含:
    - postStart  (LifecycleHandler, 可选)
    - preStop    (LifecycleHandler, 可选)
    - stopSignal (string, 可选)
    - os         (PodOS, 可选) 仅用于 stopSignal 适用性校验，不参与输出

  返回值: 可嵌入 lifecycle 下的 Lifecycle YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.lifecycle" (dict "os" (dict "name" "linux") "stopSignal" "SIGTERM") }}
      // stopSignal: SIGTERM
*/ -}}
{{- define "definitions.lifecycle" -}}
  {{- /* stopSignal（string, 可选）: 先归一化；仅非空时要求 os.name 非空，输出阶段再按官方枚举校验。 */ -}}
  {{- $stopSignal := include "base.string.normalize" (include "base.get" (list . "stopSignal")) | trim }}
  {{- if $stopSignal }}
    {{- $_osName := include "base.string.normalize" (include "base.get" (list . "os.name")) | trim }}
    {{- if not $_osName }}
      {{- fail "[definitions.lifecycle] stopSignal: cannot be set when os.name is empty" }}
    {{- end }}
  {{- end }}

  {{- /* postStart、preStop（LifecycleHandler, 可选）: 非空 map 时原样委托 definitions.lifecycleHandler，回收非空结果输出。 */ -}}
  {{- range $_key := list "postStart" "preStop" }}
    {{- $_raw := include "base.get" (list $ $_key) | trim }}
    {{- if $_raw }}
      {{- $_handler := $_raw | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_handler) "true" }}
        {{- fail (printf "[definitions.lifecycle] %s: must be map type" $_key) }}
      {{- end }}
      {{- if $_handler }}
        {{- $_rendered := include "definitions.lifecycleHandler" $_handler | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail (printf "[definitions.lifecycle] %s: invalid YAML output from definitions.lifecycleHandler" $_key) }}
        {{- end }}
        {{- if $_rendered }}
          {{- include "base.field" (list $_key $_rendered "base.map") }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* stopSignal（string, 可选）: 非空时按 Kubernetes v1.36 官方枚举大小写敏感校验并输出。 */ -}}
  {{- if $stopSignal }}
    {{- $stopSignals := list
      "SIGABRT" "SIGALRM" "SIGBUS" "SIGCHLD" "SIGCLD" "SIGCONT" "SIGFPE" "SIGHUP" "SIGILL" "SIGINT"
      "SIGIO" "SIGIOT" "SIGKILL" "SIGPIPE" "SIGPOLL" "SIGPROF" "SIGPWR" "SIGQUIT" "SIGRTMAX"
      "SIGRTMAX-1" "SIGRTMAX-10" "SIGRTMAX-11" "SIGRTMAX-12" "SIGRTMAX-13" "SIGRTMAX-14"
      "SIGRTMAX-2" "SIGRTMAX-3" "SIGRTMAX-4" "SIGRTMAX-5" "SIGRTMAX-6" "SIGRTMAX-7" "SIGRTMAX-8" "SIGRTMAX-9"
      "SIGRTMIN" "SIGRTMIN+1" "SIGRTMIN+10" "SIGRTMIN+11" "SIGRTMIN+12" "SIGRTMIN+13" "SIGRTMIN+14"
      "SIGRTMIN+15" "SIGRTMIN+2" "SIGRTMIN+3" "SIGRTMIN+4" "SIGRTMIN+5" "SIGRTMIN+6" "SIGRTMIN+7"
      "SIGRTMIN+8" "SIGRTMIN+9" "SIGSEGV" "SIGSTKFLT" "SIGSTOP" "SIGSYS" "SIGTERM" "SIGTRAP"
      "SIGTSTP" "SIGTTIN" "SIGTTOU" "SIGURG" "SIGUSR1" "SIGUSR2" "SIGVTALRM" "SIGWINCH" "SIGXCPU" "SIGXFSZ"
    }}
    {{- include "base.field" (list "stopSignal" $stopSignal "base.string" $stopSignals) }}
  {{- end }}
{{- end }}
