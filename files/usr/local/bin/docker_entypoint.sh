#!/usr/bin/env sh

set -e

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-3600}

test $EMAIL_FROM
test $EMAIL_USERNAME
test $EMAIL_PASSWORD
test $NOTIFY_TO_EMAIL

confd -onetime -backend env


while :
do
  scan_server.rb $1 $2
  echo $?
	sleep $SLEEP_INTERVAL
done

