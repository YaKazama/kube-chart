# 新增 `definitions.hostAlias` 渲染模板任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `NET` 下新增 `NET.IPV4` 与 `NET.IPV6` 常量，表达式与 `Decision: 校验常量表达式` 一致（`IPV6` 含无压缩 IPv4 混合式分支与 `[0-9A-Za-z._-]` zone 字符集），既有键不改动；对应 `Decision: 校验常量集中到 base.env 并复用既有域名常量`、`Decision: 校验常量表达式`、`Dependency: base.env`。
- [x] T2 `templates/api-resources/Definitions/_HostAlias.tpl`：新增 `definitions.hostAlias` 与整体契约注释；按 `hostnames`、`ip` 顺序输出；`hostnames` 经 `fromYamlArray` 恢复并使用后缀判定排除解析错误后委托 `base.slice.cleanup` 清洗，再逐项执行 `kindIs "string"` 与 253 字符上限检查；`ip` 剥离引号后按 `NET.IPV4`/`NET.IPV6` 校验并以 `quote` 渲染；实现两者同空返回空内容、一空一非空中断；对应 `Decision: hostnames 元素清洗委托 base.slice.cleanup`、`Decision: 单标签纯数字由清洗后的类型门禁拦截`、`Decision: hostname 长度上限由模板层校验`、`Decision: 取值、空值收敛与字段输出`、`Decision: ip 使用 quote 渲染`、`Decision: hostnames 解析错误使用精确判定`。

## 验证

- [x] V1 `/tmp` 最小 application Chart：加载 `_HostAlias.tpl` 与真实 `templates/base`，执行 `helm template` 覆盖完整条目与两者皆空两种输入，确认完整条目按 `hostnames`、`ip` 顺序输出，两者皆空返回空内容。
- [x] V2 `/tmp` 最小 application Chart：执行 `helm template` 覆盖 `::`、`1::`、`2001:db8::`、`::1`、`::ffff:1.2.3.4`、`fe80::1%eth0.100` 与 `1:2:3:4:5:6:1.2.3.4`，把渲染结果交父级 `fromYaml` 解析，确认无解析错误且地址文本不变，同时确认 `hostnames` 先于 `ip` 且列表顺序保持。
- [x] V3 `/tmp` 最小 application Chart：执行 `helm template` 覆盖 `["a.example.com b.example.com,c.example.com"]` 与 `["b.example.com","a.example.com","b.example.com","c.example.com"]`，确认拆分结果与首次出现顺序。
- [x] V4 `/tmp` 最小 application Chart：执行 `helm template` 覆盖 CIDR `ip`、非法 `ip`、非字符串 `ip`、含 `*` 的 hostname、`a..b`、空字符串元素、非字符串元素、单标签纯数字、超过 253 字符、非数组 `hostnames` 与一空一非空输入，逐一确认渲染按预期中断。
- [x] V5 `/tmp` 最小 application Chart：执行 `helm template` 覆盖 `hostnames` 仅含 `errors.example.com`、`Error.example.com`、`error.example.com`、`myerror.io`、`provider-error.io` 与 `terror.example.com` 六种输入，确认均为合法域名、不视为解析错误并正常输出。
