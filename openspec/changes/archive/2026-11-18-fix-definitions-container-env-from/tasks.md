# definitions.container envFrom 输入任务

## 实施

- [x] T1 `templates/base/_env.tpl`：在 `base.env` 的 `K8S` 段新增 `ENV_FROM` 键及紧邻注释，运行时表达式为 `^((?i:cm|configmap|secret))[,\s]+([^,\s]+)(?:[,\s]+([^,\s]+))?(?:[,\s]+([^,\s]+))?$`，源码层按 YAML 双引号转义为 `\\s`；writable scope 为该键与紧邻注释行；对应 `Decision: 字符串简写由单一捕获组正则解析`。
- [x] T2 `templates/api-resources/Definitions/_Container.tpl`：更新 `definitions.container` 契约注释的 `envFrom` 行、`envFrom` 字段注释与其后字段块，保留 `envFromFileRefs` > `envFrom` 取值，加入 `fromYamlArray` 恢复与错误门禁、`kindIs` 元素类型分支、`mustRegexMatch` + `mustRegexReplaceAll` 捕获解析、`dict` + `lower` 关键字映射、`prefix` 条件写入与 `mustToJson` 交回 `definitions.container.array`；writable scope 为契约注释的 `envFrom` 行与 `envFrom` 字段注释及其字段块；对应 `Decision: envFrom 取值来源与数组类型门禁`、`Decision: 元素类型分支与归一化回收`、`Decision: 字符串简写由单一捕获组正则解析`、`Decision: 关键字映射与大小写边界`、`Decision: 归一化元素构造`、`Decision: 归一化结果交回 definitions.container.array`、`Decision: 失败边界与消息`。

## 验证

- [x] V1 `/tmp/` 最小 application Chart：加载真实 `_Container.tpl`、`_env.tpl`、`_get.tpl`、`_convert.tpl`、`_field.tpl`、`_types.tpl`、`_fileRefs.tpl`、`_validate.tpl`、`_collection.tpl` 与 `definitions.envFromSource` 同名回显 fixture，渲染 `envFrom: [{configMapRef: "app-config"}]`，预期输出的 `envFrom` 数组项与输入一致且不失败；对应 `Decision: envFrom 取值来源与数组类型门禁`、`Decision: 元素类型分支与归一化回收`。
- [x] V2 同一 Chart：分别渲染 `["configMap app-config"]`、`["cm app-config"]`、`["secret db-secret"]`、`["CM app-config"]`、`["ConfigMap app-config"]` 与 `["SECRET db-secret"]`，预期引用键依次为 `configMapRef`、`configMapRef`、`secretRef`、`configMapRef`、`configMapRef`、`secretRef`，引用值分别为 `app-config` 或 `db-secret`，且结果 map 只含一个引用键；对应 `Decision: 关键字映射与大小写边界`、`Decision: 归一化元素构造`。
- [x] V3 同一 Chart：渲染 `["cm app-config /app"]`、`["secret db-secret /db true"]`、`["cm,app-config,/app"]`、`["cm   app-config ,  /app"]` 与 `["  cm app-config  "]`，预期前者得到 `{configMapRef: "app-config", prefix: "/app"}` 且无 `optional` 键，次者得到 `{secretRef: "db-secret true", prefix: "/db"}`，其余三项均得到 `{configMapRef: "app-config", prefix: "/app"}` 或 `{configMapRef: "app-config"}` 的对应结果；对应 `Decision: 字符串简写由单一捕获组正则解析`、`Decision: 归一化元素构造`。
- [x] V4 同一 Chart：分别渲染 `["cm App_Config"]` 与 `["cm app-config /app notabool"]`，预期本层不中断，引用值分别为 `App_Config` 与 `app-config notabool`；再渲染 string 与 map 元素混用的数组，预期按输入顺序输出且每个元素均为 map；对应 `Decision: 归一化元素构造`、`Decision: 元素类型分支与归一化回收`。
- [x] V5 同一 Chart：提供可读取的 `envFromFileRefs` 且文件内容含 string 元素，同时提供 `envFrom`，预期输出取自文件内容并按同一规则归一化；对应 `Decision: envFrom 取值来源与数组类型门禁`。
- [x] V6 同一 Chart：分别渲染 `envFrom: "cm app-config"`、`envFrom: {configMapRef: "app-config"}`、`envFrom: [{configMapRef: "app-config"}, 1]`、`["cm"]`、`[""]`、`["cm app-config /app true extra"]`、`["env app-config"]`、`["config app-config"]` 与 `["secretKey db-secret"]`，预期全部中断渲染且失败消息含 `envFrom`；对应 `Decision: 失败边界与消息`。
- [x] V7 同一 Chart：渲染缺失 `envFrom` 与 `envFrom: null`，预期均不输出 `envFrom` 且不失败；对应 `Decision: envFrom 取值来源与数组类型门禁`。
- [x] V8 同一 Chart：渲染 `["cm app-config true"]` 与 `["cm app-config false"]`，预期分别输出 `{configMapRef: "app-config", prefix: "true"}` 与 `{configMapRef: "app-config", prefix: "false"}`，不产生 `optional` 键；对应 `Decision: 字符串简写由单一捕获组正则解析` 的已验证语义边界。
