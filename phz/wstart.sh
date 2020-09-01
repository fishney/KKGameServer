#!/bin/bash
#项目目录
PROJECT_PATH=$(cd "$(dirname "$0")"; pwd)

run(){
    #检查启动程序
    if [ ! -x "${2}"  ]; then
        echo "启动程序没有,${2} "
        exit
    fi
    #关闭程序
    echo "${TMP_PATH}kill_${1}.sh"
    if [ -a "${TMP_PATH}kill_${1}.sh" ]; then
        echo "关闭程序："
        sh ${TMP_PATH}kill_${1}.sh
    fi
    #设置日志存储
    DATA_DAY=`date +%Y-%m-%d`
    DATA_SECOND=`date +%Y-%m-%d-%H-%M-%S`
    LOG_NAME="${LOG_PATH}${1}_${DATA_DAY}.log"
    BACKUP_LOG_NAME="${LOG_PATH}${1}_${DATA_SECOND}_old.log"
    #备份日志
    if [ -a "${LOG_NAME}"  ]; then
        # mv ${LOG_NAME} ${BACKUP_LOG_NAME}
        rm -rf ${LOG_NAME}
    fi
    #启动
    nohup ${2} ${3} >> ${LOG_NAME} 2>&1 &
    # (${2} ${3} &)
    #生成关闭的程序
    echo "#!/bin/bash" > ${TMP_PATH}kill_${1}.sh
    echo "echo 'run: ${2} ${3} pid: $!'" >> ${TMP_PATH}kill_${1}.sh
    echo "kill -9 $!" >> ${TMP_PATH}kill_${1}.sh
    chmod 777 ${TMP_PATH}kill_${1}.sh
    # sleep 1
    #显示运行的程序
    echo "运行程序："
    # echo "nohup ${2} ${3} >> ${LOG_NAME} 2>&1 &"
    echo "run:$2 $3  pid:$!  log:${LOG_NAME} "
    #打印启动错误
    sleep 3
    if [ -s "${LOG_NAME}"  ]; then
        echo "启动日志："
        cat ${LOG_NAME}
        # exit
    fi
    sleep 1
}

echo "  >>---------- start --------------"
echo ""
cd ${PROJECT_PATH};
#日志目录
LOG_PATH="./log/"
if [ ! -x "$LOG_PATH"  ]; then
        mkdir "$LOG_PATH"
fi

#tmp目录
TMP_PATH="./tmp/"
if [ ! -x "$TMP_PATH"  ]; then
    mkdir "$TMP_PATH"
fi



echo ""
echo "  >>------- master server ---------"
echo ""
run master ${PROJECT_PATH}/game_master ./etc/config.master

echo ""
echo "  >>------- api server ---------"
echo ""
run api ${PROJECT_PATH}/game_master ./etc/wsconfig.api

echo ""
echo "  >>------- clubs server ---------"
echo ""
run clubs ${PROJECT_PATH}/game_master ./etc/config.club

echo ""
echo "  >>------- game server ---------"
echo ""
run game ${PROJECT_PATH}/game_master ./etc/config.game



echo ""
echo "  >>------- login server ---------"
echo ""
run login ${PROJECT_PATH}/game_login ./etc/wsconfig.login


echo ""
echo "  >>------- node server ---------"
echo ""
run node ${PROJECT_PATH}/game_node ./etc/wsconfig.node

echo ""
echo "  >>---------- end --------------"
