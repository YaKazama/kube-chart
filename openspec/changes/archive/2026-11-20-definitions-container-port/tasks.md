# definitions.containerPort 任务

## 实施

- [x] T1 `templates/base/_env.tpl`，writable scope 为 `base.env` 常量 Map 的 `K8S.CONTAINER_PORT` 键：新增简写正则常量，依次捕获 `hostIP`、`hostPort`、`containerPort`、`protocol`、`name`；对应 `Decision: 单正则位置解析`。
- [x] T2 `templates/api-resources/Definitions/_ContainerPort.tpl`，writable scope 为新文件完整内容：新增 `definitions.containerPort`，实现 string 与 map 双形态分派并归一为同一组字段，再按 `containerPort` → `hostIP` → `hostPort` → `name` → `protocol` 逐字段校验与渲染；对应 `Decision: 上下文双形态分派与字段归一化`、`Decision: 单正则位置解析`、`Decision: 端口校验复用 base.port`、`Decision: hostIP 内联双正则`、`Decision: name 复用 IANA 常量`、`Decision: protocol 大写归一与枚举`、`Decision: 固定顺序与逐字段直白写法`。
- [x] T3 `templates/api-resources/Definitions/_Container.tpl`，writable scope 为 `definitions.container.array` 整体与 `definitions.container` 中 `ports` 字段的注释及 `include` 调用行：为 `definitions.container.array` 增加默认关闭的 `allowString` 放行 string 元素，并在 `ports` 调用处开启；对应 `Decision: container.array 可选 string 放行`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：真实 `base.*` 依赖下渲染 `8080`，输出只含 `containerPort: 8080`。
- [x] V2 `/tmp/` 最小 application Chart：渲染 `127.0.0.1,8080,80/tcp#http` 与 `::1,8080,80/udp#dns`，验证五字段顺序、IPv6 `hostIP` 与 `protocol: "TCP"`、`protocol: "UDP"`。
- [x] V3 `/tmp/` 最小 application Chart：渲染 `8080,80` 与 `127.0.0.1,80`，验证 `hostPort` 与 `hostIP` 的位置识别互不牽连。
- [x] V4 `/tmp/` 最小 application Chart：覆盖空输入、含空白（`8080, 80`、`127.0.0.1 ,8080,80`）、多余分隔符（`1,2,3,4`、`8080,80/`）、端口 `0`、`65536`、`65537`、域名与 CIDR `hostIP`、非法 `name`（大写、首尾 `-`、连续 `--`、`123`、超 15 字符）、非枚举 `protocol`，预期全部中断渲染。
- [x] V5 `/tmp/` 最小 application Chart：加载真实 `_Container.tpl`，`ports` 为 `["80", "8080,80"]` 与 `["80", {containerPort: 443, name: https}]`，验证 string 简写与 map 混用均渲染为完整 `ContainerPort` 片段且顺序与输入一致。
- [x] V6 `/tmp/` 最小 application Chart：同一真实 `_Container.tpl` 下 `volumeMounts` 提供 string 元素，预期仍中断渲染，确认 `allowString` 默认关闭。
- [x] V7 `/tmp/` 最小 application Chart：直接以 map 为上下文渲染，覆盖 `{containerPort: 8080}`、五字段完整 map、缺少 `containerPort`、`hostPort: 0`、域名 `hostIP`、非法 `name`、非枚举 `protocol`、非 string 非 map 上下文，验证输出顺序与失败边界。
