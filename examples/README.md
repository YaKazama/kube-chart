# 稳定样例

本目录只保存已实现、已验证且可独立复现的稳定样例。

`apps.deployment` 的父模板契约已实现并通过隔离验证，但它的直接依赖 `definitions.objectMeta` 与 `apps.deploymentSpec` 尚未实现，因此当前不提供伪造子模板的可运行稳定样例。最小调用契约见 [`README.md`](../README.md)。
