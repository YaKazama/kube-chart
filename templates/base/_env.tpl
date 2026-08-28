{{- /*
  提供基础模板共用的常量集合。

  行为: 输出空字符串、分隔符、类型、网络、RFC、Kubernetes 与应用相关的正则常量。

  入参: 任意占位值；不读取其内容。

  边界: 仅声明静态 YAML 常量；不读取上下文、不执行校验，也不负责具体业务规则。

  返回值: 可由 fromYaml 解析的常量 Map。

  示例:
    {{- $const := include "base.env" "" | fromYaml }}
*/ -}}
{{- define "base.env" -}}
EMPTY_STR: ""
SPLIT:
  ALL: "\\s*[\\s:,./|*^@#-]+\\s*"
  COMMA: "\\s*,\\s*"
TYPES:
  INT: "^[+-]?\\d+$"
  POSITIVE_INT: "^\\d+$"
  ZERO: "^([+-]?)0+(\\d*)$"
  OCTAL_HEX: "^0(x|X|o|O)"
  PERCENT: "^\\d+(\\%)?$"
SYS:
  FILE_MODE: "^(0[0-7]{3}|0|[1-9]\\d|[1-4]\\d{2}|50\\d|51[0-1])$"
  YAML_QUOTED: "^['\"](.*)['\"]$"
NET:
  IP: "^((0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)\\.){3}(0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)(\\/\\d{1,2})?$"
  DOMAIN_NAME: "(?i)^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.|$))*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$"
RFC:
  RFC1035: "^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$"
  RFC1123: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$"
  RFC1035_RBAC: "^[a-zA-Z0-9]([a-zA-Z0-9._:-]{0,251}[a-zA-Z0-9])?$|^[a-zA-Z0-9]$"
  APISERVICE: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)*$"
K8S:
  QUANTITY: "^[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?$"
  TIME: "^[-+]?(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"
  FIELDS_V1: "^(\\.|f\\:[^\\:]+|i\\:\\d+|v\\:.+|k\\:.+)$"
  SELECTOR:
    EQUALITY0: "^([A-Za-z0-9._-]+)(?:\\s+([=]{1,2}|!=))(?:\\s+([A-Za-z0-9._-]+))$"
    # 集合选择器 (In/NotIn, 操作符大小写不敏感, 捕获 key/op/values)
    SET0: "^([A-Za-z0-9._-]+)(?:\\s+((?i)in|(?i)notin))(?:\\s+\\((.*?)\\))$"
    # 存在性选择器 (key / !key, 捕获 not 前缀和 key)
    SET_EXISTS: "^(!)?([A-Za-z0-9._-]+)$"
APPS:
  DEPLOYMENT:
    STRATEGY: "^(Recreate|RollingUpdate)(?:\\s+(.*))?$"
    ROLLING_UPDATE: "^(\\d+\\%?)?(?:\\s+(\\d+\\%?))?$"
API_GROUP:
  GROUP_VERSION_DISCOVERY: "^(\\S+\\/\\S+) +([a-z0-9][a-z0-9.]*)$"
  SERVER_ADDRESS_BY_CLIENT_CIDR: "^((?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?:/\\d{1,2})?)\\s+(\\S+)$"
{{- end }}
