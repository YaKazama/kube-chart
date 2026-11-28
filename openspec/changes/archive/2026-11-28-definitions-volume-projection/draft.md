---
change-id: definitions-volume-projection
updated_at: "2026-11-28T08:35:14Z"
---

# definitions.volumeProjection

## 目标

- 新增 `definitions.volumeProjection`，渲染 Kubernetes `VolumeProjection` 字段片段。

## 需求

- 上下文是原生 map。
- 字段按官方定义。
- 按官方定义渲染顺序。
- 子模板映射：
  - `clusterTrustBundle` 委托 `definitions.clusterTrustBundleProjection`。
  - `configMap` 委托 `definitions.configMapProjection`。
  - `downwardAPI` 委托 `definitions.downwardAPIProjection`。
  - `podCertificate` 委托 `definitions.podCertificateProjection`。
  - `secret` 委托 `definitions.secretProjection`。
  - `serviceAccountToken` 委托 `definitions.serviceAccountTokenProjection`。
- 所有子模板只占位，本 change 不创建。
- 所有字段互斥且必填：同时只能有一个字段生效。
- 六个官方字段之外的输入字段不参与互斥判定。
- 多个字段同时出现、取值后为空或非法时中断报错。

## 非目标

- 不创建上述六个子模板。

## 验收

- 输入恰好一个有效字段时，按官方字段名与顺序输出该字段，并委托对应子模板渲染。
- 多个字段同时出现时中断并报错。
- 无字段、取值后为空或字段非法时中断并报错。

## 开放问题

- 无。
