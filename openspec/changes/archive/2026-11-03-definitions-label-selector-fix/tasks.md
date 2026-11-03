# Definitions LabelSelector Fix 任务

## 实施

- [x] T1 `templates/base/_env.tpl`：把 `K8S.SELECTOR.EQUALITY_FOR_APPS`、`K8S.SELECTOR.SET_FOR_APPS`、`K8S.SELECTOR.EXISTS_FOR_APPS` 三处 key 捕获组改为 `([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)?)`，其余部分与捕获组编号保持不变；对应 `Decision: key 捕获组采用可选斜杠段`、`Decision: 捕获组编号与语义保持不变`、`Decision: 仅补斜杠结构，不放宽字段格式语义`。

## 验证

- [x] V1 `/tmp/` 最小 Chart 加载真实 `_env.tpl`，执行 `helm template` 断言回归：`app = web`、`app != web`、`app in (a)`、`app notin (a)`、`app`、`!app` 的匹配结果与修改前一致。
- [x] V2 `/tmp/` 最小 Chart 加载真实 `_env.tpl`，执行 `helm template` 断言新增能力：`app.kubernetes.io/name = web`、`app.kubernetes.io/name in (a, b)`、`app.kubernetes.io/name`、`!app.kubernetes.io/name` 三条正则均匹配成功。
- [x] V3 `/tmp/` 最小 Chart 加载真实 `_env.tpl`，执行 `helm template` 断言捕获提取：`mustRegexReplaceAll` 的 `${1}` 为 `app.kubernetes.io/name`，`${2}` 为操作符，`${3}` 为值；`EXISTS_FOR_APPS` 的 `${1}` 为 `!`、`${2}` 为 key。
- [x] V4 `/tmp/` 最小 Chart 加载真实 `_env.tpl`，执行 `helm template` 断言关键失败：`a/b/c`、`a/`、`/a` 在三条正则下均不匹配。
