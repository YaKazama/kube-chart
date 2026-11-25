# `definitions.persistentVolumeClaimTemplate` 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PersistentVolumeClaimTemplate.tpl`（writable scope：该 define 的契约注释与正文）：新增 `definitions.persistentVolumeClaimTemplate`，实现 map 入口门禁、`metadata` 与 `spec` 取值恢复、`metadata` 委托 `definitions.objectMeta`、`spec` 必填并委托 `core.persistentVolumeClaimSpec`、字段渲染与失败消息；对应 `上下文与字段取值`、`metadata 委托`、`spec 委托与必填`、`输出形态`、`失败消息`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效与较完整有效场景：加载真实 `definitions.objectMeta` 与 `spec` 同名 fixture 后执行 `helm template`，渲染出预期的 `metadata` 与 `spec`，无父键、`---` 或控制字段。
- [x] V2 `/tmp/sd-kube-chart/` 空值与必填场景：加载真实 `definitions.objectMeta` 与 `spec` 同名 fixture 后执行 `helm template`，缺失或为空的 `metadata` 只输出 `spec`；`spec` 缺失、为空、子模板返回空内容时中断。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败场景：非 map 上下文、非法 `metadata` 与 `spec`、子模板返回非法 YAML 均中断并给出预期前缀；fixture 边界明确标注不证明真实依赖集成。
