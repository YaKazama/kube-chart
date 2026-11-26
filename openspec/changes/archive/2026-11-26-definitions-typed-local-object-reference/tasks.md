# definitions.typedLocalObjectReference 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_TypedLocalObjectReference.tpl`：新增 `definitions.typedLocalObjectReference`，在整体契约注释与 `define` 块内按 `apiGroup` → `kind` → `name` 顺序渲染，`apiGroup` 为空时省略且不校验，`kind` 与 `name` 由本模板前缀报必填失败；对应 `原生 map 固定顺序渲染`、`apiGroup 可省略且不校验`、`必填失败归属本模板`、`字符串标量稳定输出`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：加载真实 `base.*` 模板，仅传入 `kind` 与 `name`，`helm template` 结果为只含这两个字段且顺序为 `kind`、`name`。
- [x] V2 `/tmp/sd-kube-chart/`：传入第三方 `apiGroup`、`kind` 与 `name`，输出三字段顺序为 `apiGroup`、`kind`、`name` 且值保持输入。
- [x] V3 `/tmp/sd-kube-chart/`：空 map、`name` 仅空白、`apiGroup` 为整数三种输入均中断渲染，必填失败消息以 `[definitions.typedLocalObjectReference]` 开头。
