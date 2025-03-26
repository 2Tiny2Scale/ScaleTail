#!/bin/bash

term_proc() {
    echo "Entrypoint FPM caught SIGTERM signal!"
    echo "Killing process $master_pid"
    kill -TERM "$master_pid" 2>/dev/null
}

trap term_proc SIGTERM

change_php_vars() {
    ESCAPED=$(printf '%s\n' "$REDIS_PASSWORD" | sed -e 's/[\/&]/\\&/g')
    for FILE in /etc/php/*/fpm/php.ini
    do
        [[ -e $FILE ]] || break
        echo "Configure PHP | Setting 'memory_limit = ${PHP_MEMORY_LIMIT}'"
        sed -i "s/memory_limit = .*/memory_limit = ${PHP_MEMORY_LIMIT}/" "$FILE"
        echo "Configure PHP | Setting 'max_execution_time = ${PHP_MAX_EXECUTION_TIME}'"
        sed -i "s/max_execution_time = .*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/" "$FILE"
        echo "Configure PHP | Setting 'upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}'"
        sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}/" "$FILE"
        echo "Configure PHP | Setting 'max_file_uploads = ${PHP_MAX_FILE_UPLOADS}'"
        sed -i "s/max_file_uploads = .*/max_file_uploads = ${PHP_MAX_FILE_UPLOADS}/" "$FILE"
        echo "Configure PHP | Setting 'post_max_size = ${PHP_POST_MAX_SIZE}'"
        sed -i "s/post_max_size = .*/post_max_size = ${PHP_POST_MAX_SIZE}/" "$FILE"
        echo "Configure PHP | Setting 'max_input_time = ${PHP_MAX_INPUT_TIME}'"
        sed -i "s/max_input_time = .*/max_input_time = ${PHP_MAX_INPUT_TIME}/" "$FILE"
        sed -i "s/session.save_handler = .*/session.save_handler = redis/" "$FILE"
        echo "Configure PHP | Setting 'session.save_path = '$(echo $REDIS_HOST | grep -E '^\w+://' || echo tcp://$REDIS_HOST):$REDIS_PORT?auth=${ESCAPED}'"
        sed -i "s|.*session.save_path = .*|session.save_path = '$(echo $REDIS_HOST | grep -E '^\w+://' || echo tcp://$REDIS_HOST):$REDIS_PORT?auth=${ESCAPED}'|" "$FILE"
        sed -i "s/session.sid_length = .*/session.sid_length = 64/" "$FILE"
        sed -i "s/session.use_strict_mode = .*/session.use_strict_mode = 1/" "$FILE"
    done

    for FILE in /etc/php/*/fpm/pool.d/www.conf
    do
        [[ -e $FILE ]] || break
        echo "Configure PHP | Setting 'pm.max_children = ${PHP_FCGI_CHILDREN}'"
        sed -i -E "s/;?pm.max_children = .*/pm.max_children = ${PHP_FCGI_CHILDREN}/" "$FILE"
        echo "Configure PHP | Setting 'pm.start_servers = ${PHP_FCGI_START_SERVERS}'"
        sed -i -E "s/;?pm.start_servers = .*/pm.start_servers = ${PHP_FCGI_START_SERVERS}/" "$FILE"
        echo "Configure PHP | Setting 'pm.(min|max)_spare_servers = ${PHP_FCGI_START_SERVERS}'"
        sed -i -E "s/;?pm.min_spare_servers = .*/pm.min_spare_servers = ${PHP_FCGI_SPARE_SERVERS}/" "$FILE"
        if [[ "$PHP_FCGI_START_SERVERS" -gt "$PHP_FCGI_SPARE_SERVERS" ]]; then
            sed -i -E "s/;?pm.max_spare_servers = .*/pm.max_spare_servers = ${PHP_FCGI_START_SERVERS}/" "$FILE"
        else
            sed -i -E "s/;?pm.max_spare_servers = .*/pm.max_spare_servers = ${PHP_FCGI_SPARE_SERVERS}/" "$FILE"
        fi
        echo "Configure PHP | Setting 'pm.max_requests = ${PHP_FCGI_MAX_REQUESTS}'"
        sed -i -E "s/;?pm.max_requests = .*/pm.max_requests = ${PHP_FCGI_MAX_REQUESTS}/" "$FILE"
        if [[ "$FASTCGI_STATUS_LISTEN" != "" ]]; then
            echo "Configure PHP | Setting 'pm.status_path = /status'"
            sed -i -E "s/;?pm.status_path = .*/pm.status_path = \/status/" "$FILE"
            echo "Configure PHP | Setting 'pm.status_path = /run/php/php-fpm-status.sock'"
            sed -i -E "s/;?pm.status_listen = .*/pm.status_listen = \/run\/php\/php-fpm-status.sock/" "$FILE"
        else
            echo "Configure PHP | Disabling 'pm.status_path'"
            sed -i -E "s/^pm.status_path = /;pm.status_path = /" "$FILE"
            echo "Configure PHP | Disabling 'pm.status_listen'"
            sed -i -E "s/^pm.status_listen =/;pm.status_listen =/" "$FILE"
        fi
    done
}

echo "Configure PHP | Change PHP values ..." && change_php_vars

echo "Configure PHP | Starting PHP FPM"
/usr/sbin/php-fpm8.2 -R -F & master_pid=$!

# Wait for it
wait "$master_pid"
