{{- define "definitions.SecurityContext" -}}
  {{- $os := include "base.getValue" (list . "os") }}

  {{- /* allowPrivilegeEscalation bool */ -}}
  {{- if not (eq $os "windows") }}
    {{- $allowPrivilegeEscalation := include "base.getValue" (list . "allowPrivilegeEscalation") }}
    {{- if $allowPrivilegeEscalation }}
      {{- include "base.field" (list "allowPrivilegeEscalation" $allowPrivilegeEscalation "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* appArmorProfile map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $appArmorProfileVal := include "base.getValue" (list . "appArmorProfile") | fromYaml }}
    {{- if $appArmorProfileVal }}
      {{- $appArmorProfile := include "definitions.AppArmorProfile" $appArmorProfileVal | fromYaml }}
      {{- if $appArmorProfile }}
        {{- include "base.field" (list "appArmorProfile" $appArmorProfile "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* capabilities map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $capabilitiesVal := include "base.getValue" (list . "capabilities") | fromYaml }}
    {{- if $capabilitiesVal }}
      {{- $capabilities := include "definitions.Capabilities" $capabilitiesVal | fromYaml }}
      {{- if $capabilities }}
        {{- include "base.field" (list "capabilities" $capabilities "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* privileged bool */ -}}
  {{- if not (eq $os "windows") }}
    {{- $privileged := include "base.getValue" (list . "privileged") }}
    {{- if $privileged }}
      {{- include "base.field" (list "privileged" $privileged "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* procMount string */ -}}
  {{- if not (eq $os "windows") }}
    {{- $procMount := include "base.getValue" (list . "procMount") }}
    {{- $procMountAllows := list "Default" "Unmasked" }}
    {{- if $procMount }}
      {{- include "base.field" (list "procMount" $procMount "base.string" $procMountAllows) }}
    {{- end }}
  {{- end }}

  {{- /* readOnlyRootFilesystem bool */ -}}
  {{- if not (eq $os "windows") }}
    {{- $readOnlyRootFilesystem := include "base.getValue" (list . "readOnlyRootFilesystem") }}
    {{- if $readOnlyRootFilesystem }}
      {{- include "base.field" (list "readOnlyRootFilesystem" $readOnlyRootFilesystem "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* runAsGroup int */ -}}
  {{- if not (eq $os "windows") }}
    {{- $runAsGroup := include "base.getValue" (list . "runAsGroup") }}
    {{- if $runAsGroup }}
      {{- include "base.field" (list "runAsGroup" $runAsGroup "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* runAsNonRoot bool */ -}}
  {{- $runAsNonRoot := include "base.getValue" (list . "runAsNonRoot") }}
  {{- if $runAsNonRoot }}
    {{- include "base.field" (list "runAsNonRoot" $runAsNonRoot "base.bool") }}
  {{- end }}

  {{- /* runAsUser int */ -}}
  {{- if not (eq $os "windows") }}
    {{- $runAsUser := include "base.getValue" (list . "runAsUser") }}
    {{- if $runAsUser }}
      {{- include "base.field" (list "runAsUser" $runAsUser "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* seLinuxOptions map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $seLinuxOptionsVal := include "base.getValue" (list . "seLinuxOptions") | fromYaml }}
    {{- if $seLinuxOptionsVal }}
      {{- $seLinuxOptions := include "definitions.SELinuxOptions" $seLinuxOptionsVal | fromYaml }}
      {{- if $seLinuxOptions }}
        {{- include "base.field" (list "seLinuxOptions" $seLinuxOptions "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* seccompProfile map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $seccompProfileVal := include "base.getValue" (list . "seccompProfile") | fromYaml }}
    {{- if $seccompProfileVal }}
      {{- $seccompProfile := include "definitions.SeccompProfile" $seccompProfileVal | fromYaml }}
      {{- if $seccompProfile }}
        {{- include "base.field" (list "seccompProfile" $seccompProfile "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* windowsOptions map */ -}}
  {{- if eq $os "windows" }}
    {{- $windowsOptionsVal := include "base.getValue" (list . "windowsOptions") | fromYaml }}
    {{- if $windowsOptionsVal }}
      {{- $windowsOptions := include "definitions.WindowsSecurityContextOptions" $windowsOptionsVal | fromYaml }}
      {{- if $windowsOptions }}
        {{- include "base.field" (list "windowsOptions" $windowsOptions "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
