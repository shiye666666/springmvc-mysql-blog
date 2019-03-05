#!/bin/bash
###############################################################################
#编译脚本的原理是将编译结果放到output目录中，这个样例模版提供一个产生
#war包的最基本的编译脚本，对于特殊的需求请酌情考虑
#
#1、该脚本支持参数化，参数将传入build_package函数（内容为最终执行的编译命令）
#   ，用$1,$2....表示，第1,2...个参数
#2、产生的包为tomcat运行的war包，所以至少需要提供server.xml，放在conf文件
#   夹中
#3、部署需要启动tomcat，所以需要提供control文件放在当前目录中，用于启动和
#   监控程序状态
#4、如果想自己设置tomcat的配置文件，可以放在工作目录的conf文件夹内，否者部署
#   系统会使用默认的tomcat配置文件

###############用户修改部分################
readonly PACKAGE_DIR_NAME=""    #如果在pom文件中定义了模块，请设置该变量,可选项
readonly PACKAGE_WAR_NAME=""    #定义产出的war包名,必填项
#最终的抽包路径为$OUTPUT/webapps/$PACKAGE_DIR_NAME/$PACKAGE_WAR_NAME
###########################################

if [[ "${PACKAGE_WAR_NAME}" == "" ]];then
    echo "Please set "PACKAGE_WAR_NAME" value"
    exit 1
fi

function set_work_dir
{
    readonly OUTPUT=$(pwd)/output
    readonly WORKSPACE_DIR=$(pwd)
}

#清理编译构建目录操作
function clean_before_build
{
    cd ${WORKSPACE_DIR}
    mvn clean
    rm -rf ${OUTPUT}
}

#实际的编译命令
#这个函数中可使用$1,$2...获取第1,2...个参数
function build_package()
{
    cd ${WORKSPACE_DIR}
    mvn package -Dmaven.test.skip=true || return 1
}

#建立最终发布的目录
function build_dir
{
    mkdir ${OUTPUT} || return 1
    mkdir ${OUTPUT}/bin || return 1
    mkdir ${OUTPUT}/logs || return 1
    mkdir -p ${OUTPUT}/webapps/${PACKAGE_DIR_NAME} || return 1
}

function dir_not_empty()
{
    if [[ ! -d $1 ]];then
        return 1
    fi
    if [[ $(ls $1|wc -l) -eq 0 ]];then
        return 1
    fi
    return 0
}

#拷贝编译结果到发布的目录
function copy_result
{
    cd ${WORKSPACE_DIR}
    cp -r ./${PACKAGE_DIR_NAME}/target/${PACKAGE_WAR_NAME} ${OUTPUT}/webapps/${PACKAGE_DIR_NAME}/${PACKAGE_WAR_NAME} || return 1
    cp -r ./control ${OUTPUT}/bin || return 1
    (dir_not_empty ${WORKSPACE_DIR}/conf && cp -rf ./conf/* ${OUTPUT}/);return 0
}

#解压war包
function unzip_result
{
    cd ${OUTPUT}/webapps/${PACKAGE_DIR_NAME} || return 1
    jar -xvf ${PACKAGE_WAR_NAME} || return 1
}

#清理war包
function clean_after_build
{
    cd ${OUTPUT}/webapps/${PACKAGE_DIR_NAME} || return 1
    rm -f ${PACKAGE_WAR_NAME}
}

#执行
function main()
{
    cd $(dirname $0)
    set_work_dir

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Cleaning...'
    clean_before_build || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Clean completed'
    echo

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Building...'
    build_package $@ || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Build completed'
    echo

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Making dir...'
    build_dir || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Make completed'
    echo

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Copy result to publish dir...'
    copy_result || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Copy completed'
    echo

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Unzip war package...'
    unzip_result || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Unzip completed'
    echo

    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Clean publish dir...'
    clean_after_build || exit 1
    echo "At: "$(date "+%Y-%m-%d %H:%M:%S") 'Clean completed'
    echo

    exit 0
}

main $@
