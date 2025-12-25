#!/usr/bin/env bash
# @author: Ya Kazama <kazamaya.y@gmail.com>
# @date  : 2022-06-08 13:44:21
#

# REAL_PATH=$(cd "$(dirname $0)" && pwd)
# cd ${REAL_PATH} || exit 1

function publish() {
    local folder="$1"
    local index_url="$2"
    local ngx_upload="$3"
    local merge="$4"
    local nexus_login_info="$5"
    local pkg_noclean="$6"
    local ngx_k="$7"
    local cmd_helm
    local name
    local version
    local helm_upload_url
    local helm_custom_nginx_header

    cd ${folder} || exit 1

    cmd_helm=$(which helm)
    [[ ! -f "${cmd_helm}" ]] && echo "command: helm not found, please install it first." && exit 1

    if [[ -f "Chart.yaml" ]]; then
        name=$(grep -E "^name:" Chart.yaml | awk '{print $2}' | tr -d '"')
        version=$(grep -E "^version:" Chart.yaml | awk '{print $2}' | tr -d '"')
        # -u: 解决本地没有 dependencies 时，helm package 执行出错的问题
        # Error: found in Chart.yaml, but missing in charts/ directory: library-charts
        ${cmd_helm} package . -u
        if [[ -n "${nexus_login_info}" ]]; then
            curl -u "${nexus_login_info}" "${index_url}" --upload-file ${name}-${version}.tgz
        else
            if [[ "${merge^}" == "True" ]]; then
                curl -s -O -L "${index_url:?}/index.yaml"
                ${cmd_helm} repo index --merge index.yaml --url ${index_url} .
            else
                ${cmd_helm} repo index . --url ${index_url}
            fi

            if [[ "${ngx_upload}" == "True" ]]; then
                helm_upload_url="${index_url}/upload"

                if [[ "${index_url}" =~ (12334.icu) || -n "${ngx_k}" ]]; then
                    helm_custom_nginx_header="NGX_K: ${ngx_k}"
                    curl -XPUT -H "${helm_custom_nginx_header}" ${helm_upload_url}/${name}-${version}.tgz --data-binary @${name}-${version}.tgz
                    curl -XPUT -H "${helm_custom_nginx_header}" ${helm_upload_url}/index.yaml --data-binary @index.yaml
                else
                    curl -XPUT ${helm_upload_url}/${name}-${version}.tgz --data-binary @${name}-${version}.tgz
                    curl -XPUT ${helm_upload_url}/index.yaml --data-binary @index.yaml
                fi
            fi
        fi

        if [[ "${pkg_noclean}" != "True" ]]; then
            rm -rf ${name}-${version}.tgz index.yaml
        fi
    else
        echo "Chart.yaml missing."
        exit 1
    fi
}

function usage() {
    echo "Usage: sh $0 <Helm Chart> [Options]"
    echo "Options:"
    echo "  -h, --help:                     帮助信息"
    echo "  -i <URL>, --index-url <URL>:    * HELM Chart 仓库 URL"
    echo "  --nexus-login <USER:PASS>:      Nexus 提供的 HELM Chart 仓库的 username and password。此时 --merge、-N 参数会失效"
    echo "  --merge:                        将生成的索引合并到给定的索引中"
    echo "  -N, --nginx-upload:             使用 Nginx 上传 / 下载站点时需要指定此参数"
    echo "  --ngx-k <TOKEN>:                使用 Nginx 上传时使用的自定义变量 NGX_K 值"
    echo "  --no-clean:                     是否清理生成的 tgz 文件. 默认为 False 表示会清理"
    exit 0
}

function main() {
    [[ "$1" =~ (^-{1,2}(h|help)+$) ]] && usage

    local ARGS
    local ARGS_SHORT='h,i:,N,k:'
    local ARGS_LONG='help,index-url:,merge,nexus-login:,nginx-upload,ngx-k:,no-clean'
    ARGS=$(getopt -o ${ARGS_SHORT} --long ${ARGS_LONG} -n "$0" -- "$@")
    eval set -- "${ARGS}"

    while :
    do
        case "$1" in
            -i|--index-url)     local INDEX_URL="$2";       shift 2 ;;
            --merge)            local MERGE_STATUS="True";  shift 1 ;;
            --nexus-login)      local _NEXUS_LOGIN="$2";    shift 2 ;;
            -N|--nginx-upload)  local _NGX_UPLOAD="True";   shift 1 ;;
            -k|--ngx-k)         local _NGX_K="$2";          shift 2 ;;
            --no-clean)         local _NO_CLEAN="True";     shift 1 ;;
            --)                 shift;                      break   ;;
            *)                  usage                               ;;
        esac
    done

    # how to use
    [[ "${MERGE_STATUS}" != "True" ]] && MERGE_STATUS="False"
    [[ "${_NGX_UPLOAD}" != "True" ]] && _NGX_UPLOAD="False"
    [[ "${_NO_CLEAN}" != "True" ]] && _NO_CLEAN="False"
    [[ -z "$1" ]] && usage
    [[ -z "${INDEX_URL}" ]] && echo "HELM Chart 仓库未找到，--index-url 参数未指定！"
    [[ "${INDEX_URL}" =~ (12334.icu) && -z "${_NGX_K}" ]] && echo "--ngx-k 未定义！" && usage
    publish "$1" "${INDEX_URL}" "${_NGX_UPLOAD}" "${MERGE_STATUS}" "${_NEXUS_LOGIN}" "${_NO_CLEAN}" "${_NGX_K}"
}

# main
main "$@"
