# 核心设计原则

本文件定义跨模板的设计取向；具体实现规则以引用的规则文件为唯一来源。

- **尽早报错**：必填缺失或类型非法时，通过 `required` 或 `fail` 快速中断渲染。详见 `const-general.md` 与 `const-boundary.md`。
- **类型唯一**：同一 `values.yaml` 字段保持固定类型，禁止以 string、list、dict 等多种类型复用。详见 `const-general.md`。
- **最小化传参**：禁止无意义透传 `.`；单值传标量，同构集合传 list，多维状态传 dict；业务模板传业务配置，base 层通用工具可传根上下文。详见 `const-general.md` 与 `template-architecture.md`。
- **状态隔离**：修改字典、列表或上下文，复用嵌套资源配置，或执行合并时，必须以 `mustDeepCopy` 隔离，严禁污染 `.Values`。详见 `const-general.md` 与 `core-capabilities.md`。
- **正则集中管理**：正则统一定义于 `templates/base/_env.tpl` 的全大写下划线嵌套字典；调用时经 `fromYaml` 读取后校验。简单正则可在父模板解析，复杂正则必须在子模板逐级解析。详见 `const-general.md`。
