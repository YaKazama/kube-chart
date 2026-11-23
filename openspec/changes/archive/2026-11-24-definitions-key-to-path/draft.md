---
change-id: definitions-key-to-path
updated_at: "2026-11-23T16:35:26Z"
---

# definitions.keyToPath

## 目标

- 新增 `definitions.keyToPath`，把 `{key, path, mode}` map 渲染为 Kubernetes KeyToPath 字段片段，供 configMap、secret 等 VolumeSource 使用。

## 需求

- 上下文为 map；原生 map 与父模板清洗后的 map 结构相同，按同一方式处理。
- 只读取 `key`、`path`、`mode` 三个字段，其他字段静默忽略。
- `key` 必填，按 ConfigMap/Secret data key 的字符集规则校验；为空或非法时中断。
- `path` 必填，通过公共路径能力归一化为相对路径并拒绝绝对路径。
  - 归一化结果不得为 `..`，也不得以 `../` 开头；命中时中断。
  - `path` 为空时中断。
- `mode` 选填，类型与语义沿用父模板说明：接受八进制 `0000`-`0777` 或十进制 `0`-`511`，输出十进制 int；空值不渲染，非法值中断。
- 字段按官方文档顺序输出：`key`、`mode`、`path`。
- 非 map 上下文、空字符串与其他错误类型必须中断报错。

## 验收

- 输入合法 `{key, path}` 时按 `key`、`path` 顺序渲染。
- `mode` 存在时渲染为十进制 int，且位于 `key` 与 `path` 之间。
- `key` 或 `path` 缺失、为空或非法时中断。
- `path` 为绝对路径，或归一化结果为 `..` 或以 `../` 开头时中断。
- 非 map 上下文、空字符串或错误类型中断报错。
- `key`、`path`、`mode` 以外的字段不参与输出。

## 非目标

- 不实现本模板之外的 Definitions 能力，也不负责 ConfigMap/Secret 的数据读取。

## 开放问题

- 暂无。
