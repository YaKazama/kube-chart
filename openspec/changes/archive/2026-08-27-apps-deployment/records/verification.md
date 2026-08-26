# 验证记录

## 验证范围

- change：`apps-deployment`
- 冻结契约：`plan/spec.md` 存在，SHA-256 为 `fa464411607273bfb4d45b9fb412ec764e9c24d962acfc081c46feae3d14b188`；`plan/design.md` 存在，SHA-256 为 `fb3aec549ece5c2d0a76558c5eec8e00ed65a20433fc61d772a6e825841097c1`。两者与批准记录一致。
- 目标文件：`templates/api-resources/Apps/_Deployment.tpl`，SHA-256 为 `b487fedb4a9ba30d94ea82e14a09de42e319bc550cdc79b8e8409bf7a6a087c0`。
- 直接依赖 `definitions.objectMeta`：当前无正式 `define`，无正式文件 SHA-256；本轮使用同名隔离 fixture。
- 直接依赖 `apps.deploymentSpec`：当前无正式 `define`，无正式文件 SHA-256；本轮使用同名隔离 fixture。
- 直接依赖 `base.isFromYamlError`：位于 `templates/base/_convert.tpl`，文件 SHA-256 为 `f91ad99ac31f770487673005e1b12a6435cb46a154208749fabe3a8542071c1f`。
- 直接依赖 `base.field`：位于 `templates/base/_field.tpl`，文件 SHA-256 为 `36a4f3e19ebd688533ab0fd05dfb175d5bc8eff8a156ba51289eb4180407d432`。
- 直接依赖 `base.map`：位于 `templates/base/_types.tpl`，文件 SHA-256 为 `ea41c8275711d77456d4be1023dd4c2f92e57aff06a40d1a95e39545af292a1f`。
- 总结论：通过。

## 环境

- 验证时间：`2026-08-27T01:35:01+08:00`
- 工作目录：`/opt/kazama/gitea/user_kazama/kube-chart`
- 系统：`Darwin 25.6.0 arm64`
- Helm 命令：`/opt/homebrew/bin/helm version --short`
- Helm 退出码：`0`
- Helm 版本：`v4.2.4+g3900f43`
- Kubernetes API 目标：隔离渲染命令显式使用 `--kube-version 1.36.0`。

## 场景 `根 Chart lint`

- 命令：`/opt/homebrew/bin/helm lint .`
- 输入：当前 library Chart 及正式模板。
- 退出码：`0`
- 预期：Chart lint 通过，无模板失败。
- 实际：`1 chart(s) linted, 0 chart(s) failed`；同时输出既有 icon 建议和 `version 'v1.36.0' is not a valid SemVerV2` 警告。
- 结论：通过。

## 场景 `渲染单个 Deployment 与同一上下文`

- 命令：`/opt/homebrew/bin/helm template valid-minimal /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=valid --set initialKind=Service --show-only templates/deployment.yaml`
- 输入：可写 map，初始 `_kind=Service`；`definitions.objectMeta` 将同一上下文写入 fixture 标记，`apps.deploymentSpec` 校验该标记可见；两个 fixture 均校验 `_kind=Deployment`。
- 退出码：`0`
- 预期：只渲染一个 `apps/v1` Deployment，字段顺序为 `apiVersion`、`kind`、`metadata`、`spec`；两个子模板观察到同一上下文和被覆盖的 `_kind=Deployment`。
- 实际：输出单个 `apiVersion: "apps/v1"`、`kind: "Deployment"` 对象，包含 `metadata`、`spec`，两处 fixture 观测值均为 `Deployment`；上下文标记校验未触发失败。目标模板本身未输出 `status`、YAML 文档分隔符或其他资源。
- 结论：通过。

## 场景 `较完整有效 map`

- 命令：`/opt/homebrew/bin/helm template valid-complete /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=valid --set initialKind=StatefulSet --set replicas=3 --set image=registry.k8s.io/pause:3.10 --show-only templates/deployment.yaml`
- 输入：可写 map，初始 `_kind=StatefulSet`、`replicas=3`和容器镜像。
- 退出码：`0`
- 预期：`metadata` 与 `spec` 的非空 map 通过 `base.field` 和 `base.map` 渲染，`_kind` 被覆盖为 `Deployment`。
- 实际：输出 `metadata.name=fixture`、`spec.replicas=3`、selector、Pod template 和 container，两个 fixture 观测值均为 `Deployment`。
- 结论：通过。

## 场景 `子模板返回空 map`

- 命令：`/opt/homebrew/bin/helm template empty-maps /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=empty-maps --show-only templates/deployment.yaml`
- 输入：`metadata` 与 `spec` fixture 均返回 `{}`。
- 退出码：`0`
- 预期：两个字段均保留并渲染为 `{}`。
- 实际：输出 `metadata: {}` 和 `spec: {}` 的等价多行 YAML。
- 结论：通过。

## 场景 `必填子模板输出为空`

- 命令：`/opt/homebrew/bin/helm template metadata-empty /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=metadata-empty --show-only templates/deployment.yaml`；`/opt/homebrew/bin/helm template spec-empty /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=spec-empty --show-only templates/deployment.yaml`
- 输入：分别使 `definitions.objectMeta` 和 `apps.deploymentSpec` 返回空字符串。
- 退出码：`1`、`1`
- 预期：渲染立即失败，错误指出对应字段缺失或为空。
- 实际：分别输出 `[apps.deployment] metadata: required field is missing or empty` 和 `[apps.deployment] spec: required field is missing or empty`。
- 结论：通过。

## 场景 `子模板输出无法解析`

- 命令：`/opt/homebrew/bin/helm template metadata-invalid-yaml /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=metadata-invalid-yaml --show-only templates/deployment.yaml`；`/opt/homebrew/bin/helm template spec-invalid-yaml /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=spec-invalid-yaml --show-only templates/deployment.yaml`
- 输入：分别使 `metadata` 和 `spec` fixture 返回无效 YAML `[` 。
- 退出码：`1`、`1`
- 预期：渲染立即失败，错误指出对应子模板输出不是有效 YAML。
- 实际：分别输出 `[apps.deployment] metadata: invalid YAML output from definitions.objectMeta` 和 `[apps.deployment] spec: invalid YAML output from apps.deploymentSpec`。
- 结论：通过。

## 场景 `子模板输出类型非法`

- 命令：`/opt/homebrew/bin/helm template metadata-non-map /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=metadata-non-map --show-only templates/deployment.yaml`；`/opt/homebrew/bin/helm template spec-non-map /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=spec-non-map --show-only templates/deployment.yaml`
- 输入：分别使 `metadata` 和 `spec` fixture 返回可解析的 list YAML。
- 退出码：`1`、`1`
- 预期：渲染立即失败，错误指出对应字段必须为 map。
- 实际：分别输出 `[apps.deployment] metadata: must be map type` 和 `[apps.deployment] spec: must be map type`。
- 结论：通过。

## 场景 `依赖模板错误传播`

- 命令：`/opt/homebrew/bin/helm template metadata-fail /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=metadata-fail --show-only templates/deployment.yaml`；`/opt/homebrew/bin/helm template spec-fail /tmp/kube-chart-apps-deployment-verify.aB8pXA --kube-version 1.36.0 --set case=spec-fail --show-only templates/deployment.yaml`
- 输入：分别使 `definitions.objectMeta` 和 `apps.deploymentSpec` fixture 在执行期间直接 `fail`。
- 退出码：`1`、`1`
- 预期：Helm 传播依赖模板的原始错误。
- 实际：分别输出 `[definitions.objectMeta] fixture: failed` 和 `[apps.deploymentSpec] fixture: failed`。
- 结论：通过。

## Fixtures 与限制

- 隔离 Chart 位于 `/tmp/kube-chart-apps-deployment-verify.aB8pXA`，完成后已清理。
- 隔离 Chart 中的目标文件与 3 个已实现 `base` 依赖均由当轮正式文件复制，SHA-256 与上述正式文件逐一一致。
- 同名 fixture 文件 `templates/_fixtures.tpl` 的 SHA-256 为 `ba2627cf03805aa5d175a1a5bd5b21e97a0f83a914dbd07917f5ceb175e57b62`；调用入口 `templates/deployment.yaml` 的 SHA-256 为 `5ba1076f541a214c98785b58b2724cdf53bb250c4478eeaf08e069444cbd2e3d`。
- fixture 只提供 `definitions.objectMeta` 与 `apps.deploymentSpec` 的最小成功、空输出、无效 YAML、非 map 和直接失败边界，并通过共享标记验证两次调用观察同一上下文。
- 本记录证明 `apps.deployment` 调用方契约在隔离边界内通过，不宣称未实现的 `definitions.objectMeta` 与 `apps.deploymentSpec` 已完成真实集成。
