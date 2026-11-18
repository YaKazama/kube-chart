# definitions.httpHeader 设计

## 技术目标

- capability：`definitions.httpHeader`
- artifact-type：`Helm named template`
- target：`definitions.httpHeader`

## 设计决策

### Decision: 字段顺序、归一化与必填门禁

- requirements：`字段校验与输出`
- choice：按 `name`、`value` 顺序遍历字段列表，逐个使用 `base.get` 取值、`base.string.normalize` 恢复 string 并 `trim`；缺失、trim 后为空或非 string 时中断，通过后以 `base.field` 的 `quote` 模式渲染该字段。
- rationale：同一循环固定 Kubernetes HTTPHeader 官方字段顺序，复用公共取值、归一和渲染能力，并统一缺失、空白与非字符串失败边界。

## 依赖契约

### Dependency: `base.get`

- availability：`existing`
- source：`templates/base/_get.tpl`
- operation：`consume`
- input：`list [map 上下文, "name"|"value"]`
- output：字段的 YAML 标量文本；字段缺失时为空输出
- ownership：依赖层负责取值与序列化；本模板负责必填、空白和类型门禁

### Dependency: `base.string.normalize`

- availability：`existing`
- source：`templates/base/_convert.tpl`
- operation：`consume`
- input：`base.get` 输出的 YAML 标量文本
- output：string；空值与 null 返回空字符串，非 string 或非法 YAML 中断
- ownership：依赖层负责标量解码；本模板负责 trim 与空值判断

### Dependency: `base.field`

- availability：`existing`
- source：`templates/base/_field.tpl`
- operation：`consume`
- input：`list ["name"|"value", 已归一化字符串, "quote"]`
- output：YAML 键值片段；空值不输出
- ownership：依赖层负责带引号字符串渲染；本模板在调用前完成非空校验

## 代码边界

### `templates/api-resources/Definitions/_HTTPHeader.tpl`

- access：`write`
- operations：`add definitions.httpHeader`
- writable-scopes：新文件的完整内容

### `templates/base/_get.tpl`

- access：`read`
- operations：`base.get`
- writable-scopes：无

### `templates/base/_convert.tpl`

- access：`read`
- operations：`base.string.normalize`
- writable-scopes：无

### `templates/base/_field.tpl`

- access：`read`
- operations：`base.field`
- writable-scopes：无

## 验证设计

- 在 `/tmp/` 最小 application Chart 中加载当前 library Chart，直接以 map 上下文调用 `definitions.httpHeader`；本模板没有未实现依赖，不需要 fixture。
- 最小有效场景：提供带首尾空白的 `name`、`value`，验证输出已 trim 且按 `name`、`value` 顺序排列。
- 关键失败场景：分别缺少 `name`、缺少 `value`、空字符串、仅含空白字符及非 string 输入，预期全部中断渲染。
