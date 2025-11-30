{{- define "definitions.WindowsSecurityContextOptions" -}}
  {{- /* gmsaCredentialSpec string */ -}}
  {{- $gmsaCredentialSpec := include "base.getValue" (list . "gmsaCredentialSpec") }}
  {{- include "base.field" (list "gmsaCredentialSpec" $gmsaCredentialSpec) }}

  {{- /* gmsaCredentialSpecName string */ -}}
  {{- $gmsaCredentialSpecName := include "base.getValue" (list . "gmsaCredentialSpecName") }}
  {{- include "base.field" (list "gmsaCredentialSpecName" $gmsaCredentialSpecName) }}

  {{- /* hostProcess bool */ -}}
  {{- $hostProcess := include "base.getValue" (list . "hostProcess") }}
  {{- include "base.field" (list "hostProcess" $hostProcess "base.bool") }}

  {{- /* runAsUserName string */ -}}
  {{- $runAsUserName := include "base.getValue" (list . "runAsUserName") }}
  {{- include "base.field" (list "runAsUserName" $runAsUserName) }}
{{- end }}
