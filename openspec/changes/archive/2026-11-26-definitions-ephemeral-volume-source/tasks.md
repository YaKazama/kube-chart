# `definitions.ephemeralVolumeSource` 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_EphemeralVolumeSource.tpl`：新增 `definitions.ephemeralVolumeSource`，实现 `base.get` 取值、必填非空校验、子模板调用与条件渲染；对应 `Decision: base.get 取值与必填非空校验` 与 `Decision: 子模板委托与条件输出`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 隔离 Chart：同名 fixture 返回非空内容时输出 `volumeClaimTemplate`；返回空内容时不输出该字段且不报错；未声明键被忽略；对应 `Requirement: 子模板委托与字段输出` 与 `Requirement: 原生 map 上下文与字段范围`。
- [x] V2 `/tmp/sd-kube-chart/` 隔离 Chart：缺失、null、空 map、无法恢复为 map 的字符串与列表输入均中断，消息包含 `[definitions.ephemeralVolumeSource] volumeClaimTemplate`；对应 `Requirement: volumeClaimTemplate 必填且可恢复为非空 map`。
