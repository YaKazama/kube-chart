目标: 新增命名模板 `definitions.GroupVersionForDiscovery`，写入 `templates/api-resources/Definitions/_GroupVersionForDiscovery.tpl`。
需求:
- 入参：唯一上下文 `.`，类型为 dict（由 `definitions.APIGroup` 解析后传入）。
  - 上下文键与 K8s API 字段一致。
- 行为：按 K8s API 规范渲染 `groupVersion` / `version` 两个字段；不渲染 `status` / `metadata` 字段。
- 字段：
  - `groupVersion`：string, 必填项。
    - 格式：`group/version`。
    - 示例：`meta/v1`。
    - 渲染模板：`base.string`。
    - 校验：上游 `definitions.APIGroup` 已通过 `API_GROUP.GROUP_VERSION_DISCOVERY` 正则分组提取（`${1}`），本模板不再重复校验。
  - `version`：string, 必填项。
    - 格式：`version`，小写字母数字开头可包含点。
    - 示例：`v1.23.0`。
    - 渲染模板：`base.string`。
    - 校验：上游 `definitions.APIGroup` 已通过 `API_GROUP.GROUP_VERSION_DISCOVERY` 正则分组提取（`${2}`），本模板不再重复校验。
- 边界行为：
  - 必填项缺失或值为 `nil`（`base.get` 返回字符串 `"null"`）时立即中断并报错。
  - 字段未提供时静默跳过，不输出空键。
- 报错格式：`[definitions.GroupVersionForDiscovery] 字段路径: 错误原因`。
约束:
- 引用约束 `docs/rules/const-general.md`。
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等。
- 允许读取 `docs/samples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/group-version-for-discovery-v1-meta/#GroupVersionForDiscovery
  - https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#groupversionfordiscovery-v1-meta
- 示例代码：
  - 引用 `docs/rules/const-example-code.md`。
