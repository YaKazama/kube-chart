# definitions.probe 任务

## 实施

- [x] T1 `templates/base/_env.tpl`，writable scopes 为 `K8S` map 内新增的 `GRPC_ACTION` 键及其前置注释：新增 grpc 简写正则 `^\\s*(?:([^\\s,]+)[,\\s]+)?([^\\s,]+)\\s*$`（分隔符为空格或逗号）；对应 `Decision: grpc 简写解析`。
- [x] T2 `templates/api-resources/Definitions/_Probe.tpl`，writable scope 为新文件完整内容：新增 `definitions.probe` 及同文件私有模板 `definitions.probe.render`、`definitions.probe.integer`，实现动作互斥、动作空值拦截、动作形态归一与委托、整数阈值与官方字段顺序；对应 `Decision: 动作键收集与互斥`、`Decision: 生效动作空值与动作值派生`、`Decision: 动作形态归一`、`Decision: 动作子模板委托`、`Decision: grpc 简写解析`、`Decision: httpGet 与 tcpSocket 简写复用既有常量`、`Decision: integer 字段闭环`、`Decision: 字段顺序`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：仅提供 `failureThreshold: 3` 与 `timeoutSeconds: 5`，`helm template` 输出只包含这两个字段且不含动作字段。
- [x] V2 `/tmp/` 最小 application Chart：提供 `httpGet` 原生 map 与全部六个 integer 阈值，验证输出顺序为官方字段顺序。
- [x] V3 `/tmp/` 最小 application Chart + `definitions.grpcAction` fixture：分别提供 `exec` string array、含 headers 的 `httpGet` 字符串、`tcpSocket` 字符串（含与不含 `host`）、`grpc` 字符串 `grpc-health 8080`、逗号形态 `grpc-health,8080` 与原生 map，验证动作归一与委托。
- [x] V4 `/tmp/` 最小 application Chart + `definitions.grpcAction` fixture：覆盖多动作并存、`exec: null`、`exec: null` 与合法 `httpGet` 并存、`grpc: {}`、非法 `grpc` 简写、非法 `exec` 元素类型、integer 阈值为字符串／布尔／带小数数值／map，预期全部中断渲染。
