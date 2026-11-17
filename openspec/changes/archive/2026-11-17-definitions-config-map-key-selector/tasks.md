# definitions.configMapKeySelector 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `RFC` 下新增 `RFC1123_SUBDOMAIN` 常量；对应 `为 base.rfc 追加 1123sub 分支与常量`。
- [x] T2 `templates/base/_k8s.tpl`：在 `base.rfc` 中追加 `1123sub` 模式分支（正则取 `RFC.RFC1123_SUBDOMAIN`、长度上限 253、modeLabel 为 `RFC1123 Subdomain`），并同步其契约注释的模式清单与示例；对应 `为 base.rfc 追加 1123sub 分支与常量`。
- [x] T3 `templates/api-resources/Definitions/_ConfigMapKeySelector.tpl`：新增 define `definitions.configMapKeySelector`，按 `key` → `name` → `optional` 顺序渲染；`key` 与 `name` 自控判空，`name` 委托 `base.rfc` 的 `1123sub` 模式，`optional` 用 `SYS.YAML_QUOTED` 排除字符串后交给 `base.bool`；对应 `单文件承载并按官方字段顺序渲染`、`key 与 name 用自控空值校验替代 base.get 必填参数`、`name 复用 base.rfc 的 1123sub 模式`、`optional 用 base.get 原始输出的引号形态区分原生布尔与字符串`。
- [x] T4 `templates/api-resources/Definitions/_EnvVarSource.tpl`：把 `configMapKeyRef` 配置项的 `required` 从 `1` 改为 `2`；对应 `父级 configMapKeyRef 必需段数改为 2`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与四个已变更文件）：输入 `key: LOG_LEVEL` 与 `name: app-config`，渲染成功且输出只含这两个字段，均为双引号字符串。
- [x] V2 同上：`key`、`name`、`optional: true` 三字段齐全时按 `key`、`name`、`optional` 顺序输出，`optional` 为裸布尔。
- [x] V3 同上：`optional: false` 时输出 `optional: false`；输入含未定义键 `foo` 时输出不含 `foo`。
- [x] V4 同上：`name: app.config` 渲染成功。
- [x] V5 同上：`key` 缺失、`name` 缺失、`name` 为空白、`name: app_config`、`name: -app`、254 字符名称、`optional: "true"`、`optional: 1` 八种输入分别 `helm template` 失败，失败消息符合预期。
- [x] V6 同上：加载真实 `_EnvVarSource.tpl`，`configMapKeyRef` 为 `cfg` 时输出为空且不中断；为 `cfg LOG_LEVEL` 时组装为 `name`/`key` 并渲染出 `configMapKeyRef` 字段。
- [x] V7 同上：加载真实 `_k8s.tpl`，`base.rfc` 的 `1035`、`1123`、`rbac` 三个既有模式分别以合法与非法取值渲染，结果与失败消息与变更前一致；`1123sub` 接受 `app.config` 且拒绝 `-app`。
