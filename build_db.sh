#!/usr/bin/env bash
# This NEEDS to be bash, otherwise the source command won't work

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  source $HOME/env.sh
fi

read -p "Enter broker *SUPERUSER* password (from Lynny-Whitebox-Secrets/deployments/cf3/whitebox_instance.developers_db.json):" -s DB_SU_PASS

# hostname:port:database:username:password
# For some reason .pgpass doesn't work on gotty
echo "$DB_URL:*:*:broker_superuser:$DB_SU_PASS" > $HOME/.pgpass
echo "$DB_URL:*:*:$DB_USER:$DB_PASS" >> $HOME/.pgpass
chmod 0600 $HOME/.pgpass

dropdb -h $DB_URL -p 5432 -U broker_superuser --maintenance-db postgres ${USER}_test 
createdb -h $DB_URL -p 5432 -U broker_superuser --maintenance-db postgres ${USER}_test
psql -v ON_ERROR_STOP=1 -h $DB_URL -p 5432 -U $DB_USER -d ${USER}_test -AtX1f $HOME/src/$GOPACKAGENAME/sql/schema.sql
