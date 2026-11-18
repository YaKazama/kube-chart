# definitions.httpGetAction 任务

## 实施

- [x] T1 `templates/base/_env.tpl`，writable scopes 为 `SPLIT` 与 `K8S` map 内的精确新增键：新增 `SPLIT.SPACE`、`K8S.IANA_SVC_NAME`、`K8S.IANA_SVC_NAME_LETTER`；对应 `Decision: httpHeaders 双形态归一与委托` 与 `Decision: port 数值与命名分派`。
- [x] T2 `templates/base/_validate.tpl`，writable scopes 为 `base.net` 前置注释块与 `dns` 分支：将 `base.net` 的 `dns` 模式更新为严格 IPv4、IPv6 或域名校验并拒绝 CIDR；对应 `Decision: host 联合校验`。
- [x] T3 `templates/api-resources/Definitions/_HTTPGetAction.tpl`，writable scope 为新文件完整内容：新增 `definitions.httpGetAction`，实现字段顺序、可选字段省略、host、httpHeaders、path、port、scheme 与子模板委托；对应 `字段输出与顺序`、`httpHeaders 解析与委托`、`port 校验` 等 Requirement。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：仅提供 `port: 8080`，`helm template` 输出只包含数值 `port`，不输出其他字段。
- [x] V2 `/tmp/` 最小 application Chart + `definitions.httpHeader` fixture：提供 IPv6 `host`、原生 HTTPHeader map array、绝对 `path`、命名 `port` 与小写 `scheme`，验证字段顺序、IPv6、委托、命名端口和大写归一。
- [x] V3 `/tmp/` 最小 application Chart + `definitions.httpHeader` fixture：提供域名或 IPv4 `host`、string array `httpHeaders` 与纯数字字符串 `port`，验证空格拆分、委托与数值归一。
- [x] V4 `/tmp/` 最小 application Chart + `definitions.httpHeader` fixture：覆盖缺少端口、数值越界、非法命名端口、CIDR/非法 host、相对 path、非法 scheme、混用或缺少键的 headers、字符串 token 数不是 2、子模板非法 YAML，预期全部中断渲染。
- [x] V5 `/tmp/` 最小 application Chart：直接渲染 `base.net` 的 `dns` 模式，确认 IPv6 被接受、CIDR 被拒绝且 IPv4 与域名保持可用。
