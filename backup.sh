#!/bin/bash
#
# Backup apps e mysql DBs digitalocean dropbox
webapps_dir=/var/www
backup_dir=/var/backup
backup_senhas_file=/var/scripts/senha/.backup_senhas

old_ifs="$ifs"
ifs=$'\n'

for LINE in `cat $backup_senhas_file`; do
    ifs=' '
    array=($LINE)
    app_nome=${array[0]}
    app_dir=$webapps_dir/$app_nome
    db_tipo=`echo ${array[1]} | tr '[:lower:]' '[:upper:]'`
    db_nome=${array[2]}
    db_usuario=${array[3]}
    db_senhas=${array[4]}
    db_sql="${db_nome}.${db_tipo}.sql"

    tar -cf $backup_dir/$app_nome.tar $app_dir
    rm -rf $backup_dir/$app_nome.tar.bz2
    bin/bzip2 $backup_dir/$app_nome.tar

    if [[ ! -z "$db_tipo" ]] && [[ ! -z "$db_usuario" ]] && [[ ! -z "$db_senhas" ]]; then
        if [[ $db_tipo == "M" ]];then
            mysqldump -u$db_usuario -p$db_senhas $db_nome > $backup_dir/$db_sql
        elif [[ $db_tipo == "P" ]];then
            pgpassword=$db_senhas pg_dump -U $db_usuario -f $backup_dir/$db_sql $db_nome
        else
            continue
        fi
        /bin/rm -rf $backup_dir/$db_sql.bz2
        /usr/bin/bzip2 $backup_dir/$db_sql
    fi
done

ifs="$old_ifs"

# Faz o upload e apaga arquivos antigos no dropbox

for backup_file in $backup_dir/*; do 
   file=`basename $backup_file`
   /var/scripts/dropbox_uploader.sh upload ${backup_file} backup/${file}
done
