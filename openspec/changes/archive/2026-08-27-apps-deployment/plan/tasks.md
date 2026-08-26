> 需求修改入口：[draft.md](../draft.md)

# Apps Deployment 实施顺序

1. 复核 `definitions.objectMeta` 与 `apps.deploymentSpec` 的外部依赖边界，确保当前 change 不创建对应占位模板或实现。
2. 在 `templates/api-resources/Apps/_Deployment.tpl` 中实现或校正 `apps.deployment` 的整体契约注释与 `_kind` 原地注入，依赖父 Chart 的可写 map 入口契约，不重复添加顶层资源入口类型门禁。
3. 按 `apiVersion`、`kind`、`metadata`、`spec` 顺序实现字段处理闭环，补齐子模板输出的空字符串、YAML 错误与类型门禁，并保留 `base.map` 对空 map 的既有渲染行为。
4. 复核命名空间、直接依赖、上下文所有权、无 `mustDeepCopy` 约束、错误格式、排版及单资源边界。
5. 执行 `/opt/homebrew/bin/helm lint .`，并使用真实 Helm 命令验证普通 map、空 map，以及两个字段子模板的空字符串、无效 YAML 与非 map 场景；同名隔离 fixture 仅放在 `/tmp/` 并在完成后清理，且不得把隔离结果记录为真实依赖集成通过。
