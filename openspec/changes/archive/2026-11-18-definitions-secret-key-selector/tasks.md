# definitions.secretKeySelector 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `K8S` 下新增 `DATA_KEY` 常量；对应 `data key 字符集正则集中在 base.env 并由两个选择器共用`。
- [x] T2 `templates/api-resources/Definitions/_SecretKeySelector.tpl`：新增 define `definitions.secretKeySelector`，按 `key` → `name` → `optional` 输出；`key` 与 `name` 必填，`name` 委托 `base.rfc` 的 `1123sub` 校验，`key` 按 `K8S.DATA_KEY` 校验字符集，`optional` 剥离 YAML 引号后交给 `base.bool`；对应 `单文件承载并按官方字段顺序输出`、`name 与 key 各自独立取值并各自收口校验`、`optional 剥离 YAML 引号后交给 base.bool`。
- [x] T3 `templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`：在 `key` 处理闭环中追加 `K8S.DATA_KEY` 字符集校验，并把 `optional` 改为剥离 YAML 引号后交给 `base.bool`；对应 `configMapKeySelector 的 key 校验就地补强`、`optional 剥离 YAML 引号后交给 base.bool`。
- [x] T4 `templates/api-resources/Definitions/_EnvVarSource.tpl`：把 `$sources` 中 `secretKeyRef` 的 `required` 由 `1` 改为 `2`；对应 `envVarSource 的 secretKeyRef 必需段数改为 2`。
- [x] T5 `templates/api-resources/Definitions/_FileKeySelector.tpl`：把 `optional` 改为剥离 YAML 引号后交给 `base.bool`，与另两个选择器同构；对应 `optional 剥离 YAML 引号后交给 base.bool`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与 `_SecretKeySelector.tpl`）：输入 `key: password`、`name: db-creds`，渲染成功且只输出这两字段，均为双引号字符串，不含 `optional`。
- [x] V2 同上：`key: password`、`name: db-creds`、`optional: true` 齐全时按 `key`、`name`、`optional` 顺序输出；`optional: false` 时输出 `optional: false`；`optional: "true"` 与 `optional: "false"` 同样输出布尔标量。
- [x] V3 同上：`name` 为 `1secret`、`app.config`、63 字符单段、253 字符多段时分别渲染成功。
- [x] V4 同上：`key` 为字符串 `LOG_LEVEL`、`app.key`、`"1"`、`.key`、`key.`、`_key`、`-key` 时分别渲染成功。
- [x] V5 同上：输入含未定义键 `foo` 时输出不含 `foo`。
- [x] V6 同上：`key` 缺失、`key` 为空白、`key: 1`、`key: true`、`key: k ey`、`key: k/ey`、`key: k:ey` 七种输入分别 `helm template` 失败；前两类消息含 `key`，字符集类消息含 `key` 与实际取值，非字符串类型由标量还原层中断。
- [x] V7 同上：`name` 缺失、`name` 为空白、`name: My-Secret`、`name: secret_name`、`name: .secret`、64 字符单段、254 字符多段七种输入分别失败，失败消息符合预期。
- [x] V8 同上：`optional: 1`、`optional: "yes"` 与 `optional: {a: b}` 三种输入分别失败，失败消息由布尔类型门禁给出。
- [x] V9 同上：`definitions.configMapKeySelector` 在 `key: LOG_LEVEL` 下仍渲染成功、在 `key: k/ey` 下失败；同一 `key` 在两个选择器下结果一致。
- [x] V10 同上：`definitions.envVarSource` 的 `secretKeyRef` 为 `db-creds` 时不输出内容且不中断，为 `db-creds password` 时输出 `name` 与 `key`，为 `db-creds password true` 与 `db-creds password true extra` 时输出 `optional: true` 并忽略多余段，为 `db-creds password maybe` 时中断；三个模板需在各自独立的 `/tmp/` Chart 中分别渲染，避免同一 Chart 内探针互相污染。
- [x] V11 同上：`definitions.configMapKeySelector` 的 `configMapKeyRef: app-config LOG_LEVEL true` 与 `definitions.fileKeySelector` 的 `fileKeyRef: env-vol etc/app.log LOG_LEVEL true` 均渲染成功并输出 `optional: true`；两者的 `optional: 1` 均失败。
