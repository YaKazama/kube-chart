---
change-id: definitions-iscsi-volume-source
updated_at: "2026-11-26T16:27:01Z"
---

# 新增 definitions.iscsiVolumeSource

## 目标

- 提供 `definitions.iscsiVolumeSource`，用于渲染 Kubernetes `ISCSIVolumeSource`（v1 core），并修正父模板 `iscsi` 简写的捕获与归一化。

## 需求

- 上下文是原生 map 或由父模板清洗后的 map。
- 字段按官方定义：`targetPortal`、`iqn`、`lun` 必填；`iscsiInterface`、`fsType`、`readOnly`、`portals`、`chapAuthDiscovery`、`chapAuthSession`、`secretRef`、`initiatorName` 可选。
- 按官方定义渲染顺序：`chapAuthDiscovery`、`chapAuthSession`、`fsType`、`initiatorName`、`iqn`、`iscsiInterface`、`lun`、`portals`、`readOnly`、`secretRef`、`targetPortal`。
- `lun` 为 integer，显式 `0` 必须渲染。
- `fsType` 大小写不敏感匹配 `ext4`、`xfs`、`ntfs`；渲染时按枚举值校验并输出小写枚举值。
- `secretRef` 清洗为 `LocalObjectReference` map（string 名称转换为 `{name: ...}`），再委托子模板 `definitions.localObjectReference` 渲染；本 change 不创建、不修改该子模板。
- `portals` 为 string array，清洗委托 `base.slice.cleanup`；元素格式与 `targetPortal` 一致，非法值不渲染。
- `targetPortal` 与 `portals` 共用的 portal 格式：
  - IPv4：`10.0.2.15` 或 `10.0.2.15:3260`。
  - IPv6：`2001:db8::1`；带端口时必须使用方括号，例如 `[2001:db8::1]:3260`。
  - 端口可省略；省略时补全 `:3260`。
  - 不接受纯端口号（如 `3260`）。
  - `targetPortal` 不符合格式时中断。
- 公共模板分析结论：当前 `base` 层没有 host:port 解析能力；本 change 新增 base 公共模板，承载等价于 Go 标准库 `net.SplitHostPort` 的解析与默认端口补全。
- 扩展 `K8S.VOLUME.ISCSI_PORTAL`，使其覆盖 IPv4、IPv6 与可选端口。
- 修正父模板 `templates/api-resources/Definitions/_Volume.tpl` 使用的 `K8S.VOLUME.ISCSI` 正则（捕获组取值）：
  - `targetPortal` 改为必填。
  - `lun` 改为 `[0-9]+`。
  - `fsType` 改为 `(?i:ext4|xfs|ntfs)`。
  - boolean 字段 `readOnly`、`chapAuthDiscovery`、`chapAuthSession` 改为 `(?i:true|false)`；最终渲染为小写 `true`/`false`。

## 期望输入格式

- 键名与 Kubernetes `ISCSIVolumeSource` 字段一致。
- `targetPortal` 为 string，符合上述 IPv4/IPv6 与端口规则。
- `portals` 为 string array 或可拆分文本，由 `base.slice.cleanup` 归一化。
- `secretRef` 为 string 名称或 `LocalObjectReference` map，由本 change 清洗为 map。

## 验收

- 提供 `iqn`、`lun: 0`、`targetPortal` 时，输出包含 `lun: 0`。
- 已提供字段按官方顺序渲染。
- 父模板 `iscsi` 简写缺少 `targetPortal` 时中断。
- 父模板简写中的 boolean 字段接受任意大小写 `true|false`，输出小写 `true`/`false`。
- `fsType` 以任意大小写输入，输出 `ext4`、`xfs`、`ntfs` 之一的小写值。
- `targetPortal` 的 IPv4、IPv4:port、IPv6、[IPv6]:port 形式均通过；未指定端口时输出补全 `:3260`；纯端口号或其他格式中断。
- `portals` 中的非法元素不出现在输出中。
- `secretRef` 以 string 或 map 输入时均输出 `secretRef.name`。
