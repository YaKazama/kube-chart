# definitions.volume 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：更新 `K8S.VOLUME.SHORT`，新增 `UNSUPPORTED_SHORT`、`KEY_TO_PATH_SOURCE`、`KEY_TO_PATH_ITEM`、`CSI`、`CSI_ATTRIBUTE`、`DOWNWARD_API`、`DOWNWARD_API_FIELD_ITEM`、`DOWNWARD_API_RESOURCE_ITEM`、`EMPTY_DIR`、`FC`、`HOST_PATH`、`IMAGE`、`ISCSI`、`ISCSI_PORTAL`、`NFS`、`PERSISTENT_VOLUME_CLAIM`；对应 `Decision: 字符串解析归属与常量`。
- [x] T2 `templates/api-resources/Definitions/_Volume.tpl`：新增 `definitions.volume` 命名模板、契约注释与错误消息前缀，实现 `{name, <source>}` 分派、11 类 source 字符串解析与 `ephemeral` / `projected` string 拒绝、枚举/布尔/数量校验、孙模板字段以原始 item 字符串/secretRef 字符串下传、子模板 include 与 `{}` 兜底、字段顺序渲染；对应 `Decision: 输入形状与唯一 source 分派`、`Decision: 子模板占位与空输出兜底`、`Decision: 字段渲染顺序`、`Decision: 位置可选段空字符串占位`、`Decision: 括号组与数组空值`、`Decision: 枚举与布尔归一化`、`Decision: 不过度清洗与下游校验`。
- [x] T3 `templates/api-resources/Core/_PodSpec.tpl`：更新 `volumes` 注释与处理块，移除 `SPLIT.SPACE_COMMA` 归一化、扩展 `volumeTypes`、统一 map/string 为 `{name, <source>: <value>}`、拒绝 `ephemeral` / `projected` string、改用 `definitions.volume` 调用；对应 `Decision: core.podSpec volumes 归一化`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小有效渲染：加载 `_env.tpl`、`_Volume.tpl`、`_PodSpec.tpl` 与 base 依赖，提供 13 个 unavailable 子模板 fixture；渲染 `definitions.volume` 的 map 输入与 `core.podSpec` 的单 string 输入，确认 `name` 与 source 键顺序、`{}` 输出和 fixture 调用；对应 `验证设计` 的最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 完整字符串渲染：覆盖 11 类可解析 source 的 string 输入，包括 optional/defaultMode/items、csi 空 secretRef/枚举/属性、downwardAPI 两种 item 与 mode、emptyDir medium/sizeLimit、fc 两组 WWN 与 lun、hostPath 显式空 type、image pullPolicy、iscsi 空占位/chap/portals、nfs/pvc readOnly，以及枚举大小写归一化和八进制/十进制 mode 原样下传；同时确认 `ephemeral` / `projected` string 中断；对应 `验证设计` 的较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` volumes 混合渲染：渲染 `core.podSpec` 的 map/string 混合 `volumes`，确认 `volumeTypes` 的 `csi`、`api`、`downwardAPI` 归一化与数组输出；对应 `Requirement: core.podSpec volumes 归一化`。
- [x] V4 `/tmp/sd-kube-chart/` 关键失败：覆盖 name 缺失/非法、source 数量为零或多、名单外 source、`ephemeral` / `projected` string、非法枚举/布尔/lun/sizeLimit/绝对路径/portal、空 items/属性括号、字符串格式不匹配和子模板非法 YAML；对应 `验证设计` 的关键失败项。
- [x] V5 `/tmp/sd-kube-chart/` 子模板输出边界：fixture 分别返回空内容、合法非 map 与非法 YAML，确认前两者输出 `source: {}`、非法 YAML 中断；对应 `验证设计` 的空输出与占位项。
