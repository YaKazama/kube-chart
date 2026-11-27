# 移除 imageRefs 设计

## 技术目标

- capability：`definitions.container`
- artifact-type：`Helm 命名模板`
- target：`templates/api-resources/Definitions/_Container.tpl`

## 设计决策

### Decision: image 两源解析

- requirements：`image 来源解析`
- choice：删除 `imageRefs` 分支，只保留 `imageFileRefs` > `image` 两级来源；最终为空时中断。
- rationale：draft 确认移除 `imageRefs`，并保留 `imageFileRefs` 的更高优先级。

### Decision: imageRefs 静默忽略

- requirements：`image 来源解析`
- choice：不再通过 `base.get` 读取或校验 `imageRefs`；未声明键按既有边界静默忽略。
- rationale：draft 明确要求静默忽略，避免残留 values 阻断渲染。

### Decision: imageFileRefs 只接受 string

- requirements：`image 来源解析`
- choice：`base.fileRefs` 输出非空后先用 `fromYaml` 探测；可解析为 map 时中断；否则经 `base.string.normalize` 解码，非 string 值中断。
- rationale：draft 要求 map 内容中断；list、number、boolean 沿用 `base.string.normalize` 的 string 门禁。

### Decision: 删除 imageRef 辅助模板

- requirements：`image 来源解析`
- choice：删除 `define "definitions.container.imageRef"` 及其契约注释，不保留兼容入口。
- rationale：移除 `imageRefs` 后无其他调用方；draft 确认当前阶段直接破坏性删除。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [map, 点分路径]`
- output：可解析的 YAML 字符串；路径缺失时为空输出
- ownership：`base.get` 负责取值与序列化；本模板负责 image 来源优先级与最终非空校验

### Dependency: `base.fileRefs`

- availability：`existing`
- source：`templates/base/_fileRefs.tpl`
- operation：`consume`
- input：`list [上下文, imageFileRefs 原始 YAML 字符串]`
- output：合并后内容的 YAML 字符串；无有效项时为空内容
- ownership：负责文件读取、路径校验与字段提取；本模板负责解析结果的 string 门禁

### Dependency: `base.isFromYamlError`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`fromYaml` 的返回值
- output：错误标记字符串 `"true"` 或 `"false"`
- ownership：只判断 YAML map 解析是否失败

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.fileRefs` 或 `base.get` 输出的单个 YAML 标量文本
- output：解码后的 string；非 string 标量或非法 YAML 中断
- ownership：只还原 string 标量，不做 trim 或内容改写

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list [key, value, 渲染模板]`
- output：YAML 键值对；渲染值为空时不输出
- ownership：负责单字段 YAML 渲染与引号处理

## 代码边界

### `templates/api-resources/Definitions/_Container.tpl`

- access：`write`
- operations：`update` `image` 字段处理块、`remove` `definitions.container.imageRef`、`update` 文件头整体契约注释中的 image 与引用字段优先级说明
- writable-scopes：`image` 字段处理块、`define "definitions.container.imageRef"` 及其契约注释、整体契约注释中的 image 相关区段

### `templates/base/_get.tpl`

- access：`read`
- operations：`consume` `base.get`

### `templates/base/_fileRefs.tpl`

- access：`read`
- operations：`consume` `base.fileRefs`

### `templates/base/_convert.tpl`

- access：`read`
- operations：`consume` `base.isFromYamlError`、`base.string.normalize`

### `templates/base/_field.tpl`

- access：`read`
- operations：`consume` `base.field`

## 验证设计

- 最小有效：仅提供 `image`，输出该镜像引用。
- imageRefs 被忽略：同时提供 `image` 与任意形态的 `imageRefs`，仍输出 `image` 且不中断。
- 文件来源：`imageFileRefs` 解析出 string 时覆盖 `image`。
- 关键失败：`imageFileRefs` 解析出 map、list 或其他非 string 值，以及两个来源均不可得时中断。
- 真实依赖：`base.*` 均为现有模板；验证在 `/tmp/sd-kube-chart/` 新建的最小 application Chart 中加载真实实现，文件引用使用该 Chart 内的真实 fixture 文件。
