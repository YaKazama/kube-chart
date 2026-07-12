目标: 新增命名模板 `base.field`，写入 `templates/base/_field.tpl`。
需求:
- 行为: 安全渲染 YAML 键值对，统一处理引号、枚举校验与多种类型输出；指定枚举时强制使用 `base.string`；仅在 val 非空时输出。
- 入参：`list <key> <value> [渲染模板] [允许值列表枚举]`。
  - `key`：键名，字符串，必填且非空。
  - `value`：需要渲染的值，任意类型，必填。
  - `渲染模板` (可选): 处理 value 的命名模板。
    - 默认值: `base.string`，执行 trim / 零折叠 / 特殊格式直通。
    - 数字类: `base.int` / `base.int64` / `base.float64`，数字原生输出。
    - 布尔类: `base.bool`。
    - 复合类型: `base.map` / `base.slice`。
    - 引号控制:
      - `quote`：强制添加双引号 (内部映射为 `base.string` + 引号)。
      - `squote`：强制添加单引号。
    - 容器 env 专用: `containers.env`，处理 containers 下 env 变量中的 value，为 `0/true/false/数值` 自动添加双引号 (内部路由至 `base.process.containers.env`)。
    - 其他模板名: 调用对应模板处理。
  - `允许值列表枚举` (可选): 枚举校验列表；指定时强制使用 `base.string` 作为渲染模板。
    - 逐一检查 value 的值: 匹配成功保留；匹配失败丢弃；都不匹配则报错。
- 字段类型默认行为 (与 `base.get` 对齐):
  - string: `base.string` 模板渲染。
  - integer/int: `base.int` 模板渲染。
  - boolean/bool: `base.bool` 模板渲染。
  - object/map: `base.map` 模板渲染。
  - array/slice: `base.slice` 模板渲染。
- 返回值: 序列化后的 YAML 键值对 (`key: value` 形式, 复杂类型换行缩进, 多行字符串使用 `|-` 块标量)。
约束:
- 引用约束 `docs/rules/const-general.md`。
- 必填项缺失则立即中断并报错，报错格式 `[模板名] 字段路径: 错误原因`。
- 允许读取 `docs/samples/` 和 `templates/` 目录下的 `tpl` 文件，获取示例代码。
参考:
- 示例代码:
  - 引用 `docs/rules/const-example-code.md`。
