# definitions.grpcAction 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_GRPCAction.tpl`，writable scope 为新文件完整内容：新增 `definitions.grpcAction`，按 `port` → `service` 顺序实现取值、可观察类型归一、命名端口校验、服务名省略与渲染；对应 `Decision: 字段取值与输出顺序`、`Decision: port 类型分派与命名端口校验`、`Decision: port 实现同步复现`、`Decision: service 归一与省略`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：仅提供 `port: 8080`，`helm template` 输出只包含 `port: 8080`，不输出 `service`。
- [x] V2 `/tmp/` 最小 application Chart：提供命名端口 `port: grpc` 与 `service: grpc.health.v1.Health`，验证 `port` 在前且以字符串输出，`service` 以字符串输出。
- [x] V3 `/tmp/` 最小 application Chart：分别提供 `port: "8080"` 与 `port: 8080`，验证两者均输出整数 `port`。
- [x] V4 `/tmp/` 最小 application Chart：覆盖 `port` 缺失、`null`、空字符串、`0`、`65536`、带小数数值、布尔、map、list、非法命名端口（大写、超过 15 字符、首尾 `-`、连续 `--`），以及 `service` 为布尔、数值、map、list，预期全部中断渲染。
