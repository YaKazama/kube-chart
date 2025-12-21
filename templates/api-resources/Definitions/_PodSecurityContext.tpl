{{- define "definitions.PodSecurityContext" -}}
  {{- $os := include "base.getValue" (list . "os") }}

  {{- /* appArmorProfile map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $appArmorProfileVal := include "base.getValue" (list . "appArmorProfile") | fromYaml }}
    {{- if $appArmorProfileVal }}
      {{- $val := pick $appArmorProfileVal "localhostProfile" "type" }}
      {{- $appArmorProfile := include "definitions.AppArmorProfile" $val | fromYaml }}
      {{- if $appArmorProfile }}
        {{- include "base.field" (list "appArmorProfile" $appArmorProfile "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* fsGroup int */ -}}
  {{- if not (eq $os "windows") }}
    {{- $fsGroup := include "base.getValue" (list . "fsGroup" "toString") }}
    {{- if $fsGroup }}
      {{- include "base.field" (list "fsGroup" $fsGroup "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* fsGroupChangePolicy string */ -}}
  {{- if not (eq $os "windows") }}
    {{- $fsGroupChangePolicy := include "base.getValue" (list . "fsGroupChangePolicy") }}
    {{- $fsGroupChangePolicyAllows := list "OnRootMismatch" "Always" }}
    {{- if $fsGroupChangePolicy }}
      {{- include "base.field" (list "fsGroupChangePolicy" $fsGroupChangePolicy "base.string" $fsGroupChangePolicyAllows) }}
    {{- end }}
  {{- end }}

  {{- /* runAsGroup int */ -}}
  {{- if not (eq $os "windows") }}
    {{- $runAsGroup := include "base.getValue" (list . "runAsGroup" "toString") }}
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
    {{- $runAsUser := include "base.getValue" (list . "runAsUser" "toString") }}
    {{- if $runAsUser }}
      {{- include "base.field" (list "runAsUser" $runAsUser "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* seLinuxChangePolicy string */ -}}
  {{- if not (eq $os "windows") }}
    {{- $seLinuxChangePolicy := include "base.getValue" (list . "seLinuxChangePolicy") }}
    {{- if $seLinuxChangePolicy }}
      {{- include "base.field" (list "seLinuxChangePolicy" $seLinuxChangePolicy) }}
    {{- end }}
  {{- end }}

  {{- /* seLinuxOptions map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $seLinuxOptionsVal := include "base.getValue" (list . "seLinuxOptions") | fromYaml }}
    {{- if $seLinuxOptionsVal }}
      {{- $val := pick $seLinuxOptionsVal "level" "role" "type" "user" }}
      {{- $seLinuxOptions := include "definitions.SELinuxOptions" $val | fromYaml }}
      {{- if $seLinuxOptions }}
        {{- include "base.field" (list "seLinuxOptions" $seLinuxOptions "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* seccompProfile map */ -}}
  {{- if not (eq $os "windows") }}
    {{- $seccompProfileVal := include "base.getValue" (list . "seccompProfile") | fromYaml }}
    {{- if $seccompProfileVal }}
      {{- $val := pick $seccompProfileVal "localhostProfile" "type" }}
      {{- $seccompProfile := include "definitions.SeccompProfile" $val | fromYaml }}
      {{- if $seccompProfile }}
        {{- include "base.field" (list "seccompProfile" $seccompProfile "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* supplementalGroups int array */ -}}
  {{- if not (eq $os "windows") }}
    {{- $supplementalGroups := include "base.getValue" (list . "supplementalGroups") | fromYamlArray }}
    {{- if $supplementalGroups }}
      {{- include "base.field" (list "supplementalGroups" $supplementalGroups "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* supplementalGroupsPolicy string */ -}}
  {{- if not (eq $os "windows") }}
    {{- $supplementalGroupsPolicy := include "base.getValue" (list . "supplementalGroupsPolicy") }}
    {{- $supplementalGroupsPolicyAllows := list "Merge" "Strict" }}
    {{- if $supplementalGroupsPolicy }}
      {{- include "base.field" (list "supplementalGroupsPolicy" $supplementalGroupsPolicy "base.string" $supplementalGroupsPolicyAllows) }}
    {{- end }}
  {{- end }}

  {{- /* sysctls array */ -}}
  {{- if not (eq $os "windows") }}
    {{- $sysctlsVal := include "base.getValue" (list . "sysctls") | fromYamlArray }}
    {{- $sysctls := list }}
    {{- range $sysctlsVal }}
      {{- $val := pick $sysctlsVal "name" "value" }}
      {{- $sysctls = append $sysctls (include "definitions.Sysctl" $val | fromYaml) }}
    {{- end }}
    {{- if $sysctls }}
      {{- include "base.field" (list "sysctls" ($sysctls | mustCompact) "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* windowsOptions map */ -}}
  {{- if eq $os "windows" }}
    {{- $windowsOptionsVal := include "base.getValue" (list . "windowsOptions") | fromYaml }}
    {{- if $windowsOptionsVal }}
      {{- $val := pick $windowsOptionsVal "gmsaCredentialSpec" "gmsaCredentialSpecName" "hostProcess" "runAsUserName" }}
      {{- $windowsOptions := include "definitions.WindowsSecurityContextOptions" $val | fromYaml }}
      {{- if $windowsOptions }}
        {{- include "base.field" (list "windowsOptions" $windowsOptions "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
