#!bin/sh

#識別子  
ID=$1
#DBユーザー
DB_USER=$2
#DBパスワード
DB_PASSWORD=$3
#DB名
DB_NAME=$4
#DBホスト
DB_HOST=$5
#wordpressのファイルパス
WORDPRESS_PATH=$6
#バックアップ先
BACKUP_PATH="/Backup"
#バックアップ世代数
NUMBER_OF_GENERATIONS="10"

DATE=`date +%Y%m%d_%H-%M-%S`

#フォルダ存分確認（ない場合は作成する）
if [ ! -d $BACKUP_PATH/DB/"$ID" ]
then
    mkdir -m 777 $BACKUP_PATH/DB/"$ID"
fi

if [ ! -d $BACKUP_PATH/FILE/"$ID" ]
then
    mkdir -m 777 $BACKUP_PATH/FILE/"$ID"
fi


#DBのバックアップ
eval "mysqldump -u$DB_USER -h$DB_HOST -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_PATH/DB/$ID/DB_$DATE.sql.gz"
if [ $? -ne 0 ]
then
  echo "$DATE:DB Backup error." >> $BACKUP_PATH/Backup.log
  exit 1
fi

#ファイルバック
eval tar czf $BACKUP_PATH/FILE/"$ID"/FILE_$DATE.tar.gz -C $WORDPRESS_PATH . --exclude ".git"
if [ $? -ne 0 ]
then
  echo "$DATE:Wordpress File Backup error." >> $BACKUP_PATH/Backup.log
  exit 1
fi

# 関数: ファイルの削除を行う。
# $1: 削除対象のファイルパス(前方一致)
function deletefile(){
    CNT=0
    for file in `ls -1t ${1}*`
    do
        CNT=$((CNT+1))

        if [ ${CNT} -le $NUMBER_OF_GENERATIONS ]
        then
            continue
        fi
        eval "rm ${file}"
    done
    return
}

#旧バックアップファイル削除
deletefile "$BACKUP_PATH/FILE/$ID/FILE_"
deletefile "$BACKUP_PATH/DB/$ID/DB_"
