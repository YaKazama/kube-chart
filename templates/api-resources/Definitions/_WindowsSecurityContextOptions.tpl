{{- define "definitions.WindowsSecurityContextOptions" -}}
  {{- /* gmsaCredentialSpec string */ -}}
  {{- $gmsaCredentialSpec := include "base.getValue" (list . "gmsaCredentialSpec") }}
  {{- if $gmsaCredentialSpec }}
    {{- include "base.field" (list "gmsaCredentialSpec" $gmsaCredentialSpec) }}
  {{- end }}

  {{- /* gmsaCredentialSpecName string */ -}}
  {{- $gmsaCredentialSpecName := include "base.getValue" (list . "gmsaCredentialSpecName") }}
  {{- if $gmsaCredentialSpecName }}
    {{- include "base.field" (list "gmsaCredentialSpecName" $gmsaCredentialSpecName) }}
  {{- end }}

  {{- /* hostProcess bool */ -}}
  {{- $hostProcess := include "base.getValue" (list . "hostProcess") }}
  {{- if $hostProcess }}
    {{- include "base.field" (list "hostProcess" $hostProcess "base.bool") }}
  {{- end }}

  {{- /* runAsUserName string */ -}}
  {{- $runAsUserName := include "base.getValue" (list . "runAsUserName") }}
  {{- if $runAsUserName }}
    {{- include "base.field" (list "runAsUserName" $runAsUserName) }}
  {{- end }}
{{- end }}
