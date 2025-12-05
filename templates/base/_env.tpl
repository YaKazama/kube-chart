{{- /*
  constants 常量：集中管理命名模板所需的常量定义
  注：有一部分正则表达式定义分布在各个命名模板中，仅适用于该命名模板内部
*/ -}}
{{- define "base.env" -}}
# 默认空字符
emptyStr: ""
# 检查字符串是否为 float64 / int / int64 类型
regexCheckInt: "^[+-]?\\d+(\\.\\d+)?$"
# 清洗全数字的 string
regexReplaceZero: "^([+-]?)0+(\\d*)$"
# 检查八进制和十六进制字符串
regexOctalHex: "^0(x|X|o|O)"
# 分割字符串时的分隔符 " "、","、":"、"."、"|"、"/"、"^"、"@"、"#"、"*"
regexSplitStr: "\\s*[,\\:\\.\\|\\/\\*\\^@#\\s]+\\s*"
# 默认字符串分隔符(空格)
# 用于处理一些需要保留特殊字符的情况
regexSplit: "\\s+"

regexRFC1035: "^([a-z]{1,63}|[a-z][a-z0-9-]{0,61}[a-z0-9]?)$"
regexRFC1123: "^([a-z0-9]{1,63}|[a-z0-9][a-z0-9-]{0,61}[a-z0-9]?)$"
regexQuantity: "^[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?$"
regexResources: "^([+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?\\s*){1,4}$"
regexTime: "^[-+]?(\\d+(\\.\\d+)?(ns|us|µs|ms|s|m|h))+$"
regexFieldsV1: "^(\\.|f\\:[^\\:]+|i\\:\\d+|v\\:.+|k\\:.+)$"
regexIP: "^((0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)\\.){3}(0|25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]?)$"
regexFileMode: "^(0[0-7]{3}|0|[1-9]\\d|[1-4]\\d{2}|50\\d|51[0-1])$"
regexRollingUpdate: "^\\d+(\\%)?$"

regexCron: "^((\\*|[0-5]?\\d(\\-[0-5]?\\d)?)(\\/[0-5]?\\d)?(\\,[0-5]?\\d(\\-[0-5]?\\d)?(\\/[0-5]?\\d)?)*)\\s+((\\*|([0-1]?\\d|2[0-3])(\\-([0-1]?\\d|2[0-3]))?)(\\/([0-1]?\\d|2[0-3]))?(\\,([0-1]?\\d|2[0-3])(\\-([0-1]?\\d|2[0-3]))?(\\/([0-1]?\\d|2[0-3]))?)*)\\s+((\\*|([0-2]?\\d|3[01])(\\-([0-2]?\\d|3[01]))?)(\\/([0-2]?\\d|3[01]))?(\\,([0-2]?\\d|3[01])(\\-([0-2]?\\d|3[01]))?(\\/([0-2]?\\d|3[01]))?)*)\\s+((\\*|(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec)(\\-(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?)(\\/(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?(\\,(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec)(\\-(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?(\\/(0?[1-9]|1[0-2]|JAN|jan|FEB|feb|MAR|mar|APR|apr|MAY|may|JUN|jun|JUL|jul|AUG|aug|SEP|sep|OCT|oct|NOV|nov|DEC|dec))?)*)\\s+((\\*|(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat)(\\-(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?)(\\/(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?(\\,(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat)(\\-(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?(\\/(0?[0-7]|SUN|sun|MON|mon|TUE|tue|WED|wed|THU|thu|FRI|fri|SAT|sat))?)*)$"
{{- end }}
