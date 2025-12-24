{{- /*
  constants 常量：集中管理命名模板所需的常量定义
  注：有一部分正则表达式定义分布在各个命名模板中，仅适用于该命名模板内部
*/ -}}
{{- define "base.env" -}}
# 默认空字符
emptyStr: ""
# 常用分隔符
split:
  all: "\\s*[\\s\\:\\.\\|\\/\\*\\^@#,]+\\s*"
  space: "\\s+"
  comma: ",\\s*"
  commaOrSpace: ",\\s*|\\s+"
  equal: "=+"
# 类型相关
types:
  int: "^[+-]?\\d+(\\.\\d+)?$"
  positiveInt: "^\\d+$"
  zero: "^([+-]?)0+(\\d*)$"
  octalHex: "^0(x|X|o|O)"
  percent: "^\\d+(\\%)?$"
rfc:
  RFC1035: "^([a-z]{1,63}|[a-z][a-z0-9-]{0,61}[a-z0-9]?)$"
  RFC1123: "^([a-z0-9]{1,63}|[a-z0-9][a-z0-9-]{0,61}[a-z0-9]?)$"
  RFC1035RBAC: "^([a-z]{1,63}|[a-z][a-z0-9-\\:]{0,61}[a-z0-9]?)$"
  APIService: "^[a-z]([-a-z0-9]*[a-z0-9])?(\\.[a-z]([-a-z0-9]*[a-z0-9])?)*$"
k8s:
  rbac:
    subject: "^(User|Group|ServiceAccount)(?:\\s+(\\S+))(?:\\s+(\\S+))?$"
    # 未使用，作为 RoleBinding 或 ClusterRoleBinding 下的 roleRef 的参考
    role: "^(.*?)(?:\\s(.*?))?(?:\\s(.*?))?$"
  reservedNamespace: "^(default|kube-.*)$"
  quantity: "^[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?$"
  resources: "^([+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?\\s*){1,4}$"
  time: "^[-+]?(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"
  fieldsV1: "^(\\.|f\\:[^\\:]+|i\\:\\d+|v\\:.+|k\\:.+)$"
  hostAlias: "^((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})(\\.((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})){3}(\\s+[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+)+$"
  policy:
    podFailure:
      rules0: "^(FailJob|FailIndex|Ignore|Count)(?:\\s+(\\S+))?(?:\\s+(in|notin))(?:\\s+\\((.*?)\\))$"
      rules1: "^(FailJob|FailIndex|Ignore|Count)(?:\\s+\\((.*?)\\))$"
      exitCodes: "^(\\S+)?(?:\\s+((?i)in|notin))(?:\\s+\\((.*?)\\))$"
      podConditions: "^(\\S+)(?:\\s+(\\S+))?$"
    success:
      rules: "^(\\d+)?(?:\\s*((?:\\d+(?:-\\d+)?)(?:,\\s*\\d+(?:-\\d+)?)*))?$"
    statefulSetPVCRetention: "^(Retain|retain|Delete|delete)?(?:\\s+(Retain|retain|Delete|delete))?$"
  container:
    envVar: "^((?i)cm|configMap|field|file|resource|secret)(?:\\s+(.*?))$"
    envVarConfigMap: "^(\\S+)(?:\\s+(\\S+))?(?:\\s+(true|false))?$"
    envVarField: "^(\\S+)(?:\\s+(\\S+))?$"
    envVarFile: "^(\\S+)\\s+(\\S+)\\s+(\\S+)(?:\\s+(true|false))?$"
    envVarResource: "^(\\S+)(?:\\s+(\\S+))?(?:\\s+(\\S+))?$"
    envVarSecret: "^(\\S+)\\s+(\\S+)(?:\\s+(true|false))?$"
    envFrom: "^((?i)cm|configMap|secret)(?:\\s+(\\S+))(?:\\s+(\\S+))?(?:\\s+(true|false))?$"
    envFromConfigMap: "^(\\S+)(?:\\s+(true|false))?$"
    envFromSecret: "^(\\S+)(?:\\s+(true|false))?$"
    ports: "^((?:((?:\\d{1,3}\\.){3}\\d{1,3}):)?(?:(\\d{1,5}):)?)?(\\d{1,5})(?:/(TCP|tcp|UDP|udp|SCTP|sctp))?(?:#(\\S+))?$"
    resizePolicy: "^(cpu|memory)(?:\\s+(NotRequired|RestartContainer))?$"
    restartPolicyRules: "^((?i)Restart)\\s+(in|notin)\\s+\\((.*?)\\)$"
    exitCodes: "^(in|notin)(?:\\s+\\((.*?)\\))$"
    # scheme host port path httpHeaders
    httpGet: "^(?:((?i)http|https)\\s+)?(?:([a-z\\.]+|\\d{1,3}(?:\\.\\d{1,3}){3})\\s+)?(?:(\\d+)\\s+)?(\\S+)(?:\\s+header[s]?\\s+\\((.*?)\\))?$"
    # host port
    tcpSocket: "^(?:(\\S+)\\s+)?(\\d+)$"
    # service port
    grpc: "^(?:(\\S+)\\s+)?(\\d+)$"
  volume:
    # name devicePath
    device: "^(\\S+)\\s+(\\S+)$"
    # name mountPath [subPath] [subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]
    mount: "^(\\S+)(?:\\s+(\\S+))(?:\\s+(\\S+))?(?:\\s+(\\S+))?(?:\\s+(true|false))?(?:\\s+(Disabled|IfPossible|Enabled))?(?:\\s+(Bidirectional|HostToContainer|None))?$"
    volumes: "^(cm|configMap|secret|pvc|persistentVolumeClaim|emptyDir|hostPath|nfs|image|fc|iscsi|local)(?:\\s+(.*?))(?:\\s+(.*?))?$"
    configMap: "^([a-z][a-z0-9-]+)(?:\\s+(true|false))?(?:\\s+(\\d+))?(?:\\s+items\\s*\\((.*?)\\))?$"
    emptyDir: "^((?i)Memory)?(?:\\s*((?:\\d+(?:\\.\\d{0,3})?|\\.\\d{1,3})(?:[KMGTPE]i|[mkMGTPE])?))?$"
    fc0: "^targetWWNs\\s*\\((.*?)\\)\\s+(\\d+)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$"
    fc1: "^wwids\\s*\\((.*?)\\)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$"
    hostPath: "^(\\S+)\\s*(DirectoryOrCreate|Directory|FileOrCreate|File|Socket|CharDevice|BlockDevice)?$"
    image: "^(\\S+)(?:\\s+(Always|Never|IfNotPresent))?$"
    iscsi: "^(\\S+)\\s+(\\S+)\\s+(\\d+)\\s+(ext4|xfs|ntfs)(?:\\s+(true|false))(?:\\s+(\\S+))?(?:\\s+(\\S+))(?:\\s+(?:chap\\s*\\((true|false),\\s*(true|false)\\)\\s*))?(?:\\s+(?:portals\\s*\\((.*?)\\)\\s*))?(?:\\s+(\\S+)\\s*)?$"
    nfs: "^(\\S+)(?:\\s+(\\S+))(?:\\s+(true|false))?$"
    pvc: "^(\\S+)(?:\\s+(true|false))?$"
    secret: "^([a-z][a-z0-9-]+)(?:\\s+(true|false))?(?:\\s+(\\d+))?(?:\\s+(?:items\\s*\\((.*?)\\)))?$"
    local: "^(\\S+)(?:\\s+(ext4|xfs|ntfs))?$"
    claimTemplates: "^(\\S+)\\s+(\\S+)(?:\\s+(\\S+))?\\s+(accessMode[s]?)\\s*\\(\\s*([^)]+?)\\s*\\)\\s+(\\S+)(?:\\s+(\\S+))?(?:\\s+(\\S+))?(?:\\s+(Filesystem|filesystem|Block|block))?$"
  strategy:
    deployment: "^(Recreate|RollingUpdate)?(?:\\s*(\\d+\\%?))?(?:\\s+(\\d+\\%?))?$"
    deamonset: "^(OnDelete|RollingUpdate)?(?:\\s*(\\d+\\%?))?(?:\\s+(\\d+\\%?))?$"
    statefulset: "^(OnDelete|RollingUpdate)?(?:\\s*(\\d+\\%?))?(?:\\s+(\\d+))?$"
  selector:
    equality0: "^([A-Za-z0-9-]+)(?:\\s+([=]{1,2}|!=))(?:\\s+([A-Za-z0-9-]+))$"
    equality1: "^([A-Za-z0-9-]+)(?:\\s+([><]))(?:\\s+([+-]?\\d+))$"
    set0: "^([A-Za-z0-9-]+)(?:\\s+((?i)in|notin))(?:\\s+\\(.*?\\))$"
    set1: "^([A-Za-z0-9-]+)(?:\\s+((?i)gt|lt))(?:\\s+([+-]?\\d+))$"
    setExists: "^(!)?([A-Za-z0-9-]+)"
  ingress:
    resource: "^resource(?:\\s+(\\S+))(?:\\s+(\\S+))(?:\\s+(\\S+))?$"
    service: "^service(?:\\s+(\\S+))(?:\\s+([\\w-]+|0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]))$"
    path: "^(\\S+)(?:\\s+(Exact|Prefix|ImplementationSpecific))?(?:\\s+(resource|service)(?:\\s+(.*?)))$"
    tls: "^([a-z0-9-]+)(?:\\s+((?:\\*\\.)?[a-z0-9-]+(?:\\.[a-z0-9-]+)+))(?:\\s+((?:\\*\\.)?[a-z0-9-]+(?:\\.[a-z0-9-]+)+))*$"
  service:
    ports: "^(?:(3(?:[01]\\d{3}|2[0-6]\\d{2}|27[0-5]\\d|276[0-7]))\\:)?(0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5])(?:\\:(0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]|[\\w-]+))?(?:\\/(tcp|TCP|udp|UDP|sctp|SCTP))?(?:@([\\w\\.-\\/]+))?(?:#([\\w-]+))?$"
    ipFamilies: "^IPv4|Ipv6$"
net:
  ip: "^((0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)\\.){3}(0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)(\\/\\d{1,2})?$"
  port: "^((0)|([1-9]\\d{0,3})|([1-5]\\d{4})|(6[0-4]\\d{3})|(65[0-4]\\d{2})|(655[0-2]\\d)|(6553[0-5]))$"
  domainName: "(?i)^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\\.|$))*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$"
sys:
  fileMode: "^(0[0-7]{3}|0|[1-9]\\d|[1-4]\\d{2}|50\\d|51[0-1])$"
  cron: "^((\\*|[0-5]?\\d(\\-[0-5]?\\d)?)(\\/[0-5]?\\d)?(\\,[0-5]?\\d(\\-[0-5]?\\d)?(\\/[0-5]?\\d)?)*)\\s+((\\*|([0-1]?\\d|2[0-3])(\\-([0-1]?\\d|2[0-3]))?)(\\/([0-1]?\\d|2[0-3]))?(\\,([0-1]?\\d|2[0-3])(\\-([0-1]?\\d|2[0-3]))?(\\/([0-1]?\\d|2[0-3]))?)*)\\s+((\\*|([0-2]?\\d|3[01])(\\-([0-2]?\\d|3[01]))?)(\\/([0-2]?\\d|3[01]))?(\\,([0-2]?\\d|3[01])(\\-([0-2]?\\d|3[01]))?(\\/([0-2]?\\d|3[01]))?)*)\\s+((\\*|(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec)(\\-(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?)(\\/(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?(\\,(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec)(\\-(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?(\\/(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?)*)\\s+((\\*|(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat)(\\-(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?)(\\/(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?(\\,(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat)(\\-(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?(\\/(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?)*)$"
kustomize:
  prefix: "^([\\w-]+-)+$"
  suffix: "^(-[\\w-]+)+$"
{{- end }}
