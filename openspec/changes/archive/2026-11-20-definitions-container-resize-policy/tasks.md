# definitions.containerResizePolicy 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_ContainerResizePolicy.tpl`，writable scope 为新文件完整内容：新增 `definitions.containerResizePolicy`，实现 string 与 map 双形态分派并归一为同一组字段，string 分支不剔除空段、多于 2 段时中断，再按 `resourceName` → `restartPolicy` 逐字段校验与渲染；对应 `Decision: 上下文双形态分派与字段归一化`、`Decision: 位置拆分复用 SPLIT.SPACE_COMMA`、`Decision: 枚举校验复用 base.field`、`Decision: 固定顺序与逐字段直白写法`。
- [x] T2 `templates/api-resources/Definitions/_Container.tpl`，writable scope 为 `definitions.container` 中 `resizePolicy` 字段的注释与 `include` 调用行、整体契约注释中对应的 `resizePolicy` 说明，以及「数组字段非 array 或元素非对象时中断」一句的元素类型描述：为 `resizePolicy` 调用追加 `"allowString" true`，并同步三处注释使数组元素类型描述与 `ports`、`resizePolicy` 实际支持的 string 元素一致；对应 `Decision: resizePolicy 调用开启 allowString`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：string `cpu` 与 map `{resourceName: cpu}`，输出只含 `resourceName: "cpu"`。
- [x] V2 `/tmp/` 最小 application Chart：`cpu,NotRequired`、`memory RestartContainer`、`  cpu,, NotRequired  `，验证逗号与空白混用、连续分隔符与两侧空白，输出顺序为 `resourceName` → `restartPolicy`。
- [x] V3 `/tmp/` 最小 application Chart：map `{resourceName: memory, restartPolicy: RestartContainer}` 与 `{resourceName: cpu, note: anything}`，验证与等价 string 输出一致且额外键被忽略。
- [x] V4 `/tmp/` 最小 application Chart：覆盖空 string、三段 `cpu NotRequired extra`、`CPU`、`Memory`、`gpu`、`storage`、`notrequired`、`Always`、非 string 的 `resourceName` 与 `restartPolicy`、缺少 `resourceName` 的 map、非 string 非 map 上下文，预期全部中断渲染。
- [x] V5 `/tmp/` 最小 application Chart：加载真实 `_Container.tpl`，`resizePolicy` 为 `["cpu", "memory RestartContainer"]` 与 `["cpu", {resourceName: memory, restartPolicy: RestartContainer}]`，验证 string 简写与 map 混用均渲染为完整 `ContainerResizePolicy` 片段且顺序与输入一致。
- [x] V6 `/tmp/` 最小 application Chart：同一真实 `_Container.tpl` 下 `resizePolicy` 元素为 `["cpu", 1]`，预期中断渲染，确认仅放行 string 与 map。
- [x] V7 `/tmp/` 最小 application Chart：`cpu,` 输出只含 `resourceName`，`,cpu` 中断渲染，确认空段按位置参与必填与可选项判断。
