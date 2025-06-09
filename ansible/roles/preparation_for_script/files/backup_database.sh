#!/bin/bash
set -x
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
         echo "Help:"
         echo "-p: backup path"
         echo "-h: host name"
         echo "-s: service name "
         echo "-d: how match must save"
         echo "-n: bucket name"
         echo "-q: database type"
         echo "--port: what port work container"
         echo "--host: what host have container"
         echo "--password: password for database"
         echo "--username: username for database"
         shift
         exit 1
      ;;
    -p)
        backupPath=$2
        shift 2
      ;;
    -h)
        hostName=$2
        shift 2
      ;;
    -s)
        serviceName=$2
        shift 2
      ;;
    -d)
        countSave=$2
        shift 2
      ;;
    -n)
        s3Name=$2
        shift 2
      ;;
    -q)
        dbType=$2
        shift 2
      ;;
    --port)
        hostPort=$2
        shift 2
      ;;
    --host)
        hostDB=$2
        shift 2
      ;;
    --password)
        dbPassword=$2
        shift 2
        ;;
    --username)
        dbUsername=$2
        shift 2
        ;;
   esac
done

BACKUP_DATE=$(date +"%Y_%m_%d_%H_%M_%S") # const variable date
s3_name=${s3Name:-'Error!'} # name of bucket aws
host_name=${hostName:-$HOSTNAME} # name of host
db_type=${dbType:-'Error!'} # database typ
service_name=${serviceName:-'Error!'} # name of servise
backup_path=${backupPath:-'Error!'}
mkdir -p "${backup_path}"
count_save=${countSave:-"7"} # How many archives must be saved
host_database=${hostDB:-'Error!'} # Host where work docker container with database
db_password=${dbPassword:-'Error!'}
db_username=${dbUsername:-'Error!'}
format='tar'
format_option_tar=''

function uploadremoveOlderDump () {

   pushd ${backup_path} && sudo tar --remove-files -c${format_option_tar}vf "${host_name}_${db_type}_${service_name}_backup_${BACKUP_DATE}.${format}" * # create archive

   s3cmd put ${host_name}_${db_type}_${service_name}_backup_${BACKUP_DATE}.${format} s3://${s3_name}/${host_name}/${db_type}/${service_name}/ # Send dump

   show_aws_delete=$(s3cmd ls s3://${s3_name}/${host_name}/${db_type}/${service_name}/ | sort | awk '{print $4}' | head -n -${count_save});

   sudo rm -f ${host_name}_${db_type}_${service_name}_backup_${BACKUP_DATE}.${format}

   for i in ${show_aws_delete}; do
     s3cmd rm ${i} # command to delate backup
   done

}

function createDump () {

    case ${db_type} in

      'redis') # Backup redis
         port=${hostPort:-"6379"} # Port where work container
         host_database=${hostDB:-"127.0.0.1"} # Host where work redis container
         redis-cli -h ${host_database} -p ${port} save
         format='tar.gz'
         format_option_tar='z'
       ;;
       'postgresql') # Backup postgrssql
         port=${hostPort:-"5432"} # Port where work container
         host_database=${hostDB:-"localhost"}
         PGPASSWORD=${db_password} pg_dumpall --username=${db_username} --host=${host_database} | gzip > ${backup_path}${db_type}.sql.gz
      ;;

      'mongo') # Backup mongo
         port=${hostPort:-"27017"} # Port where work container
         host=${host_database:-localhost}
         # Command to cretae docker container what connect to mongo container and move backup file to local system.
         mongodump -u ${db_username} -p ${db_password} --authenticationDatabase=admin --gzip --out ${backup_path}${db_type} --host ${host_database}:${port}
      ;;

      'mysql') # Backup mysql
         port=${hostPort:-"3306"} # Port where work container
         # Command to cretae docker container what connect to mysql container and move backup file to local system.
         mysqldump -h ${host_database} -P ${port} -u ${db_username} --password=${db_password} --all-databases | gzip > ${backup_path}${db_type}.sql.gz
      ;;
   esac

}

createDump "$container_name" "$db_type" "$backup_path" "$hostPort" "$host_database" "$hostDB" "$service_name " "$show_aws_delete" "$host_name" "$s3_name" "$BACKUP_DATE" "$format" "$format_option_tar"
uploadremoveOlderDump "$s3_name" "$host_name" "$service_name" "$db_type" "$count_save" "$BACKUP_DATE" "$s3_name" "$host_name" "$service_name" "$db_type" "$backup_path" "$format" "$format_option_tar"

echo "Saved $backup_path"




