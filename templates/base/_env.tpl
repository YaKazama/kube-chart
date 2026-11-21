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
  SPACE_COMMA: "\\s*[,\\s]+\\s*"
  SPACE_COMMA_SEMICOLON: "\\s*[;,\\s]+\\s*"
  SPACE: " +"
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
  # 标准点分十进制 IPv4，四段各 0-255 且不含前导零，不接受 CIDR 后缀
  IPV4: "^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$"
  # 标准 IPv6，覆盖压缩与非压缩形式、IPv4-mapped、无压缩 IPv4 混合式与 %zone 后缀，不接受 CIDR
  IPV6: "^(([0-9A-Fa-f]{1,4}:){6}((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])|([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2}|([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3}|([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4}|([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5}|[0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6})|:((:[0-9A-Fa-f]{1,4}){1,7}|:)|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])|([0-9A-Fa-f]{1,4}:){1,4}:((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9]))(%[0-9A-Za-z._-]{1,})?$"
  DOMAIN_NAME: "(?i)^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.|$))*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$"
RFC:
  RFC1035: "^[a-z]([-a-z0-9]{0,61}[a-z0-9])?$"
  RFC1123: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?$"
  RFC1123_SUBDOMAIN: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)*$"
  RFC1035_RBAC: "^[a-zA-Z0-9]([a-zA-Z0-9._:-]{0,251}[a-zA-Z0-9])?$|^[a-zA-Z0-9]$"
  APISERVICE: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)*$"
K8S:
  QUANTITY: "^[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?$"
  # IANA_SVC_NAME 的字符、首尾与连续连字符约束；长度与字母要求由调用方校验
  IANA_SVC_NAME: "^[a-z0-9]+(-[a-z0-9]+)*$"
  # IANA_SVC_NAME 至少包含一个字母
  IANA_SVC_NAME_LETTER: "[a-z]"
  # ObjectFieldSelector.fieldPath 在 EnvVarSource 与 DownwardAPIVolumeFile 中的官方支持路径并集
  FIELD_REF: "^(metadata\\.(name|namespace|uid)|metadata\\.(labels|annotations)\\['[^']+'\\]|spec\\.(nodeName|serviceAccountName)|status\\.(hostIP|podIP|podIPs))$"
  # ResourceFieldSelector.resource 在 EnvVarSource 中的官方支持资源名
  RESOURCE_FIELD: "^(limits|requests)\\.(cpu|memory|ephemeral-storage)$"
  # ResourceFieldSelector.divisor 在 cpu 类资源下的允许形态：依次捕获整数毫核、整数核值与可选小数部分
  DIVISOR_CPU: "^(?:(\\d+)m|(\\d+)(?:\\.(\\d{1,3}))?)$"
  # ResourceFieldSelector.divisor 在 memory 与 ephemeral-storage 类资源下的允许形态：数值必须带字节单位
  DIVISOR_SIZE: "^\\d+(\\.\\d{1,3})?(?:Ki|Mi|Gi|Ti|Pi|Ei|k|M|G|T|P|E)$"
  # Secret.data 与 ConfigMap.data 的键字符集，不限首尾字符与长度
  DATA_KEY: "^[-._a-zA-Z0-9]+$"
  # Linux capability 名称：可选 CAP_ 前缀，大小写不敏感；只校验字符形态，不校验已知集合
  CAPABILITY_NAME: "^(?i:cap_)?[A-Za-z][A-Za-z0-9_]*$"
  # ContainerPort 字符串简写，依次捕获 hostIP、hostPort、containerPort、protocol 与 name；分隔符 , / # 两侧不允许空白，hostIP 段必须含 . 或 :
  CONTAINER_PORT: "^(?:([^,\\s/#]*[.:][^,\\s/#]*),)?(?:(\\d+),)?(\\d+)(?:/([^,\\s/#]+))?(?:#([^,\\s/#]+))?$"
  # ContainerRestartRule 字符串简写，依次捕获 action、operator 与括号内 values 原文；action 大小写不敏感，operator 为非空 token 且由子模板校验，段间分隔符为空白或逗号
  CONTAINER_RESTART_RULE: "^((?i:restart))[\\s,]+([^\\s,()]+)[\\s,]+\\(([^()]+)\\)$"
  # envFrom 字符串简写，依次捕获关键字、name、可选 prefix、可选 optional
  ENV_FROM: "^((?i:cm|configmap|secret))[,\\s]+([^,\\s]+)(?:[,\\s]+([^,\\s]+))?(?:[,\\s]+([^,\\s]+))?$"
  # Probe grpc 字符串简写，依次捕获可选 service 与必填 port，分隔符为空白或逗号
  GRPC_ACTION: "^\\s*(?:([^\\s,]+)[,\\s]+)?([^\\s,]+)\\s*$"
  LIFECYCLE_HANDLER:
    # LifecycleHandler httpGet 字符串简写，依次捕获 schema、host、port、path 与 headers 括号内容
    HTTP_GET: "^\\s*([^,\\s]*?)(?:[,\\s]+([^,\\s]*?))?(?:[,\\s]+([^,\\s]*?))?(?:[,\\s]+([^,\\s]*?))?(?:[,\\s]+headers[,\\s]*\\((.*)\\))?\\s*$"
    # LifecycleHandler tcpSocket 字符串简写，依次捕获可选 host 与 port
    TCP_SOCKET: "^\\s*(?:([^,\\s]+)[,\\s]+)?([^,\\s]+)\\s*$"
  RESOURCE:
    # 资源简写中的括注，只匹配一对不含嵌套括号的分组
    HUGE_PAGES_PAIR: "\\([^()]*\\)"
    # hugepages 量值，依次捕获数值与可选二进制单位
    HUGE_PAGES_QUANTITY: "^(\\d+)(Ki|Mi|Gi|Ti|Pi|Ei)?$"
    # cpu 量值，依次捕获整数部分、可选小数部分与可选毫核后缀
    CPU: "^(\\d+)(\\.\\d{1,3})?(m?)$"
  TIME: "^[-+]?(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"
  FIELDS_V1: "^(\\.|f\\:[^\\:]+|i\\:\\d+|v\\:.+|k\\:.+)$"
  # VolumeDevice 字符串简写，依次捕获 name 与 devicePath；分隔符为空白或逗号，允许首尾与连续分隔符，最多两个非空段
  VOLUME_DEVICE: "^[,\\s]*([^,\\s]*)(?:[,\\s]+([^,\\s]*))?[,\\s]*$"
  VOLUME:
    SHORT: "^((?i:cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi))(?:\\s+(.*?))(?:\\s+(.*?))?$"
  SELECTOR:
    EQUALITY_FOR_APPS: "^([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)?)(?:\\s+([=]{1,2}|!=))(?:\\s+([A-Za-z0-9._-]+))$"
    # 集合选择器 (In/NotIn, 操作符大小写不敏感, 捕获 key/op/values)
    SET_FOR_APPS: "^([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)?)(?:\\s+((?i)in|(?i)notin))(?:\\s+\\((.*?)\\))$"
    # 存在性选择器 (key / !key, 捕获 not 前缀和 key)
    EXISTS_FOR_APPS: "^(!)?([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)?)$"
    # NodeSelectorTerm 条目, 依次捕获 ! 前缀、key、运算符、values 原文; 运算符大小写不敏感, 裸 key 与 !key 无运算符段, key 语法由 KEY_NAME_FOR_APPS / KEY_PREFIX_FOR_APPS 校验
    NODE_TERM_FOR_APPS: "(?i)^(!?)([^\\s()!]+)(?:\\s+(notin|in|!=|==|=|>|<)\\s+(.+))?$"
    # NodeSelectorTerm values 原文, 仅允许括号列表或单个不含空白、逗号与括号的 token
    NODE_TERM_VALUES_FOR_APPS: "^(\\([^()]*\\)|[^\\s,()]+)$"
    # 标签键名称段 (1-63 字符, 首尾字母数字, 中间允许 -_.)
    KEY_NAME_FOR_APPS: "^[A-Za-z0-9]([-A-Za-z0-9_.]{0,61}[A-Za-z0-9])?$"
    # 标签键前缀段 (点分隔 DNS 标签序列, 每段 1-63 字符, 仅小写字母数字和 -)
    KEY_PREFIX_FOR_APPS: "^[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?)*$"
APPS:
  DEPLOYMENT:
    STRATEGY: "^(?:((?i:recreate|rollingupdate)|\"\"|''))?(?:\\s*[\\s:,/|*^@#]+\\s*|\\s*)(\"\"|''|\\d+%?)?(?:\\s*[\\s:,/|*^@#]+\\s*|\\s*)(\"\"|''|\\d+%?)?$"
  ROLLING_UPDATE:
    MAX_SURGE: "^\\d+(?:%)?$"
    MAX_UNAVAILABLE: "^(?:\\d+|0*(?:100|\\d{1,2})%)$"
API_GROUP:
  GROUP_VERSION_DISCOVERY: "^(\\S+\\/\\S+) +([a-z0-9][a-z0-9.]*)$"
  SERVER_ADDRESS_BY_CLIENT_CIDR: "^((?:[0-9]{1,3}\\.){3}[0-9]{1,3}(?:/\\d{1,2})?)\\s+(\\S+)$"
{{- end }}
