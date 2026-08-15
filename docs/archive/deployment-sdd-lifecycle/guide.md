# Deployment 调用说明草案

## 适用范围

- 本文是静态实现说明草案，尚未通过 Helm 端到端验证与 Review，不是正式用户指南。
- 适用于将 library Chart 作为父 Chart 依赖后调用 `apps.deployment` 的场景。

## 调用方式

```gotemplate
{{- $ctx := mustMergeOverwrite (mustDeepCopy .) (dict "Context" .Values.deployment) -}}
{{- include "apps.deployment" $ctx }}
```

- 模板固定输出 `apps/v1` 与 `Deployment`。
- 父 Chart 负责提供满足下层 metadata、selector 和 PodTemplateSpec 实际依赖的上下文。

## Strategy 简写

```yaml
deployment:
  strategy: "RollingUpdate 25% 0"
```

- 该字符串在匹配当前正则时会规整为 RollingUpdate 配置。
- `Recreate` 时忽略 rollingUpdate。
- maxSurge 与 maxUnavailable 同为 `0` 或 `0%` 时会失败。
- 不匹配的 strategy 简写字符串当前会被省略，不会产生 strategy 块。

## 当前限制

- `deployment.template` 子字段当前未被 `apps.deploymentSpec` 独立读取；PodTemplateSpec 使用完整根上下文。
- 当前没有已验证的 parent Chart 渲染样例，不能将本说明作为可直接部署的配置参考。
- 正式指南应在完成 Helm 验证、Review、正式 SDD 与已验证样例后生成。
