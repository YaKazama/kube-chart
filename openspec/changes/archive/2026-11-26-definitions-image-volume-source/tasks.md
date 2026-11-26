# 新增 definitions.imageVolumeSource 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：更新 `K8S.VOLUME.IMAGE` 为锚定正则，`reference` 捕获组保持 `(\S+)`，`pullPolicy` 捕获组改为大小写不敏感的官方枚举 alternation `Always|IfNotPresent|Never` 并保留捕获组；对应 `Decision: 父模板 image 简写正则`。
- [x] T2 `templates/api-resources/Definitions/_ImageVolumeSource.tpl`：新增 `definitions.imageVolumeSource`，按官方顺序渲染 `pullPolicy`、`reference`，实现 `reference` 必填、空 `pullPolicy` 省略与大小写敏感枚举校验；对应 `Decision: 定义模板字段归一化与渲染`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：加载真实 `_env.tpl`、base 依赖、`_ImageVolumeSource.tpl` 与 `_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`，覆盖 `{reference: "nginx:1.27"}`、`{reference: "nginx:1.27", pullPolicy: "Always"}`、`{reference: "nginx:1.27", pullPolicy: ""}`、缺失/空/非 string `reference`、小写/非法/非 string `pullPolicy` 的预期输出或中断；对应 `definitions.imageVolumeSource 字段渲染`。
- [x] V2 `/tmp/sd-kube-chart/`：执行 `/opt/homebrew/bin/helm template` 渲染 `definitions.volume` 的 `image` 简写 `nginx:1.27`、`nginx:1.27 always`、`nginx:1.27 IfNotPresent`、空字符串与 `nginx:1.27 Sometimes`，验证官方枚举归一化、空 `pullPolicy` 省略和新的 `does not match '<reference> [pullPolicy]'` 中断信息；对应 `definitions.volume image 字符串简写`。
