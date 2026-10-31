# 用户文档规则

- 根 `README.md` 至少包含安装或导入方式、核心原则、可用模板清单、最小示例、常见问题和迁移说明。
- `docs/` 和稳定样例只描述正式代码中已经实现、与所选 change 制品一致且有验证依据的用户可见行为。
- 未确认 `[AI 推断]`、开放问题、未实现规格、同步预览建议和孤立静态代码事实不得描述为已支持能力。
- `/opsx:code` 和 `/opsx:sync` 不修改最终用户文档；最终用户文档统一由 `/opsx:docs` 独立维护。
- `/opsx:docs <change-id>` 只处理 `openspec/changes/<change-id>/*.md` 明确涉及的行为；无 change-id 时处理 `openspec/changes/archive/` 下全部归档 change，并按正式代码过滤尚未实现或已经失效的内容。
- `/opsx:docs` 不使用聊天历史补全文档，也不修改 `openspec/changes/`、正式代码、values、Schema 或稳定样例。
- 父模板依赖未实现子模板时，只说明父模板契约和依赖，不宣称真实子模板集成可用。
- values 变更必须同步 `values.yaml`、Schema、用户文档和稳定样例；代码与配置目标列入 design write boundary，`docs/` 和根 `README.md` 由 `/opsx:docs` 按 change 范围独立更新。
- `/opsx:ck:publish` 负责检查正式代码、values、Schema、稳定样例和用户文档的一致性。
- 文档不得包含真实密钥、令牌、证书或私钥。
- 文件引用使用工作区相对路径，链接目标必须存在。
