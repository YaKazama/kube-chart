{{- define "definitions.Lifecycle" -}}
  {{- /* postStart map */ -}}
  {{- $postStartVal := include "base.getValue" (list . "postStart") | fromYaml }}
  {{- $postStart := include "definitions.LifecycleHandler" $postStartVal | fromYaml }}
  {{- if $postStart }}
    {{- include "base.field" (list "postStart" $postStart "base.map") }}
  {{- end }}

  {{- /* preStop map */ -}}
  {{- $preStopVal := include "base.getValue" (list . "preStop") | fromYaml }}
  {{- $preStop := include "definitions.LifecycleHandler" $preStopVal | fromYaml }}
  {{- if $preStop }}
    {{- include "base.field" (list "preStop" $preStop "base.map") }}
  {{- end }}

  {{- /* stopSignal string */ -}}
  {{- $stopSignal := include "base.getValue" (list . "stopSignal") }}
  {{- $stopSignalAllows := list "SIGABRT" "SIGALRM" "SIGBUS" "SIGCHLD" "SIGCLD" "SIGCONT" "SIGFPE" "SIGHUP" "SIGILL" "SIGINT" "SIGIO" "SIGIOT" "SIGKILL" "SIGPIPE" "SIGPOLL" "SIGPROF" "SIGPWR" "SIGQUIT" "SIGRTMAX" "SIGRTMAX-1" "SIGRTMAX-10" "SIGRTMAX-11" "SIGRTMAX-12" "SIGRTMAX-13" "SIGRTMAX-14" "SIGRTMAX-2" "SIGRTMAX-3" "SIGRTMAX-4" "SIGRTMAX-5" "SIGRTMAX-6" "SIGRTMAX-7" "SIGRTMAX-8" "SIGRTMAX-9" "SIGRTMIN" "SIGRTMIN+1" "SIGRTMIN+10" "SIGRTMIN+11" "SIGRTMIN+12" "SIGRTMIN+13" "SIGRTMIN+14" "SIGRTMIN+15" "SIGRTMIN+2" "SIGRTMIN+3" "SIGRTMIN+4" "SIGRTMIN+5" "SIGRTMIN+6" "SIGRTMIN+7" "SIGRTMIN+8" "SIGRTMIN+9" "SIGSEGV" "SIGSTKFLT" "SIGSTOP" "SIGSYS" "SIGTERM" "SIGTRAP" "SIGTSTP" "SIGTTIN" "SIGTTOU" "SIGURG" "SIGUSR1" "SIGUSR2" "SIGVTALRM" "SIGWINCH" "SIGXCPU" "SIGXFSZ" }}
  {{- if has $stopSignal $stopSignalAllows }}
    {{- include "base.field" (list "stopSignal" $stopSignal) }}
  {{- end }}
{{- end }}
