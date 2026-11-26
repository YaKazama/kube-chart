# definitions.fcVolumeSource 定义模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_FCVolumeSource.tpl`：新增 `definitions.fcVolumeSource` 与文件头整体契约注释，实现 `fsType`、`lun`、`readOnly`、`targetWWNs`、`wwids` 的取值、归一、校验、WWN 分支判定与按 API 顺序渲染；对应 `Decision: 文件命名与调用入口`、`Decision: 字段归一化通道`、`Decision: WWN 分支判定与优先级`、`Decision: 输出顺序与显式零值`、`Decision: 失败消息边界`。
- [x] T2 `templates/api-resources/Definitions/_Volume.tpl`：将 `fc` 分支的 `lun` 以原生整数写入上下文，并在 `fc` 契约注释中显式说明三条组合边界，不新增父层组合校验；对应 `Decision: 父模板 fc 上下文类型归一与契约说明`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 直接 include：传 `{targetWWNs: ["10:20:30:40:50:60:70:80"], lun: 0}`，输出仅含 `lun: 0` 与 `targetWWNs` 且顺序符合 API；对应 `验证设计` 最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 直接 include 与 `definitions.volume`：完整 `targetWWNs` 分支含显式 `readOnly: false` 且 `wwids` 同时存在、仅 `wwids` 分支携带 `lun`、`fc` 原生 map 入口，输出字段、顺序与分支抑制符合预期；对应 `验证设计` 较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 关键失败：`targetWWNs` 缺少 `lun`、两个 WWN 组均缺失或为空 array、`fsType: EXT4`、`lun: -1`、`readOnly: yes`、WWN 非 array 或含非 string 元素，渲染中断且消息前缀归属符合 `Decision: 失败消息边界`；对应 `验证设计` 关键失败项。
- [x] V4 `/tmp/sd-kube-chart/` 经 `definitions.volume` 字符串入口：`fc: "0 xfs targetWWNs (10:20:30:40:50:60:70:80) wwids (0x5001)"` 成功且与等价原生 map 一致，`fc: "xfs targetWWNs (...)"` 中断，`fc: "xfs wwids (...)"` 不含 `lun`，并核对 `fc` 契约注释包含三条组合边界；对应 `验证设计` 字符串入口项。
