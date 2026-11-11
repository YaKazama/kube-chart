# definitions.resourceRequirements 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `K8S` 下新增 `RESOURCE.HUGE_PAGES_PAIR`、`RESOURCE.HUGE_PAGES_QUANTITY`、`RESOURCE.CPU` 常量；对应 `Decision: 简写回溯与占位`、`Decision: cpu 精度与换算`、`Decision: hugepages 字节换算与倍数校验`。
- [x] T2 `templates/api-resources/Definitions/_ResourceRequirements.tpl`：新增 `definitions.resourceRequirements` 与辅助模板 `definitions.resourceRequirements.field`，实现三个字段的取值、归一化、白名单、量值校验与渲染，支持 `""`、`''`、`0` 三种占位，并在整体契约注释中写入 `cat /proc/meminfo | grep -i huge`、`Hugepagesize`、`HugePages_Total` 的取值说明；对应 `Decision: 主模板与辅助模板同文件组织`、`Decision: 取值与多类型归一化`、`Decision: 简写回溯与占位`、`Decision: 双形式共用一条校验与渲染路径`、`Decision: hugepages 字节换算与倍数校验`、`Decision: claims 逐项委托`。
- [x] T3 `templates/api-resources/Core/_PodSpec.tpl`：把 `resources` 处理块改为完整透传并以 `_kind="PodSpec"` 构造子上下文委托 `definitions.resourceRequirements`；对应 `Decision: core.podSpec 透传 resources`。

## 验证

- [x] V1 `/tmp` 最小 Chart 渲染 `definitions.resourceRequirements`：原生 map 覆盖 `cpu: 0.5` → `500m`、`cpu: 0.005` → `5m`、`cpu: 1` 与 `cpu: 500m` 原样、`memory`、`ephemeral-storage`、`hugepages-2Mi: 1024Mi`，并确认扩展资源键被丢弃；对应 `limits 与 requests 的 object 形式`、`hugepages 量值约束`。
- [x] V2 `/tmp` 最小 Chart 渲染字符串简写：`"500m 512Mi 1Gi (2Mi 1024Mi)"` 全字段命中、`"" 512Mi 1Gi` 与 `'' 512Mi 1Gi` 占位跳过、`'' '' 1Gi` 连续占位、`0 512Mi 1Gi` 零值占位、尾部分段缺失；对应 `limits 与 requests 的 string 简写`。
- [x] V3 `/tmp` 最小 Chart 提供同名 `definitions.resourceClaim` fixture，覆盖 string、map 与混用 `claims`，以及委托结果全空时不输出 `claims`；对应 `claims 数组`。
- [x] V4 `/tmp` 最小 Chart 加载真实 `core.podSpec` 并提供 `definitions.container` fixture，确认 `resources` 透传、`_kind` 标记下 `claims` 忽略、`ephemeral-storage` 丢弃与 `limitsAlias` 生效；对应 `Pod 级 resources 限制`、`core.podSpec 的 resources 透传`。
- [x] V5 `/tmp` 最小 Chart 执行关键失败输入：`cpu: 1.5m`、`cpu: 0.0005`、`hugepages-2Mi: 1Gi`、`hugepages-2Mi: 3Mi`、`hugepages-2Mi: 2Mi`、`"500m 512Mi 1Gi (2Mi"`、`claims` 非数组，逐一确认渲染中断；对应 `limits 与 requests 的 object 形式`、`hugepages 量值约束`、`limits 与 requests 的 string 简写`、`claims 数组`。
