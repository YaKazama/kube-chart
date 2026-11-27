# 移除 imageRefs 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Container.tpl`：删除 `imageRefs` 分支与 `definitions.container.imageRef`，将 `imageFileRefs` 解析结果限制为 string，并同步整体契约注释；对应 `image 来源解析`。

## 验证

- [x] V1 `/tmp/sd-kube-chart/` 最小 Chart 渲染仅提供 `image` 的容器，以及同时提供任意形态 `imageRefs` 的容器；`/opt/homebrew/bin/helm template` 均退出 0 并输出 `image`。
- [x] V2 `/tmp/sd-kube-chart/` 最小 Chart 使用 Chart 内 fixture 文件提供 `imageFileRefs` string 内容，并同时提供 `image`；`/opt/homebrew/bin/helm template` 输出文件中的镜像引用。
- [x] V3 `/tmp/sd-kube-chart/` 最小 Chart 覆盖失败输入：`imageFileRefs` 解析出 map、list 或其他非 string 值，以及 `image` 与 `imageFileRefs` 均无有效值；`/opt/homebrew/bin/helm template` 均非零退出。
