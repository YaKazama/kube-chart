# 通用开发约束

## 取值规范

- 只能使用 `base.get` 取值。
- 触发 `alias` 调用 `base.getWithAlias` 取值，别名优先级高。
- 无需 `trim` 删除空格。

## 类型渲染规范

不同类型字段的渲染统一使用对应基础模板，`base.get` 阶段不做强制类型转换：
- string 类型：不强制转换类型，使用 `base.string` 模板渲染。
- integer/int 类型：不强制转换类型，使用 `base.int` 模板渲染。
- boolean/bool 类型：不强制转换类型，使用 `base.bool` 模板渲染。
- object/map 类型：结合 `fromYaml` 处理，使用 `base.map` 模板渲染。
  - 需要处理 `版本兼容性(./const-boundary.md#版本兼容性)`。
- array/slice 类型：结合 `fromYamlArray`、`版本兼容性` 处理，使用 `base.slice` 模板渲染。
  - 需要处理 `版本兼容性(./const-boundary.md#版本兼容性)`。

## 模板委托与透传规则

- 字段支持多类型时，必须在上层模板中完成类型归一化处理：先统一解析规整为 dict，再透传给委托模板/子模板。
- 父模板向委托模板/子模板透传字段时，统一使用 dict 类型传递上下文。
- `spec` 字段向下传递时，使用原始上下文 `.` 或 `mustDeepCopy` 后的对象。
- 禁止创建未定义的模板。
- 禁止创建委托模板/子模板，仅名称占位使用。
- 模板名称需自行修复（末级目录前缀.小驼峰），特殊情况保持大写（如 `API`）。

## 正则解析原则

- 逐级解析原则：禁止在父模板中一次性解析，必须按字段层级拆分正则解析逻辑。
- 正则捕获组拆分使用 `mustRegexReplaceAll`，必须执行 `trim` 去除首尾空格后再使用。
- 正则表达式避免大小写敏感问题，默认统一使用小写 `(?i)` 标志。

## 工程与编码规范

- 字段处理和渲染顺序必须严格对齐 K8s 官方 API 的展示顺序，形成 “处理-渲染”单字段闭环；禁止批量集中处理所有字段后再统一渲染。
  - 例外情况：当字段之间存在强互斥或数据关联关系时，允许将关联字段集中处理后，再按 API 顺序渲染。
- 禁止实现 `status` 字段及相关逻辑。
- 所有验证操作必须在 `/tmp/` 目录下执行，禁止在工程目录内创建验证用文件/目录（如 `.verify/`）。
- 代码通过空行分隔不同功能模块，提升可读性；`{{- else if }}`、`{{- else }}` 语句前必须空行。
- 参考代码仅限 `docs/samples/` 与 `templates/` 目录下的 `.tpl` 文件。
- `base.env` 参考 `docs/samples/env.tpl`，仅提取必要逻辑写入 `templates/base/_env.tpl`，禁止全量复制。
- 正则表达式统一归入 `templates/base/_env.tpl` 目录，禁止在其他模板中直接使用正则表达式。
- 正则表达式定义需要添加注释，说明正则表达式定义的含义与使用场景。

## HELM 规范

### 内置函数

- 优先使用 `must` 函数。包括 `mustToJson`、`mustToPrettyJson`、`mustToRawJson`、`mustToToml`、`mustRegexMatch`、`mustRegexFindAll`、`mustRegexFind`、`mustRegexReplaceAll`、`mustRegexReplaceAllLiteral`、`mustRegexSplit`、`mustDateModify`、`mustToDate`、`mustMerge`、`mustMergeOverwrite`、`mustDeepCopy`、`mustFirst`、`mustRest`、`mustLast`、`mustInitial`、`mustAppend`、`mustPrepend`、`mustReverse`、`mustUniq`、`mustWithout`、`mustHas`、`mustCompact`、`mustSlice`。

### 命令规范

- `helm` 命令引用 `/opt/homebrew/bin/helm`，禁止遍历磁盘。

## 强制自检清单

代码实现完成后必须逐条确认：
- 字段顺序与 K8s 官方 API 完全一致。
- 遵循正则逐级解析原则，未跨层级一次性匹配。
- map 类型字段已兼容 Helm 4.2.2 `fromYaml` 缺陷。
- slice 类型字段已兼容 Helm 4.2.2 `fromYamlArray` 缺陷。
- 未实现本规范未定义的任何字段与逻辑。
- 检查并修复隐性 BUG。
