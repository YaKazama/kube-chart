# definitions.envVar 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_EnvVar.tpl`：新增 define `definitions.envVar`，按 `name` → `value` → `valueFrom` 顺序输出 `EnvVar` 字段；`value` 以 `toString` 强制类型后归一并以引号输出，对象与数组中断；`valueFrom` 先按 YAML 恢复区分原生 map 与字符串，字符串再剥离引号、切分两段并映射关键字，两种来源归一为同一委托上下文交给 `definitions.envVarSource`，非空结果才输出；对应 `单文件承载并沿用共享结构命名`、`按 EnvVar API 字段顺序取值并统一由 base.field 输出`、`用 base.get 原始输出是否为空判定字段未提供`、`name 走 base.get 必填与 base.string.normalize`、`value 强制转换为字符串后统一带引号输出`、`value 拒绝对象与数组`、`valueFrom 先做 YAML 恢复再按错误分支判定来源类型`、`字符串分支复用 base.env 常量切分两段并映射关键字`、`两种来源归一为同一委托上下文并共用渲染闭环`。
- [x] T2 `templates/api-resources/Definitions/_Container.tpl`：把三处 `definitions.enVar` 标识符改为 `definitions.envVar`；对应 `修正 Container 中错误的委托名`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与 `_EnvVar.tpl`，`definitions.envVarSource` 使用同名最小 fixture）：输入 `name: FOO` 与 `value: bar` 渲染成功，输出只含 `name: "FOO"` 与 `value: "bar"`。
- [x] V2 同上：`value` 分别为 `123`、`1.5`、`true` 时均输出带引号字符串，不产生数字或布尔类型。
- [x] V3 同上：`name` 缺失、`name` 为空、`value` 为对象、`value` 为数组、`value` 与 `valueFrom` 并存五种输入分别 `helm template` 失败，失败消息包含对应字段名。
- [x] V4 同上：只有 `name`、`value` 为空字符串、`valueFrom` 为 `cm`、`valueFrom` 为 `env app-config`、`valueFrom` 为空字符串五种输入均渲染成功且只输出 `name`。
- [x] V5 同上：`valueFrom` 分别为 `cm app-config LOG_LEVEL`、`ConfigMap, app-config`、`field metadata.name`、`file volume-a /etc/x`、`resource limits.cpu`、`secret db-creds password`，fixture 收到的单键 map 键与第 2 段原串均符合预期。
- [x] V6 同上：`valueFrom` 为原生 map 时 fixture 收到同一结构；fixture 返回空内容时不输出 `valueFrom` 字段。
- [x] V7 同上：加载真实 `_Container.tpl`，以 `env` 的 `value` 形态渲染 Container，`env` 字段正常输出且委托名解析到 `definitions.envVar`（`definitions.envVarSource` 仍为 fixture 边界）。
