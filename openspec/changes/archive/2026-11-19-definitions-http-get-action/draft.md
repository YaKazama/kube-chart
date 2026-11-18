---
change-id: definitions-http-get-action
updated_at: "2026-11-18T17:05:36Z"
---

# definitions.httpGetAction

## 目标

- 新增命名模板 `definitions.httpGetAction`，处理 HTTPGetAction 上下文。
- 为 `definitions.httpHeader` 提供调用边界；子模板只占位，不在本 change 创建。

## 需求

- 上下文为 map，字段包括 `host`、`httpHeaders`、`path`、`port`、`scheme`。
- `host` 为主机名、IPv4 或 IPv6 地址。
- `httpHeaders` 为原生 HTTPHeader array 时，元素必须是包含 `name` 与 `value` 的 map，并逐个向下传给子模板 `definitions.httpHeader`。
- `httpHeaders` 为非原生形态时，类型是父级模板处理后的 string array，每个元素必须恰好拆分为两个以空格分隔的非空 token，分别作为 `name`、`value` 并组成新的 map 向下传递；token 数不是 2 时中断渲染。
- `path` 使用 `base.path` 的 `uri` 模式校验；用户输入中的 `baes.path` 按现有能力名称修正为 `base.path`。
- `port` 必填，可以是名字，也可以是 integer；为 integer 或纯数字字符串时范围必须为 1-65535；为名称时必须符合完整 Kubernetes `IsValidPortName` 规则。
- `host`、`httpHeaders`、`path`、`scheme` 为可选字段。
- `scheme` 按大小写不敏感识别 HTTP、HTTPS，渲染时必须强制转为全大写。
- `scheme` 按大小写不敏感比较后仍不属于 HTTP、HTTPS 时必须中断渲染。
- 输出字段顺序遵循 Kubernetes `HTTPGetAction` 官方顺序。

## 校验调研

- `base.port` 可用于数值端口：接受数值或纯数字字符串并校验 1-65535，不处理命名端口。
- `base.net` 的 `dns` 模式可校验域名或 IPv4，不支持 IPv6；本 change 允许扩展处理以满足 `host` 的 IPv6 校验。
- 本地 Kubernetes v1.36 `HTTPGetAction` 文档规定 `port` 的命名值必须是 `IANA_SVC_NAME`，但未对 `host` 给出主机名或 IP 的具体语法约束。
- Kubernetes release-1.36 `IsValidPortName` 对 `IANA_SVC_NAME` 的完整要求是：非空、长度不超过 15、仅含 `[-a-z0-9]`、至少包含一个 `[a-z]`、不得以 `-` 开头或结尾、不得包含连续 `--`。
- 现有公共模板没有可直接复用的完整 `IANA_SVC_NAME` 校验规则。

## 期望输入格式

```yaml
host: string
httpHeaders: <HTTPHeader array> or string array
path: string
port: string or int
scheme: string
```

## 约束

- 子模板 `definitions.httpHeader` 只在本模板中占位，不在本 change 创建。
- 子模板上下文由本模板构造并向下传递。
- `httpHeaders` 的 string array 形态已经是父级模板处理后的结果。
- `host` 校验必须支持 IPv6；现有 `base.net` 的 `dns` 模式不足，本 change 允许扩展处理。

## 非目标

- 不创建 `definitions.httpHeader`。
- 不处理 `definitions.lifecycleHandler` 的动作分派或其他动作字段解析。

## 验收

- `definitions.httpGetAction` 可按字段契约接收 map 上下文。
- `host` 提供时接受主机名、IPv4 或 IPv6 地址；`path`、`port`、`scheme` 按约定归一化或校验。
- `httpHeaders` 的原生 array 与字符串形态分别形成正确的 `definitions.httpHeader` 调用上下文。
- `httpHeaders` 字符串元素不是恰好两个空格分隔的 token 时中断渲染。
- `scheme` 输出为全大写枚举值。
- `port` 缺失或非法时中断，合法 integer 保持 1-65535 范围，命名端口不符合完整 `IsValidPortName` 规则时中断。
- 输出字段顺序与 Kubernetes `HTTPGetAction` 官方顺序一致。
