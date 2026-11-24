# definitions.csiVolumeSource 定义模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_CSIVolumeSource.tpl`：新增 `definitions.csiVolumeSource` 与文件头整体契约注释，按 `driver`、`fsType`、`nodePublishSecretRef`、`readOnly`、`volumeAttributes` 顺序实现取值、归一、校验与渲染；对应 `Decision: 按 API 顺序逐字段闭环`、`Decision: nodePublishSecretRef 双形态归一与委托`、`Decision: 委托既有枚举与布尔校验`、`Decision: volumeAttributes 清洗与渲染通道`、`Decision: 失败消息边界`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 直接 include：传 `{driver: "csi.example.com"}`，输出仅含 `driver: "csi.example.com"`；对应 `验证设计` 最小有效项。
- [x] V2 `/tmp/sd-kube-chart/` 直接 include：五字段全量、string 与 map 两种 `nodePublishSecretRef`、`readOnly` 显式 `false` 与 `true`，输出字段、顺序与空值跳过符合预期；对应 `验证设计` 较完整有效项。
- [x] V3 `/tmp/sd-kube-chart/` 经 `definitions.volume`：csi string 与原生 map 两条入口渲染完整 Volume，`csi` 片段与直接 include 结果一致；对应 `验证设计` 较完整有效项。
- [x] V4 `/tmp/sd-kube-chart/` 关键失败：缺 `driver`、`driver` 非 string、`fsType: EXT4`、`readOnly: yes`、`volumeAttributes` 值非 string、`nodePublishSecretRef` 为数组与非法名称，渲染中断且消息前缀归属符合 `Decision: 失败消息边界`；对应 `验证设计` 关键失败项。
