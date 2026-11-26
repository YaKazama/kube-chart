# NFS 卷源定义任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_NFSVolumeSource.tpl`：在 `define "definitions.nfsVolumeSource"` 内按 `path`、`readOnly`、`server` 顺序渲染，并对必填字段、绝对路径、IP/hostname 与 boolean 执行校验；对应 `NFSVolumeSource 字段渲染`、`NFSVolumeSource 输入校验`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart 直接 include `definitions.nfsVolumeSource`，输入 `{server: "10.0.0.1", path: "/data"}`；`/opt/homebrew/bin/helm template` 仅输出 `path` 与 `server` 且顺序为 `path`、`server`。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart 经 `definitions.volume` 渲染 nfs 简写，输入 `{name: "nfs", nfs: "10.0.0.1 /data true"}`；`/opt/homebrew/bin/helm template` 输出 `path`、`readOnly`、`server`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart 覆盖失败输入：缺 `server`、缺 `path`、`server` 非法、`path` 非绝对、`readOnly` 非 boolean；`/opt/homebrew/bin/helm template` 均非零退出。
- [x] V4 `/tmp/sd-kube-chart/` 最小 Chart 覆盖边界输入：`path: "/"`、IPv6 `server`、`readOnly: false`；`/opt/homebrew/bin/helm template` 输出符合预期。
