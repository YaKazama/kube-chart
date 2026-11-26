# 新增 definitions.iscsiVolumeSource 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：更新 `K8S.VOLUME.ISCSI` 为必填 targetPortal、`[0-9]+` lun、大小写不敏感 fsType 与 boolean 枚举，更新 `K8S.VOLUME.ISCSI_PORTAL` 为 IPv4/IPv6 与可选端口形态正则；对应 `Decision: K8S.VOLUME.ISCSI 捕获`、`Decision: K8S.VOLUME.ISCSI_PORTAL 扩展`。
- [x] T2 `templates/base/_validate.tpl`：新增 `base.net.hostPort`，实现 host:port 解析、默认端口补全、IPv6 方括号输出与严格/非严格模式；对应 `Decision: base.net.hostPort 解析与归一化`。
- [x] T3 `templates/api-resources/Definitions/_ISCSIVolumeSource.tpl`：新增 `definitions.iscsiVolumeSource`，按官方顺序渲染全部字段，实现必填、`lun: 0`、fsType/boolean 归一化、portals 过滤与 secretRef 清洗；对应 `Decision: definitions.iscsiVolumeSource 字段处理`。
- [x] T4 `templates/api-resources/Definitions/_Volume.tpl`：更新 `iscsi` string 简写分支，只捕获并传递原始值，移除本地 targetPortal、fsType、boolean、portals、lun 校验与转换；对应 `Decision: 父模板 iscsi 简写委托`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/`：加载真实 `_env.tpl`、`_validate.tpl`，执行 `/opt/homebrew/bin/helm template`，覆盖 `base.net.hostPort` 的 IPv4/IPv6、默认端口、方括号、纯端口号与非法 IP 的严格/非严格模式；对应 `base.net.hostPort host:port 归一化`。
- [x] V2 `/tmp/sd-kube-chart/`：加载真实依赖与 `_ISCSIVolumeSource.tpl`，执行 `/opt/homebrew/bin/helm template`，覆盖最小必填含 `lun: 0`、全字段顺序、fsType 大小写、boolean 大小写、portals 混排、secretRef string/map、缺失必填与非法 targetPortal；对应 `definitions.iscsiVolumeSource 字段渲染`。
- [x] V3 `/tmp/sd-kube-chart/`：加载真实依赖、`_ISCSIVolumeSource.tpl` 与 `_Volume.tpl`，执行 `/opt/homebrew/bin/helm template`，覆盖最小简写、缺少 targetPortal、fsType/boolean 大小写、portals 丢弃非法元素、secretRef 与非法 targetPortal；对应 `definitions.volume iscsi 字符串简写`。
