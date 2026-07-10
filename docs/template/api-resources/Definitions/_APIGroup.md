目标: 新增命名模板 `definitions.APIGroup`，写入 `templates/api-resources/Definitions/_APIGroup.tpl`。
需求:
- 入参只有一个上下文 `.`。
- 字段：
  - `apiVersion`：string, 值 `meta/v1`，必填项。
  - `kind`：string, 值 `APIGroup`，必填项。
  - `name`：string, 必填项。
  - `preferredVersion`：string。
    - 引用模板 `definitions.GroupVersionForDiscovery` 。
    - 向下传递以空格分隔的字符串：`groupVersion(group/version) version`，例如：`meta/v1 v1.23.0`。
    - 正则校验；正则分组到 API_GROUP。
  - `serverAddressByClientCIDRs`：array([]string)。
    - 引用模板 `definitions.ServerAddressByClientCIDR` 。
    - 向下传递以空格分隔的字符串：`clientCIDR(client/cidr) serverAddress(server/address)`，例如：`10.0.0.0/24 10.0.0.1`。
      - 可用设置：hostname, hostname:port, IP or IP:port
    - 正则校验；正则分组到 API_GROUP。
    - 需要去重、去空。示例：`mustUniq | mustCompact`。
  - `versions`：array([]string), 必填项, 同 `preferredVersion` 字段。
    - 需要去重、去空。示例：`mustUniq | mustCompact`。
约束:
- 引用约束 `docs/template/const-general.md`。
- 允许读取`参考`提供的 URL ，通过 Field 和 Description 确认是否必填项及正则校验、可用设置、默认值、数量限制等。
- 允许读取 `docs/examples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- API：https://kubernetes.io/docs/reference/kubernetes-api/definitions/api-group-v1-meta/#APIGroup
- 示例代码：

  ```text
  ## apiVersion 和 kind 字段
  {{- nindent 0 "" -}}apiVersion: "meta/v1"
  {{- nindent 0 "" -}}kind: "APIGroup"
  ## metadata 字段, 示例
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}
  ```

  ```text
  ## 单行注释
  {{- /* 注释 */ -}}
  ## 多行注释
  {{- /*
    注释
    注释
  */ -}}
  ```
