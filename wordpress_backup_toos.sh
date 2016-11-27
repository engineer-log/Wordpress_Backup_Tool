#!bin/sh

#DBユーザー
DB_USER="wordpress"
#DBパスワード
DB_PASSWORD="password"
#DB名
DB_NAME="wordpress"
#DBホスト
DB_HOST="localhost"
#wordpressのファイルパス
WORDPRESS_PATH="/var/www/wordpress/"
#バックアップ先
BACKUP_PATH="/Backup"
#バックアップ世代数
NUMBER_OF_GENERATIONS="15"

DATE=`date +%Y%m%d-%H%M%k`

#フォルダ存分確認（ない場合は作成する）
if [ ! -d $BACKUP_PATH/DB ]
then
    mkdir -m 777 $BACKUP_PATH/DB
fi

if [ ! -d $BACKUP_PATH/FILE ]
then
    mkdir -m 777 $BACKUP_PATH/FILE
fi


#DBのバックアップ
eval "mysqldump -u$DB_USER -h$DB_HOST -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_PATH/DB/DB_$DATE.sql.gz"
if [ $? -ne 0 ]
then
  echo "$DATE:DB Backup error." >> $BACKUP_PATH/Backup.log
  exit 1
fi

#ファイルバック
eval tar czf $BACKUP_PATH/FILE/FILE_$DATE.tar.gz -C $WORDPRESS_PATH . --exclude ".git"
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
deletefile "$BACKUP_PATH/FILE/FILE_"
deletefile "$BACKUP_PATH/DB/DB_"
