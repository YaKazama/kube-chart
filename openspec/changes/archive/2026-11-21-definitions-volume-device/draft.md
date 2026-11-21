---
change-id: definitions-volume-device
updated_at: "2026-11-21T15:28:14Z"
---

# 新增 definitions.volumeDevice 模板

## 目标

- 新增 `definitions.volumeDevice`，渲染单个 Kubernetes `VolumeDevice` 字段片段。
- 父模板的 `volumeDevices` 字段支持 `string array`，并将 string 归一化为本模板所需的 map。

## 需求

- 本模板上下文为原生 map 或 string。
- string 类型格式为 `<name> <devicePath>`，分隔符为空格和逗号。
- 按官方文档字段顺序渲染：`devicePath`、`name`。
- 两个字段同时为空时无输出；仅其中一个字段为空时中断报错。
- 仅由分隔符组成的 string 视为空输入。
- 去重、去空由父模板完成处理；去重使用 Helm 内置函数按渲染结果整项比较，完全重复的项被去除，其他冲突交给 Kubernetes 处理。
- `name` 字段需要做正则校验。
- `devicePath` 要求为绝对路径，使用 `base.path` 处理。
- 父模板扩展：支持 `string array`，并在向本模板传递 string 时，先拆分成符合本模板字段的 map。
- 父模板处理 `string array` 的 string 元素时，使用带捕获组的正则按位置提取 `name` 与 `devicePath`；超过 2 项时中断报错。
- 本模板直接接收 string 时，归一化结果必须与父模板拆分结果一致。
- `name` 使用 `base.rfc` 的 `1123` 模式（RFC1123 Label）校验。
- 本模板输出为可嵌入 Container 的 YAML 片段，无有效内容时为空。

## 期望输入格式

- map：`{name: <string>, devicePath: <string>}`。
- string：`"<name> <devicePath>"`，两个字段之间使用空格或逗号分隔。
- 分隔符允许连续出现和混用；解析前 trim 首尾空白。
- 仅由分隔符组成的 string 视为空输入。

## 约束

- 仅使用 Helm 内置函数、Go Template、Sprig 与 Helm 特有函数。
- 去重使用 Helm 内置函数（`mustUniq`），不按 `devicePath` 等字段自定义去重键。
- string → map 的拆分由父模板执行；归一化模板使用父模板空间命名，不使用 `definitions.volumeDevice.*`。
- 本模板直接接收 string 时复用父模板空间的归一化实现，保持结果一致。
- 保持与现有 `definitions.*` 模板一致的结构、错误前缀和输出形态。

## 非目标

- 本模板不负责去重与去空，由父模板处理。
- 不按 `devicePath` 合并或覆盖重复项；非完全重复的冲突交给 Kubernetes。

## 验收

- map 输入按官方文档字段顺序输出 `devicePath` 与 `name`。
- string 输入与等效 map 输入渲染结果一致。
- 父模板可接受 string 与 string array，string 元素按正则位置提取后与本模板 map 输入等效；超过 2 项时中断报错。
- 两个字段同时存在时输出；同时为空或仅含分隔符时无输出；仅一个字段为空时中断报错。
- 完全重复的数组项由父模板去重；非完全重复的项保留并交给 Kubernetes 处理。
- `name` 不符合正则或 `devicePath` 非绝对路径时按约定失败。
- `helm template` 实际渲染通过。
