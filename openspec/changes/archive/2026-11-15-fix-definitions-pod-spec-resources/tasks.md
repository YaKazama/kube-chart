# resources 支持从文件读取配置任务

## 实施

- [x] T0 `templates/base/_collection.tpl`：把 `base.map.dig` 的路径拆分由 `base.env` 的 `SPLIT.ALL` 改为 `splitList "."` 并同步契约注释，使点分路径不再按 `-`、`/` 等字符拆分；对应 Decision `路径取值复用 base.map.dig`。
- [x] T1 `templates/base/_fileRefs.tpl`：新建并定义 `base.fileRefs`，归一 array 与 map 形态，用 `base.path` 的 `rel` 模式校验并拒绝根目录逃逸，经 `Files` 读取文件并校验非空与合法 YAML mapping，`fieldPaths` 为空时按文件名去扩展名推导，逐路径委托 `base.map.dig` 取值并依空输出判定未命中，结果按 sequence、mapping、scalar 恢复，以“map 递归合并、其他类型整体覆盖”累加并以 `$hasResult` 标记输出；对应 Decision `文件读取与合并集中在 base.fileRefs`、`路径取值复用 base.map.dig`、`路径校验使用 base.path rel 模式并补充根目录逃逸检查`、`map 递归合并，其他类型整体覆盖`、`扩展名剥离不使用正则`、`空输出表示无有效项`。
- [x] T2 `templates/api-resources/Core/_PodSpec.tpl`：更新 `core.podSpec` 的 `resources` 区段，加入 `resourcesFileRefs` 取值与 `base.fileRefs` 调用，按输出是否为空回退到 `resources`，累加结果附加 `_kind=PodSpec` 后委托 `definitions.resourceRequirements`；对应 Decision `空输出表示无有效项`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart 加载真实 `templates/base/` 模板与 `_fileRefs.tpl`，以 `/opt/homebrew/bin/helm template` 执行 map 形态、array 多元素、省略 `fieldPaths`、多 `fieldPaths`、文件名无扩展名、含 `-` 键名路径、map 递归合并、同键覆盖与 slice/标量整体覆盖场景，断言合并结果；执行 `filePath` 缺失、空白、绝对路径、含 `..`、文件不存在、文件为空、非法 YAML、路径未命中场景，断言渲染中断。
- [x] V2 `/tmp/` 最小 application Chart 加载真实 `_PodSpec.tpl` 与 `_ResourceRequirements.tpl`，以 `/opt/homebrew/bin/helm template` 执行 array 与 map 形态的 `resourcesFileRefs`，断言输出资源字段；执行 `resourcesFileRefs` 缺失、为 `null`、无有效项三种场景，断言回退到内联 `resources`；执行两者均未设置、累加结果不是 map 两种场景，断言不输出 `resources` 与渲染中断。
- [x] V3 `/tmp/` 最小 application Chart 加载真实 `_collection.tpl`，以 `/opt/homebrew/bin/helm template` 回归 `base.slice.cleanup` 的默认 `SPLIT.ALL` 拆分结果，断言与改动前一致。
