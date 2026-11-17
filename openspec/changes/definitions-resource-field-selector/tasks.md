# definitions.resourceFieldSelector 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `K8S` 下新增 `RESOURCE_FIELD`、`DIVISOR_CPU`、`DIVISOR_SIZE` 三个常量；对应 `divisor 归一后按资源类型分流校验形态`。
- [x] T2 `templates/api-resources/Definitions/_ResourceFieldSelector.tpl`：新增 define `definitions.resourceFieldSelector`，按 `containerName` → `divisor` → `resource` 输出；`containerName` 可选、`resource` 必填并校验支持列表，`divisor` 按资源类型限制形态，cpu 小数核值换算为整数毫核，全部形态统一经 `base.field` 的 `base.quantity` 渲染模板输出；对应 `单文件承载并按官方字段顺序输出`、`containerName 与 resource 各自独立取值`、`divisor 归一后按资源类型分流校验形态`、`cpu 小数核值换算为毫核后统一交给 base.quantity 渲染`、`先取 resource 再处理 divisor，输出顺序仍按官方字段表`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与两个已变更文件）：输入 `resource: limits.cpu`，渲染成功且输出只含 `resource: "limits.cpu"`，不含 `containerName` 与 `divisor`。
- [x] V2 同上：`containerName: app`、`divisor: 1m`、`resource: limits.cpu` 齐全时按 `containerName`、`divisor`、`resource` 顺序输出。
- [x] V3 同上：六个官方资源名分别渲染成功。
- [x] V4 同上：`divisor` 为 `1`、`2` 时输出不带引号数字；为 `1.5`、`0.05` 时输出 `1500m`、`50m`；为 `1m`、`500m`、`2Mi`、`128Mi`、`1Ti` 时输出对应字符串标量。
- [x] V5 同上：输入含未定义键 `foo` 时输出不含 `foo`。
- [x] V6 同上：`resource` 缺失、`resource` 为空白、`resource: metadata.name`、`resource: limits.gpu` 四种输入分别 `helm template` 失败，失败消息符合预期。
- [x] V7 同上：`.cpu` 资源下 `divisor` 为 `1Ki`、`2Mi`、`1.5m`，`.memory` 资源下 `divisor` 为 `1`、`1m`、`500m`，以及 `divisor: 1Xi` 六种输入分别失败，失败消息符合预期。
- [x] V8 同上：`.cpu` 资源下 `divisor` 为 `1.5`、`2`、`1000m`，`.memory` 资源下 `divisor` 为 `2Mi`、`128Mi` 均渲染成功；`1.5` 输出 `1500m`。
