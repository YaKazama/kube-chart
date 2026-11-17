# definitions.fileKeySelector 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_FileKeySelector.tpl`：新增 define `definitions.fileKeySelector`，按 `key` → `optional` → `path` → `volumeName` 顺序渲染；三个必填字段自控判空，`path` 经 `base.path` 的 `rel` 模式归一化并拒绝 `.`、`..` 与 `../` 前缀三种结果，`optional` 用 `SYS.YAML_QUOTED` 排除字符串后交给 `base.bool`；对应 `单文件承载并按官方字段顺序渲染`、`三个必填字段统一自控判空`、`path 用 base.path 的 rel 模式归一化并补充路径边界判断`、`optional 用 base.get 原始输出的引号形态区分原生布尔与字符串`。
- [x] T2 `templates/api-resources/Definitions/_EnvVarSource.tpl`：把 `fileKeyRef` 配置项的 `required` 从 `2` 改为 `3`；对应 `父级 fileKeyRef 必需段数改为 3`。

## 验证

- [x] V1 `/tmp/` 最小 Chart（真实 `templates/base/` 与两个已变更文件）：输入 `key: LOG_LEVEL`、`path: app.log`、`volumeName: env-vol`，渲染成功且输出只含这三个字段，均为双引号字符串，不含 `optional`。
- [x] V2 同上：四字段齐全时按 `key`、`optional`、`path`、`volumeName` 顺序输出，`optional` 为裸布尔；`optional: false` 时输出 `optional: false`。
- [x] V3 同上：输入含未定义键 `foo` 时输出不含 `foo`。
- [x] V4 同上：`path` 为 `logs/./app.log` 时输出 `logs/app.log`；`path` 为 `a/../b` 时输出 `b`。
- [x] V5 同上：`volumeName` 缺失、`path` 缺失、`key` 缺失、`path` 为空白、`key` 为空白、`volumeName` 为空白、`path: /etc/app.log`、`path: ../app.log`、`path: ..`、`path: .`、`path: a/..`、`optional: "true"`、`optional: 1` 十三种输入分别 `helm template` 失败，失败消息符合预期。
- [x] V6 同上：加载真实 `_EnvVarSource.tpl`，`fileKeyRef` 为 `env-vol app.log` 时输出为空且不中断；为 `env-vol app.log LOG_LEVEL` 时组装为 `volumeName`/`path`/`key` 并渲染出 `fileKeyRef` 字段。
