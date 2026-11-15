# definitions.windowsSecurityContextOptions 任务

## 实施

- [x] T1 `templates/api-resources/Definitions/_WindowsSecurityContextOptions.tpl`：在 `definitions.windowsSecurityContextOptions` 中按官方字段顺序渲染四个可选字段，字符串字段归一后以引号标量输出，`hostProcess` 仅在其值为 `true` 时输出；对应 `WindowsSecurityContextOptions 字段片段渲染` 与 `hostProcess 布尔语义`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart（加载真实 library Chart）：渲染四个字段齐全且 `hostProcess: true` 的场景，断言输出顺序为 `gmsaCredentialSpec`、`gmsaCredentialSpecName`、`hostProcess`、`runAsUserName` 且类型正确；对应 `WindowsSecurityContextOptions 字段片段渲染`。
- [x] V2 同一 Chart：分别渲染仅提供 `gmsaCredentialSpecName`、全部缺省、字符串字段为空字符串或纯空白三类输入，断言只输出已提供字段、缺省时输出空内容；对应 `WindowsSecurityContextOptions 字段片段渲染`。
- [x] V3 同一 Chart：渲染 `hostProcess` 为 `false`、`"false"`、`"yes"` 与 `1` 的场景，断言前两者不产生该键、后两者渲染失败；对应 `hostProcess 布尔语义`。
- [x] V4 同一 Chart：渲染字符串字段为 map 的场景，断言渲染失败；对应 `WindowsSecurityContextOptions 字段片段渲染` 的失败边界。
