目标: 新增命名模板 `definitions.APIGroup`，写入 `templates/api-resources/Definitions/_APIGroup.tpl`。
需求:
- 入参只有一个上下文 `.`。
- 字段：
  - `apiVersion`：string, 值 `meta/v1`，必填项。
  - `kind`：string, 值 `APIGroup`，必填项。
  - `name`：string, 必填项。
  - `preferredVersion`：string。
    - 引用模板 `definitions.GroupVersionForDiscovery` 。
    - 向下传递上下文为 dict 类型。示例：`dict "groupVersion" "meta/v1" "version" "v1.23.0"`。
    - 正则校验；正则分组到 API_GROUP。
      - 格式：`groupVersion(group/version) version`
      - 示例：`meta/v1 v1.23.0`
  - `serverAddressByClientCIDRs`：array([]string)。
    - 引用模板 `definitions.ServerAddressByClientCIDR` 。
      - 结果要去重、去空。示例：`mustUniq | mustCompact`。
      - 向下传递上下文为 dict 类型。示例：`dict "clientCIDR" "10.0.0.0/24" "serverAddress" "10.0.0.1"`。
        - This can be a hostname, hostname:port, IP or IP:port.
    - 正则校验；正则分组到 API_GROUP。
      - 格式：`clientCIDR serverAddress`
      - 示例：`10.0.0.0/24 10.0.0.1`
  - `versions`：array([]string), 必填项, 同 `preferredVersion` 字段。
    - 结果要去重、去空。示例：`mustUniq | mustCompact`。
    - 向下传递上下文为 dict 类型。示例：`dict "groupVersion" "meta/v1" "version" "v1.23.0"`
约束:
- 引用约束 `docs/template/const-general.md`。
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等。
- 允许读取 `docs/examples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- API：
  - https://kubernetes.io/docs/reference/kubernetes-api/definitions/api-group-v1-meta/#APIGroup
- 示例代码：
  - 引用 `docs/template/const-example-code.md`。
