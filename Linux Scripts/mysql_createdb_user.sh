#!/bin/bash
 
EXPECTED_ARGS=2
E_BADARGS=65
MYSQL=`which mysql`
UNAME=${1:0:16}
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 dbname hostname"
  exit $E_BADARGS
fi
CHECK_USER=$(mysql -e "SELECT user FROM mysql.user WHERE user='$UNAME'")
if [ -n "$CHECK_USER" ]; then
    echo "MySQL User $UNAME exists, exiting"
    exit 1
fi
RANDOM_PASS=$(python -c "import string; import random; chars = string.letters + string.digits + string.punctuation; pwdSize = 16; print ''.join((random.choice(chars)) for x in range(pwdSize))")
RANDOM_PASS=$(echo $RANDOM_PASS | sed "s/'//g")
Q1="CREATE DATABASE IF NOT EXISTS $1;"
Q2="GRANT ALL ON *.* TO '$UNAME'@'$2' IDENTIFIED BY '$RANDOM_PASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
printf '%s\n' "MySQL Database and User Created"
printf '%s\n' "MySQL Database Name: $1"
printf '%s\n' "MySQL Username: $UNAME"
printf '%s\n' "MySQL Password: $RANDOM_PASS"
printf '%s\n' "MySQL Database Hostname: $2"

mysql -e "$SQL"

