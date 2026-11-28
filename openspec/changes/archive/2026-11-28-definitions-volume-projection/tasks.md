# definitions.volumeProjection 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_VolumeProjection.tpl`：新增 `definitions.volumeProjection` 契约注释与 define，按官方字段表收集出现字段并强制恰好一个，校验字段值为非空原生 map，逐字段委托对应子模板并拒绝空输出或非法 YAML；写入范围限于该模板的契约注释与 define 块；对应 `Decision: 以字段表收集出现字段并强制恰好一个`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart，使用六个同名子模板 fixture：`{configMap: {name: "cfg"}}` 输出以 `configMap` 为键的 map 片段。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart，使用六个同名 fixture：六个官方字段分别单独输入时，输出对应字段键并调用各自子模板。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：无字段、两个及以上字段同时出现、字段为空 map、字段为 null、字段为 string 时均中断并报错。
- [x] V4 `/tmp/sd-kube-chart/` 最小 Chart，使用返回空内容与非法 YAML 的 fixture：单字段输入时均中断并报错。
