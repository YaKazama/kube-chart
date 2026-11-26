---
change-id: definitions-nfs-volume-source
updated_at: "2026-11-26T17:01:33Z"
---

# definitions.nfsVolumeSource

## 目标

- 新增 `definitions.nfsVolumeSource` 定义，按官方 `NFSVolumeSource` 渲染 NFS 卷字段。

## 需求

- 上下文为原生 map 或由父模板清洗后的 map。
- 字段按官方定义：`server`、`path` 必填，`readOnly` 可选。
- 按官方定义渲染顺序输出字段；本地 v1.36 参考中依次为 `path`、`readOnly`、`server`。
- 渲染时校验：`server` 为 IP 或 hostname 格式；`path` 为绝对路径；`readOnly` 为 boolean 类型。

## 约束

- 父模板 nfs 正则维持现状：`readOnly` 捕获为 `true|false`，`path` 捕获为绝对路径，无需修正。

## 验收

- `server` 或 `path` 缺失时渲染中断。
- `server` 既非 IP 也非 hostname 格式时渲染中断。
- `path` 不是绝对路径时渲染中断。
- `readOnly` 不是 boolean 类型时渲染中断。
- 渲染结果按官方定义顺序输出 `path`、`readOnly`、`server`，未提供的可选字段不输出。
