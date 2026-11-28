---
change-id: definitions-projected-volume-source
updated_at: "2026-11-28T08:03:56Z"
---

# definitions.projectedVolumeSource

## 目标

- 新增 `definitions.projectedVolumeSource`，渲染 Kubernetes `ProjectedVolumeSource` 字段片段，供 `definitions.volume` 的 `projected` 键委托使用。

## 需求

- 上下文是原生 map。
- 字段按官方定义，仅 `defaultMode` 与 `sources`。
- 按官方定义顺序渲染：`defaultMode`、`sources`。
- 条目字段按官方定义。
- `defaultMode` 与 `sources` 均可选。
- `defaultMode` 或 `sources` 为空时不渲染对应键；非法输入中断报错。
- `sources` 逐项委托子模板 `definitions.volumeProjection`；该子模板为占位，本 change 不创建。
- `sources` 元素为原生 map，不接受 string 简写。
- `sources` 回收的内容去重、去空，由 Helm 内置函数处理；完全相同的结果保留首个。
- `defaultMode` 沿用既有 VolumeSource 的 mode 输入形态与十进制归一化输出规则。

## 非目标

- 不创建 `definitions.volumeProjection`。
- 不修改 `definitions.volume` 对 `projected` 的既有委托关系。

## 验收

- 同时提供 `defaultMode` 与 `sources` 时，输出顺序为先 `defaultMode` 后 `sources`，键名与官方定义一致。
- `defaultMode` 或 `sources` 缺省、为空时，模板正常渲染且不输出对应键。
- `sources` 的每个有效条目经 `definitions.volumeProjection` 渲染后回收；空结果被剔除，完全相同的结果只保留一个；全部被剔除时不输出 `sources`。
- 非法 `defaultMode` 或 `sources` 输入中断并报错。

## 开放问题

- 无。
