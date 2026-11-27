# PVC 卷源定义任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_PersistentVolumeClaimVolumeSource.tpl`：在 `define "definitions.persistentVolumeClaimVolumeSource"` 内按 `claimName`、`readOnly` 顺序渲染，并对必填与 boolean 类型执行校验；对应 `PersistentVolumeClaimVolumeSource 字段渲染`、`PersistentVolumeClaimVolumeSource 输入校验`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart 直接 include `definitions.persistentVolumeClaimVolumeSource`，输入 `{claimName: "data"}`；`/opt/homebrew/bin/helm template` 仅输出 `claimName`。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart 经 `definitions.volume` 渲染 persistentVolumeClaim 简写，输入 `{name: "data", persistentVolumeClaim: "data true"}`；`/opt/homebrew/bin/helm template` 输出 `claimName`、`readOnly`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart 覆盖失败输入：缺 `claimName`、`claimName` 为空、`claimName` 非 string、`readOnly` 非 boolean；`/opt/homebrew/bin/helm template` 均非零退出。
- [x] V4 `/tmp/sd-kube-chart/` 最小 Chart 覆盖边界输入：`readOnly: false`；`/opt/homebrew/bin/helm template` 输出 `readOnly: false`。
