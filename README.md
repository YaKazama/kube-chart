# kube-chart

`kube-chart` 是面向 Kubernetes `>= 1.36.0` 的 Helm library Chart，使用 Helm `>= 4.0.0`。它通过命名模板为父 Chart 提供可组合的 Kubernetes 资源渲染能力。

## 安装或导入

将本 Chart 作为父 Chart 的 dependency 导入。使用本地目录时，父 Chart 的 `Chart.yaml` 可声明：

```yaml
dependencies:
  - name: kube-chart
    version: "v1.36.0"
    repository: "file://../kube-chart"
```

然后在父 Chart 目录执行 `helm dependency update`。发布到 Chart 仓库后，将 `repository` 替换为实际仓库地址。

## 核心原则

- 父 Chart 负责构造可写的局部 map 上下文和跨资源编排。
- library Chart 命名模板每次只渲染单个资源，不输出 Helm Hooks 或跨资源组合。
- 结构子模板返回 YAML 字符串；调用方负责解析、错误保护和类型检查。
- 必填缺失、YAML 无法解析或类型非法时尽早终止渲染。

## 可用模板

| 命名模板 | 作用 | 直接依赖 | 当前集成状态 |
|---|---|---|---|
| `apps.deployment` | 渲染单个 `apps/v1` Deployment | `definitions.objectMeta`、`apps.deploymentSpec` | 父模板契约已实现并隔离验证；两个子模板尚未实现，暂无真实集成。 |

当前行为契约见 [`openspec/specs/apps-deployment/spec.md`](openspec/specs/apps-deployment/spec.md)，模板实现见 [`templates/api-resources/Apps/_Deployment.tpl`](templates/api-resources/Apps/_Deployment.tpl)。

## 最小示例

`apps.deployment` 的最小调用形式如下：

```gotemplate
{{- $ctx := dict "Values" .Values -}}
{{ include "apps.deployment" $ctx }}
```

父 Chart 必须传入可写 map。模板会原地将 `$ctx._kind` 设置为 `Deployment`，再把同一上下文传给 `definitions.objectMeta` 与 `apps.deploymentSpec`，不使用 `mustDeepCopy`。

> 当前仓库尚未实现 `definitions.objectMeta` 与 `apps.deploymentSpec`，因此上述调用在子模板可用前不是可独立运行的完整集成示例。

## 常见问题

### 为什么调用 `apps.deployment` 时报告找不到子模板？

`apps.deployment` 依赖 `definitions.objectMeta` 与 `apps.deploymentSpec`。当前只有父模板契约完成实现与隔离验证；必须等待两个依赖能力以独立 change 实现和验证后，才能获得仓库内的完整集成。

### 为什么调用后的上下文 `_kind` 会变化？

`apps.deployment` 拥有当前 Deployment 资源上下文，其调用契约明确原地覆盖 `_kind` 为 `Deployment`。父 Chart 应传入专用的局部 map，不应直接传入全局上下文。

## 迁移说明

`apps.deployment` 是新增命名模板，不改变已有模板契约，现有调用方无需迁移。
