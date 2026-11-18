# definitions.lifecycle 生命周期模板任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_Lifecycle.tpl`：新增 `definitions.lifecycle`，实现 `postStart`/`preStop` 统一委托及 `stopSignal` 本地校验与渲染；对应 `生命周期 Handler 委托`、`stopSignal 校验与渲染`。
- [x] T2 `templates/api-resources/Definitions/_Container.tpl`：为 `definitions.container.struct` 增加可选 `extra` 合并，并在 lifecycle 委托中注入同源 `os`，同步相关契约注释与示例；对应 `父模板注入 os`。

## 验证

- [x] V1 `/tmp/` fixture `definitions.lifecycleHandler`：渲染包含 `postStart` 和非空 `preStop` 的 lifecycle，fixture 对 `preStop` 返回空结果；预期只输出 `postStart`，且不输出 `preStop` 或 `stopSignal`。
- [x] V2 `/tmp/` fixture `definitions.lifecycleHandler` + 真实 `core.podSpec`/`definitions.container`：渲染含 `postStart`、`preStop`、合法 `stopSignal` 且 `os.name: linux` 的容器；预期三个 lifecycle 字段均输出。
- [x] V3 `/tmp/` fixture `definitions.lifecycleHandler`：分别验证 `stopSignal` 缺少 `os.name`、`stopSignal` 大小写不匹配、`postStart` 非 map；预期 `helm template` 均非零退出。
