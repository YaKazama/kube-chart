---
change-id: fix-definitions-downward-api-volume-source-items
updated_at: "2026-11-24T14:17:52Z"
---

# definitions.downwardAPIVolumeSource items 过滤修正

## 目标

- 修正 `definitions.downwardAPIVolumeSource` 的 string item 处理：用现有 item 正则过滤出 `path`、可选 `mode` 与 `*Ref` 串后传给 `definitions.downwardAPIVolumeFile`；原生 map item 原样直传。

## 需求

- string item MUST 按 `K8S.VOLUME.DOWNWARD_API_FIELD_ITEM` 与 `K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM` 过滤，MUST NOT 新增平行正则。
- field 形态 MUST 传 `{path, [mode], fieldRef: "<fieldPath>[ <apiVersion>]"}`；resource 形态 MUST 传 `{path, [mode], resourceFieldRef: "<resource>[ <containerName>][ <divisor>]"}`；`*Ref` 串由捕获段以单个空格连接。
- 缺失的可选段 MUST NOT 写入对应键；纯空白 string item MUST 跳过。
- `path`、`mode` 与 `*Ref` 串 MUST 直接使用正则捕获结果，MUST NOT 额外 trim、归一化、做 YAML 标量解码或剥离引号。
- `*Ref` MUST 保持 string，MUST NOT 在本模板构造 `fieldRef`/`resourceFieldRef` map；其拆分与 `definitions.objectFieldSelector`/`definitions.resourceFieldSelector` 委托由 `definitions.downwardAPIVolumeFile` 负责。
- 原生 map item MUST 原样直传，MUST NOT 清洗、改写、深拷贝或调用孙模板。
- string item 不匹配任一形态时 MUST 中断渲染。
- 本 change 的契约为准，覆盖已归档 `definitions-downward-api-volume-source` 中“string item 以 `{item: <原始字符串>}` 原样包装”的规格。

## 期望输入格式

<!-- 只填写用户明确指定的本次特殊限制。 -->

## 约束

- 只调整 string item 的过滤与传递；`defaultMode`、map item 直传与子模板输出处理不变。
- 子模板 `definitions.downwardAPIVolumeFile` 仍不实现，items 在本 change 后仍不可真实渲染；验证使用同名回显 fixture。
- 不修改已归档制品；由本 change 的 `MODIFIED Requirements` 覆盖旧契约。

## 非目标

- 不实现 `definitions.downwardAPIVolumeFile`。
- 不在本模板构造、校验或清洗 `fieldRef`/`resourceFieldRef` 内部字段，也不处理两者互斥。
- 不归一化 `path`，不清洗原生 map item。
- 不保留已归档的 `{item: <原始字符串>}` 包装形态。

## 验收

- 输入 `["  meta 0400 field metadata.name  "]` → 子模板收到 `{path: "meta", mode: "0400", fieldRef: "metadata.name"}`。
- 输入 `["meta2 field metadata.name v1"]` → 子模板收到 `{path: "meta2", fieldRef: "metadata.name v1"}`，无 `mode`。
- 输入 `["cpu 0644 resource limits.cpu app 1m"]` → 子模板收到 `{path: "cpu", mode: "0644", resourceFieldRef: "limits.cpu app 1m"}`。
- 纯空白 string 跳过；原生 map item 原样直传，字段不被改写或补全。
- 格式不匹配的 string item 中断。

## 开放问题

- 暂无。
