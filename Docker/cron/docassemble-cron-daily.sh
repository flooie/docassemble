#! /bin/bash

export DA_CONFIG_FILE=/usr/share/docassemble/config/config.yml
source /usr/share/docassemble/local/bin/activate
export CONTAINERROLE=":${CONTAINERROLE:-all}:"
source /dev/stdin < <(su -c "python -m docassemble.base.read_config $DA_CONFIG_FILE" www-data)

if [ "${S3ENABLE:-null}" == "null" ] && [ "${S3BUCKET:-null}" != "null" ]; then
    export S3ENABLE=true
fi

if [ "${S3ENABLE:-null}" == "true" ] && [ "${S3BUCKET:-null}" != "null" ] && [ "${S3ACCESSKEY:-null}" != "null" ] && [ "${S3SECRETACCESSKEY:-null}" != "null" ]; then
    export AWS_ACCESS_KEY_ID=$S3ACCESSKEY
    export AWS_SECRET_ACCESS_KEY=$S3SECRETACCESSKEY
fi

if [[ $CONTAINERROLE =~ .*:(all|sql):.* ]]; then
    /usr/share/docassemble/webapp/run-cron.sh cron_daily
fi
MONTHDAY=$(date +%m-%d)
BACKUPDIR=/usr/share/docassemble/backup/$MONTHDAY
rm -rf $BACKUPDIR
mkdir -p $BACKUPDIR
if [[ $CONTAINERROLE =~ .*:(all|web|celery|log):.* ]]; then
    rsync -au /usr/share/docassemble/files $BACKUPDIR/
    rsync -au /usr/share/docassemble/config $BACKUPDIR/
    rsync -au /usr/share/docassemble/log $BACKUPDIR/
fi
if [[ $CONTAINERROLE =~ .*:(all|sql):.* ]]; then
    PGBACKUPDIR=`mktemp -d`
    chown postgres.postgres "$PGBACKUPDIR"
    su postgres -c 'psql -Atc "SELECT datname FROM pg_database" postgres' | grep -v -e template -e postgres | awk -v backupdir="$PGBACKUPDIR" '{print "cd /tmp; su postgres -c \"pg_dump -F c -f " backupdir "/" $1 " " $1 "\""}' | bash
    rsync -au "$PGBACKUPDIR" $BACKUPDIR/postgres
    if [ "${S3ENABLE:-false}" == "true" ]; then
	s3cmd sync "$PGBACKUPDIR/" s3://${S3BUCKET}/postgres/
    fi
fi
if [ "${S3ENABLE:-false}" == "true" ]; then
    if [ "${EC2:-false}" == "true" ]; then
	export LOCAL_HOSTNAME=`curl http://169.254.169.254/latest/meta-data/local-hostname`
    else
	export LOCAL_HOSTNAME=`hostname --fqdn`
    fi
    s3cmd sync /usr/share/docassemble/backup/ s3://${S3BUCKET}/backup/${LOCAL_HOSTNAME}/
fi
