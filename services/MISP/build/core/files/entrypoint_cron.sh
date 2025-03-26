#!/bin/bash

term_procs() {
    echo "Entrypoint CRON caught SIGTERM signal!"
    echo "Killing process $p1_pid"
    kill -TERM "$p1_pid" 2>/dev/null
    echo "Killing process $p2_pid"
    kill -TERM "$p2_pid" 2>/dev/null
}

trap term_procs SIGTERM

cat << EOF > /etc/cron.d/misp
20 2 * * * www-data /var/www/MISP/app/Console/cake Server cacheFeed "$CRON_USER_ID" all > /tmp/cronlog 2>&1
30 2 * * * www-data /var/www/MISP/app/Console/cake Server fetchFeed "$CRON_USER_ID" all > /tmp/cronlog 2>&1

0 0 * * * www-data /var/www/MISP/app/Console/cake Server pullAll "$CRON_USER_ID" > /tmp/cronlog 2>&1
0 1 * * * www-data /var/www/MISP/app/Console/cake Server pushAll "$CRON_USER_ID" > /tmp/cronlog 2>&1

00 3 * * * www-data /var/www/MISP/app/Console/cake Admin updateGalaxies > /tmp/cronlog 2>&1
10 3 * * * www-data /var/www/MISP/app/Console/cake Admin updateTaxonomies > /tmp/cronlog 2>&1
20 3 * * * www-data /var/www/MISP/app/Console/cake Admin updateWarningLists > /tmp/cronlog 2>&1
30 3 * * * www-data /var/www/MISP/app/Console/cake Admin updateNoticeLists > /tmp/cronlog 2>&1
45 3 * * * www-data /var/www/MISP/app/Console/cake Admin updateObjectTemplates "$CRON_USER_ID" > /tmp/cronlog 2>&1

EOF

# Build a fifo buffer for the cron logs, 777 so anyone can write to it
if [[ ! -p /tmp/cronlog ]]; then
    mkfifo -m 777 /tmp/cronlog
fi

# Build another fifo for the cron pipe
if [[ ! -p /tmp/cronpipe ]]; then
    mkfifo /tmp/cronpipe
fi

# Execute the cron pipe
cron -l -f > /tmp/cronpipe & p1_pid=$!
tail -f /tmp/cronlog < /tmp/cronpipe & p2_pid=$!

# Wait for both processes of the cron pipe
wait "$p2_pid"
wait "$p1_pid"
