# definitions.resourceClaim 模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ResourceClaim.tpl`：新建文件并定义 `definitions.resourceClaim`，以 `alias=false` 调用 `base.get` 取值，`base.string.normalize` 解码后按 `name`、`request` 顺序以引号标量渲染，`request` 为空时跳过；对应 Decision `单文件单模板，按 API 字段顺序直接渲染`、`关闭 base.get 别名识别`、`name 走必填取值，request 走可选取值`、`两个字段以带引号标量输出`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart 加载 `_ResourceClaim.tpl` 与真实 `templates/base/` 模板：以 `/opt/homebrew/bin/helm template` 执行仅 `name`、`name` + `request`、`request` 为空、含额外键、`name` 含非 DNS 字符、`name` 缺失、`name` 为空白和字段为非字符串标量场景，前五个场景断言输出字段与顺序，后三个场景断言渲染中断。
- [x] V2 `/tmp/` 最小 application Chart 通过真实 `definitions.resourceRequirements` 的容器 `claims` 简写与 map 项执行 `/opt/homebrew/bin/helm template`，确认委托结果与空结果剔除行为。
