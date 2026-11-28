# definitions.projectedVolumeSource 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ProjectedVolumeSource.tpl`：新增 `definitions.projectedVolumeSource` 契约注释与 define，按官方顺序实现 `defaultMode` 的取值、YAML 引号剥离、`base.fileMode` 归一化与 `base.int` 输出；写入范围限于该模板的契约注释与 define 块；对应 `Decision: defaultMode 复用既有 mode 归一化`。
- [x] T2 `templates/api-resources/Definitions/_ProjectedVolumeSource.tpl`：实现 `sources` 数组解析、条目 map 校验、逐项委托 `definitions.volumeProjection`、空结果剔除与 `mustUniq` 去重；写入范围限于该模板的契约注释与 define 块；对应 `Decision: sources 逐项委托并回收`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart：空 map 输出空内容；`defaultMode: "0644"` 输出 `defaultMode: 420`；`defaultMode: 0` 输出 `defaultMode: 0`。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart，使用同名 `definitions.volumeProjection` fixture：`defaultMode` 与多个 `sources` 同时输入时顺序为 `defaultMode`、`sources`；空渲染条目被剔除，完全相同的条目只保留首个并保持输入顺序；全部条目为空时不输出 `sources`。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart：`defaultMode: "9999"`、`sources` 为 map、`sources` 条目为 string、fixture 子模板返回非法 YAML 时均中断并报错。
