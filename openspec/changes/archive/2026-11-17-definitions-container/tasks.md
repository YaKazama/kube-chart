# definitions.container 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Container.tpl`：新增 `definitions.container` 及同文件辅助模板 `definitions.container.array`、`definitions.container.struct`、`definitions.container.imageRef`，按官方字段顺序逐字段渲染 25 个字段，其中 13 个委托子模板、12 个直接渲染，`name` 经 `base.rfc` 的 `1123` 模式校验，`image` 按 `imageFileRefs` > `imageRefs` > `image` 三级解析并拼接，五个 `*FileRefs` 通过 `base.fileRefs` 覆盖对应内联字段；对应 `Container 字段片段渲染`、`image 三源解析`、`引用字段优先级`、`枚举字段校验` 与 `上下文契约`。
- [x] T2 `templates/api-resources/Core/_PodSpec.tpl`：把 `containers` 与 `initContainers` 两处 `include "definitions.container"` 的上下文改为 `mustMerge $_item (dict "os" $os) $containerExtras`，去掉 `containers` 包装键；对应 `上下文契约`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（加载真实 library Chart，unavailable 子模板使用同名 fixture）：渲染只含 `name` 与 `image` 的输入，断言输出只含这两个字段且 `image` 在前；渲染 25 字段齐全的输入，断言字段顺序与官方顺序一致；对应 `Container 字段片段渲染`。
- [x] V2 同一 Chart：渲染 `name` 缺失、为空字符串、纯空白、含大写字母、含下划线、以 `-` 开头与超 63 字符的输入，断言均渲染中断且不符合规则的消息给出校验规则；对应 `Container 字段片段渲染`。
- [x] V3 同一 Chart：渲染仅 `image`、`imageRefs` 与 `image` 并存、`imageRefs` 只给 `repository`、`tag` 与 `digest` 均空、`digest` 有值且 `tag` 空、`digest` 无 `sha256` 前缀、三者均空的输入，断言输出镜像引用符合拼接规则、末者渲染中断；对应 `image 三源解析`。
- [x] V4 同一 Chart：渲染 `imageFileRefs` 文件内容分别为对象与标量的输入，断言对象走拼接规则、标量直接作为镜像引用，且二者均覆盖 `imageRefs` 与 `image`；对应 `image 三源解析`。
- [x] V5 同一 Chart：渲染 `envFileRefs` 与 `env` 并存、`resourcesFileRefs` 与 `resources` 并存、FileRefs 无有效结果、`filePath` 缺失、`filePath` 为绝对路径与 `../` 逃逸的输入，断言 FileRefs 优先、无结果时回退、三类非法路径中断；对应 `引用字段优先级`。
- [x] V6 同一 Chart：渲染 `imagePullPolicy`、`restartPolicy`、`terminationMessagePolicy` 的合法值与小写变体，断言合法值输出、变体中断并给出合法范围；渲染 `stdin` 为 `false` 的输入，断言输出 `stdin: false`；对应 `枚举字段校验` 与 `Container 字段片段渲染`。
- [x] V7 同一 Chart：以真实 `core.podSpec` 的 `containers` 与 `initContainers` 入口各渲染一个容器，断言父模板回收正常、字段顺序正确，且上下文不含 `containers` 包装键；对应 `上下文契约`。
