# definitions.envFromSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_EnvFromSource.tpl`：新增 define `definitions.envFromSource`，以 `hasKey` 判定 `configMapRef` 与 `secretRef` 互斥并派生字段与子模板名，map 原样透传、string 按位次归一、其余类型中断，引用与 `prefix` 分别经 `base.field` 渲染后按官方字段顺序拼接，空引用与空子模板结果均不输出；对应 `单文件承载并沿用共享结构命名`、`hasKey 判定互斥并用 ternary 收敛字段与子模板选择`、`用 get 与 kindIs 区分引用值类型`、`引用字符串使用 base.env 分隔符与位次映射`、`引用与 prefix 先渲染为片段再按官方顺序拼接`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与 `_EnvFromSource.tpl`，两个子模板使用同名最小 fixture 回显上下文）：`configMapRef` 为原生 map，`/opt/homebrew/bin/helm template` 渲染成功且输出以 `configMapRef` 为顶层键，不含 `envFrom`。
- [x] V2 同上：`secretRef` 为原生 map，渲染成功，fixture 收到的上下文与输入一致。
- [x] V3 同上：`configMapRef` 为 `app-config`、`secretRef` 为 `db-secret true`，fixture 分别收到只含 `name` 的 map 与含 `name`、`optional`（字符串 `true`）的 map。
- [x] V4 同上：`configMapRef` 为 `app-config,true` 与 `app-config ,  true` 均按逗号与空白切分；`secretRef` 为 `db-secret true extra` 时忽略多余段。
- [x] V5 同上：`configMapRef` 配 `prefix: /app` 输出 `configMapRef` 在 `prefix` 之前；`secretRef` 配 `prefix: /db` 输出 `prefix` 在 `secretRef` 之前；无 `prefix` 时不输出该键；`prefix` 为 `X=Y` 时原样输出。
- [x] V6 同上：两个引用字段并存、不含任何引用字段、`configMapRef` 为数字、`secretRef` 为 `null` 四种输入分别以 `/opt/homebrew/bin/helm template` 渲染失败，失败消息包含对应字段名或指明必须提供一个。
- [x] V7 同上：`configMapRef` 为空字符串时 `/opt/homebrew/bin/helm template` 渲染成功且输出为空内容；fixture 对指定输入返回空内容时输出不含该引用字段。
