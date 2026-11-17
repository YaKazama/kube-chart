# definitions.envVarSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_EnvVarSource.tpl`：新增 define `definitions.envVarSource`，以五字段配置表判定互斥字段，map 原样透传、string 按位次组装、其余类型中断，非空结果经选择器子模板渲染后以 `base.field` + `base.map` 输出，空选择器与空子模板结果均不输出；对应 `单文件承载并沿用共享结构命名`、`用五字段配置表驱动分发`、`用 hasKey 与 kindIs 判定存在性和值类型`、`字符串归一使用 base.env 分隔符与位次映射`、`单键选择器结果由 base.field 以 base.map 输出`、`表驱动的存在性检查与唯一项处理分离`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与 `_EnvVarSource.tpl`，五个选择器子模板使用同名最小 fixture）：输入 `configMapKeyRef` 原生 map，渲染成功且输出以 `configMapKeyRef` 为顶层键，不含 `valueFrom`。
- [x] V2 同上：五个字段分别以原生 map 输入，fixture 收到的上下文与输入结构一致。
- [x] V3 同上：`configMapKeyRef`、`fieldRef`、`fileKeyRef`、`resourceFieldRef`、`secretKeyRef` 分别为 `app-config LOG_LEVEL`、`metadata.name v1`、`vol /etc/x`、`limits.cpu`、`db-creds password true`，fixture 收到的键与值符合位次映射，`optional` 为字符串 `true`。
- [x] V4 同上：`fieldRef` 为 `metadata.name, v1` 时按逗号切分；`resourceFieldRef` 为 `limits.cpu api 1 extra` 时忽略多余段。
- [x] V5 同上：`fileKeyRef` 为 `only-volume`、`configMapKeyRef` 为空字符串、输入不含任何字段三种情况均渲染成功且输出为空内容。
- [x] V6 同上：同时含 `configMapKeyRef` 与 `secretKeyRef`、`configMapKeyRef` 为数字、`fieldRef` 为 `null` 三种输入分别 `helm template` 失败，失败消息包含对应字段名。
- [x] V7 同上：fixture 对指定输入返回空内容时，输出不含该 `*Ref` 字段。
- [x] V8 同上：加载真实 `_EnvVar.tpl` 与本能力，`valueFrom` 分别为 `cm app-config LOG_LEVEL` 与原生 `configMapKeyRef` map，端到端输出以 `valueFrom` 为顶层键且内部为 `configMapKeyRef`。
