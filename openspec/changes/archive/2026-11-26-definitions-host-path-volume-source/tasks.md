# 新增 definitions.hostPathVolumeSource 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：更新 `K8S.VOLUME.HOST_PATH` 为锚定正则，路径捕获组保持 `(/\S*)`，`type` 捕获组改为大小写不敏感的官方枚举 alternation 并保留捕获组；对应 `Decision: 父模板 hostPath 简写正则与枚举归一化`。
- [x] T2 `templates/api-resources/Definitions/_HostPathVolumeSource.tpl`：新增 `definitions.hostPathVolumeSource`，按官方顺序渲染 `path`、`type`，实现必填、绝对路径、空 `type` 省略与大小写敏感枚举校验；对应 `Decision: 定义模板字段归一化与渲染`。
- [x] T3 `templates/api-resources/Definitions/_Volume.tpl`：更新 `hostPath` string 简写分支，空 `type` 不下传，非空 `type` 映射为官方枚举后下传，删除已由正则保证的二次枚举失败分支；对应 `Decision: 父模板 hostPath 简写正则与枚举归一化`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：加载真实 `_env.tpl`、base 依赖、`_HostPathVolumeSource.tpl` 与 `_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`，覆盖 `{path: "/data"}`、`{path: "/data/../logs", type: "DirectoryOrCreate"}`、`{path: "/data", type: ""}`、缺失/空/相对/非 string `path`、小写/非法/非 string `type` 的预期输出或中断；对应 `definitions.hostPathVolumeSource 字段渲染`。
- [x] V2 `/tmp/sd-kube-chart/`：执行 `/opt/homebrew/bin/helm template` 渲染 `definitions.volume` 的 `hostPath` 简写 `/data`、`/data directoryorcreate`、`/data ""`、`data`、空字符串与 `/data Invalid`，验证官方枚举归一化、空 `type` 省略和新的 `does not match '<path> [type]'` 中断信息；对应 `definitions.volume hostPath 字符串简写`。
