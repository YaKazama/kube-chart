# definitions.tcpSocketAction 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_TCPSocketAction.tpl`，writable scope 为新文件完整内容：新增 `definitions.tcpSocketAction`，按 `host` → `port` 顺序实现取值、校验、类型分派与渲染；对应 `Decision: 字段取值与输出顺序`、`Decision: host 联合校验`、`Decision: port 类型分派与命名端口校验`、`Decision: 实现同步复现`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：仅提供 `port: 8080`，`helm template` 输出只包含数值 `port`，不输出 `host`。
- [x] V2 `/tmp/` 最小 application Chart：提供 IPv6 `host` 与命名 `port: http`，验证 `host` 在前且命名端口以字符串输出。
- [x] V3 `/tmp/` 最小 application Chart：分别提供域名与 IPv4 `host`，配合纯数字字符串 `port: "8080"`，验证主机校验与端口数值归一。
- [x] V4 `/tmp/` 最小 application Chart：覆盖缺少 `port`、`port: 0`、`port: 65536`、带小数数值 `port`、非法命名端口（大写、超过 15 字符、首尾 `-`、连续 `--`）、CIDR 或 URL `host`、非字符串 `host`，预期全部中断渲染。
