# definitions.emptyDirVolumeSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_EmptyDirVolumeSource.tpl`：新增 `definitions.emptyDirVolumeSource` 定义，在 `definitions.emptyDirVolumeSource` 内实现 `medium` 枚举校验、`sizeLimit` Quantity 校验、固定字段顺序和空内容输出；对应 `复用既有取值能力`、`medium 严格枚举`、`sizeLimit 按 Quantity 校验`、`模板名与父模板分发对齐`、`固定字段顺序与空输出边界`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：新建最小 application Chart，经 `definitions.volume` 渲染 `emptyDir: {}`、原生 map 的 `{medium: "Memory", sizeLimit: "1Gi"}` 与父模板清洗 string 形态，断言字段值、字段顺序、输出可被 YAML 解析，以及未知键（含 `mediumAlias`）被忽略。
- [x] V2 `/tmp/sd-kube-chart/`：分别以 `medium: memory` 和 `sizeLimit: 1GG` 渲染，断言 `helm template` 中断并报告对应字段错误。
