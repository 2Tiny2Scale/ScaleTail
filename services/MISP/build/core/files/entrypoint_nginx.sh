#!/bin/bash

term_proc() {
    echo "Entrypoint NGINX caught SIGTERM signal!"
    echo "Killing process $master_pid"
    kill -TERM "$master_pid" 2>/dev/null
}

trap term_proc SIGTERM

init_mysql(){
    # Test when MySQL is ready....
    # wait for Database come ready
    isDBup () {
        echo "SHOW STATUS" | $MYSQL_CMD 1>/dev/null
        echo $?
    }

    isDBinitDone () {
        # Table attributes has existed since at least v2.1
        echo "DESCRIBE attributes" | $MYSQL_CMD 1>/dev/null
        echo $?
    }

    RETRY=100
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "... waiting for database to come up"
        sleep 5
        RETRY=$(( RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "... error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi

    if [ $(isDBinitDone) -eq 0 ]; then
        echo "... database has already been initialized"
        export DB_ALREADY_INITIALISED=true
    else
        echo "... database has not been initialized, importing MySQL scheme..."
        $MYSQL_CMD < /var/www/MISP/INSTALL/MYSQL.sql
    fi
}

init_misp_data_files(){
    # Init config (shared with host)
    echo "... initialize configuration files"
    MISP_APP_CONFIG_PATH=/var/www/MISP/app/Config
    # workaround for https://forums.docker.com/t/sed-couldnt-open-temporary-file-xyz-permission-denied-when-using-virtiofs/125473
    # [ -f $MISP_APP_CONFIG_PATH/bootstrap.php ] || cp $MISP_APP_CONFIG_PATH.dist/bootstrap.default.php $MISP_APP_CONFIG_PATH/bootstrap.php
    # [ -f $MISP_APP_CONFIG_PATH/database.php ] || cp $MISP_APP_CONFIG_PATH.dist/database.default.php $MISP_APP_CONFIG_PATH/database.php
    # [ -f $MISP_APP_CONFIG_PATH/core.php ] || cp $MISP_APP_CONFIG_PATH.dist/core.default.php $MISP_APP_CONFIG_PATH/core.php
    # [ -f $MISP_APP_CONFIG_PATH/config.php ] || cp $MISP_APP_CONFIG_PATH.dist/config.default.php $MISP_APP_CONFIG_PATH/config.php
    # [ -f $MISP_APP_CONFIG_PATH/email.php ] || cp $MISP_APP_CONFIG_PATH.dist/email.php $MISP_APP_CONFIG_PATH/email.php
    # [ -f $MISP_APP_CONFIG_PATH/routes.php ] || cp $MISP_APP_CONFIG_PATH.dist/routes.php $MISP_APP_CONFIG_PATH/routes.php
    [ -f $MISP_APP_CONFIG_PATH/bootstrap.php ] || dd if=$MISP_APP_CONFIG_PATH.dist/bootstrap.default.php of=$MISP_APP_CONFIG_PATH/bootstrap.php
    [ -f $MISP_APP_CONFIG_PATH/database.php ] || dd if=$MISP_APP_CONFIG_PATH.dist/database.default.php of=$MISP_APP_CONFIG_PATH/database.php
    [ -f $MISP_APP_CONFIG_PATH/core.php ] || dd if=$MISP_APP_CONFIG_PATH.dist/core.default.php of=$MISP_APP_CONFIG_PATH/core.php
    [ -f $MISP_APP_CONFIG_PATH/config.php.template ] || dd if=$MISP_APP_CONFIG_PATH.dist/config.default.php of=$MISP_APP_CONFIG_PATH/config.php.template
    [ -f $MISP_APP_CONFIG_PATH/config.php ] || echo -e "<?php\n\$config=array();\n?>" > $MISP_APP_CONFIG_PATH/config.php
    [ -f $MISP_APP_CONFIG_PATH/email.php ] || dd if=$MISP_APP_CONFIG_PATH.dist/email.php of=$MISP_APP_CONFIG_PATH/email.php
    [ -f $MISP_APP_CONFIG_PATH/routes.php ] || dd if=$MISP_APP_CONFIG_PATH.dist/routes.php of=$MISP_APP_CONFIG_PATH/routes.php

    echo "... initialize database.php settings"
    # workaround for https://forums.docker.com/t/sed-couldnt-open-temporary-file-xyz-permission-denied-when-using-virtiofs/125473
    # sed -i "s/localhost/$MYSQL_HOST/" $MISP_APP_CONFIG_PATH/database.php
    # sed -i "s/db\s*login/$MYSQL_USER/" $MISP_APP_CONFIG_PATH/database.php
    # sed -i "s/3306/$MYSQL_PORT/" $MISP_APP_CONFIG_PATH/database.php
    # sed -i "s/db\s*password/$MYSQL_PASSWORD/" $MISP_APP_CONFIG_PATH/database.php
    # sed -i "s/'database' => 'misp'/'database' => '$MYSQL_DATABASE'/" $MISP_APP_CONFIG_PATH/database.php
    chmod +w $MISP_APP_CONFIG_PATH/database.php
    sed "s/localhost/$MYSQL_HOST/" $MISP_APP_CONFIG_PATH/database.php > tmp; cat tmp > $MISP_APP_CONFIG_PATH/database.php; rm tmp
    sed "s/db\s*login/$MYSQL_USER/" $MISP_APP_CONFIG_PATH/database.php > tmp; cat tmp > $MISP_APP_CONFIG_PATH/database.php; rm tmp
    sed "s/3306/$MYSQL_PORT/" $MISP_APP_CONFIG_PATH/database.php > tmp; cat tmp > $MISP_APP_CONFIG_PATH/database.php; rm tmp
    sed "s/db\s*password/$MYSQL_PASSWORD/" $MISP_APP_CONFIG_PATH/database.php > tmp; cat tmp > $MISP_APP_CONFIG_PATH/database.php; rm tmp
    sed "s/'database' => 'misp'/'database' => '$MYSQL_DATABASE'/" $MISP_APP_CONFIG_PATH/database.php > tmp; cat tmp > $MISP_APP_CONFIG_PATH/database.php; rm tmp

    echo "... initialize email.php settings"
    chmod +w $MISP_APP_CONFIG_PATH/email.php
    tee $MISP_APP_CONFIG_PATH/email.php > /dev/null <<EOT
<?php
class EmailConfig {
    public \$default = array(
        'transport'     => 'Smtp',
        'from'          => array('misp-dev@admin.test' => 'Misp DEV'),
        'host'          => '$SMTP_FQDN',
        'port'          => 25,
        'timeout'       => 30,
        'client'        => null,
        'log'           => false,
    );
    public \$smtp = array(
        'transport'     => 'Smtp',
        'from'          => array('misp-dev@admin.test' => 'Misp DEV'),
        'host'          => '$SMTP_FQDN',
        'port'          => 25,
        'timeout'       => 30,
        'client'        => null,
        'log'           => false,
    );
    public \$fast = array(
        'from'          => 'misp-dev@admin.test',
        'sender'        => null,
        'to'            => null,
        'cc'            => null,
        'bcc'           => null,
        'replyTo'       => null,
        'readReceipt'   => null,
        'returnPath'    => null,
        'messageId'     => true,
        'subject'       => null,
        'message'       => null,
        'headers'       => null,
        'viewRender'    => null,
        'template'      => false,
        'layout'        => false,
        'viewVars'      => null,
        'attachments'   => null,
        'emailFormat'   => null,
        'transport'     => 'Smtp',
        'host'          => '$SMTP_FQDN',
        'port'          => 25,
        'timeout'       => 30,
        'client'        => null,
        'log'           => true,
    );
}
EOT
    chmod -w $MISP_APP_CONFIG_PATH/email.php

    # Init files (shared with host)
    echo "... initialize app files"
    MISP_APP_FILES_PATH=/var/www/MISP/app/files
    if [ ! -f ${MISP_APP_FILES_PATH}/INIT ]; then
        cp -R ${MISP_APP_FILES_PATH}.dist/* ${MISP_APP_FILES_PATH}
        touch ${MISP_APP_FILES_PATH}/INIT
    fi
}

update_misp_data_files(){
    # If $MISP_APP_FILES_PATH was not changed since the build, skip file updates there
    FILES_VERSION=
    MISP_APP_FILES_PATH=/var/www/MISP/app/files
    CORE_COMMIT=${CORE_COMMIT:-${CORE_TAG}}
    if [ -f ${MISP_APP_FILES_PATH}/VERSION ]; then
        FILES_VERSION=$(cat ${MISP_APP_FILES_PATH}/VERSION)
        echo "... found local files/VERSION:" $FILES_VERSION
        if [ "$FILES_VERSION" = "${CORE_COMMIT:-$(jq -r '"v\(.major).\(.minor).\(.hotfix)"' /var/www/MISP/VERSION.json)}" ]; then
            echo "... local files/ match distribution version, skipping file sync"
            return 0;
        fi
    fi
    for DIR in $(ls /var/www/MISP/app/files.dist); do
        if [ "$DIR" = "certs" ] || [ "$DIR" = "img" ] || [ "$DIR" == "taxonomies" ] || [ "$DIR" == "terms" ] ; then
            echo "... rsync -azh \"/var/www/MISP/app/files.dist/$DIR\" \"/var/www/MISP/app/files/\""
            rsync -azh "/var/www/MISP/app/files.dist/$DIR" "/var/www/MISP/app/files/"
        else
            echo "... rsync -azh --delete \"/var/www/MISP/app/files.dist/$DIR\" \"/var/www/MISP/app/files/\""
            rsync -azh --delete "/var/www/MISP/app/files.dist/$DIR" "/var/www/MISP/app/files/"
        fi
    done
}

enforce_misp_data_permissions(){
    # If $MISP_APP_FILES_PATH was not changed since the build, skip file updates there
    MISP_APP_FILES_PATH=/var/www/MISP/app/files
    CORE_COMMIT=${CORE_COMMIT:-${CORE_TAG}}
    if [ -f "${MISP_APP_FILES_PATH}/VERSION" ] && [ "$(cat ${MISP_APP_FILES_PATH}/VERSION)" = "${CORE_COMMIT:-$(jq -r '"v\(.major).\(.minor).\(.hotfix)"' /var/www/MISP/VERSION.json)}" ]; then
        echo "... local files/ match distribution version, skipping data permissions in files/"
    else
        echo "... chown -R www-data:www-data /var/www/MISP/app/tmp" && find /var/www/MISP/app/tmp \( ! -user www-data -or ! -group www-data \) -exec chown www-data:www-data {} +
        # Files are also executable and read only, because we have some rogue scripts like 'cake' and we can not do a full inventory
        echo "... chmod -R 0550 files /var/www/MISP/app/tmp" && find /var/www/MISP/app/tmp -not -perm 550 -type f -exec chmod 0550 {} +
        # Directories are also writable, because there seems to be a requirement to add new files every once in a while
        echo "... chmod -R 0770 directories /var/www/MISP/app/tmp" && find /var/www/MISP/app/tmp -not -perm 770 -type d -exec chmod 0770 {} +
        # We make 'files' and 'tmp' (logs) directories and files user and group writable (we removed the SGID bit)
        echo "... chmod -R u+w,g+w /var/www/MISP/app/tmp" && chmod -R u+w,g+w /var/www/MISP/app/tmp
        
        echo "... chown -R www-data:www-data /var/www/MISP/app/files" && find /var/www/MISP/app/files \( ! -user www-data -or ! -group www-data \) -exec chown www-data:www-data {} +
        # Files are also executable and read only, because we have some rogue scripts like 'cake' and we can not do a full inventory
        echo "... chmod -R 0550 files /var/www/MISP/app/files" && find /var/www/MISP/app/files -not -perm 550 -type f -exec chmod 0550 {} +
        # Directories are also writable, because there seems to be a requirement to add new files every once in a while
        echo "... chmod -R 0770 directories /var/www/MISP/app/files" && find /var/www/MISP/app/files -not -perm 770 -type d -exec chmod 0770 {} +
        # We make 'files' and 'tmp' (logs) directories and files user and group writable (we removed the SGID bit)
        echo "... chmod -R u+w,g+w /var/www/MISP/app/files" && chmod -R u+w,g+w /var/www/MISP/app/files
    fi
    
    echo "... chown -R www-data:www-data /var/www/MISP/app/Config" && find /var/www/MISP/app/Config \( ! -user www-data -or ! -group www-data \) -exec chown www-data:www-data {} +
    # Files are also executable and read only, because we have some rogue scripts like 'cake' and we can not do a full inventory
    echo "... chmod -R 0550 files /var/www/MISP/app/Config ..." && find /var/www/MISP/app/Config -not -perm 550 -type f -exec chmod 0550 {} +
    # Directories are also writable, because there seems to be a requirement to add new files every once in a while
    echo "... chmod -R 0770 directories /var/www/MISP/app/Config" && find /var/www/MISP/app/Config -not -perm 770 -type d -exec chmod 0770 {} +
    # We make configuration files read only
    echo "... chmod 600 /var/www/MISP/app/Config/{config,database,email}.php" && chmod 600 /var/www/MISP/app/Config/{config,database,email}.php
}

flip_nginx() {
    local live="$1";
    local reload="$2";

    if [[ "$live" = "true" ]]; then
        NGINX_DOC_ROOT=/var/www/MISP/app/webroot
    elif [[ -x /custom/files/var/www/html/index.php ]]; then
        NGINX_DOC_ROOT=/custom/files/var/www/html/
    else
        NGINX_DOC_ROOT=/var/www/html/
    fi

    # must be valid for all roots
    echo "... nginx docroot set to ${NGINX_DOC_ROOT}"
    sed -i "s|root.*var/www.*|root ${NGINX_DOC_ROOT};|" /etc/nginx/includes/misp

    if [[ "$reload" = "true" ]]; then
        echo "... nginx reloaded"
        nginx -s reload
    fi
}

init_nginx() {
    # Adjust timeouts
    echo "... adjusting 'fastcgi_read_timeout' to ${FASTCGI_READ_TIMEOUT}"
    sed -i "s/fastcgi_read_timeout .*;/fastcgi_read_timeout ${FASTCGI_READ_TIMEOUT};/" /etc/nginx/includes/misp
    echo "... adjusting 'fastcgi_send_timeout' to ${FASTCGI_SEND_TIMEOUT}"
    sed -i "s/fastcgi_send_timeout .*;/fastcgi_send_timeout ${FASTCGI_SEND_TIMEOUT};/" /etc/nginx/includes/misp
    echo "... adjusting 'fastcgi_connect_timeout' to ${FASTCGI_CONNECT_TIMEOUT}"
    sed -i "s/fastcgi_connect_timeout .*;/fastcgi_connect_timeout ${FASTCGI_CONNECT_TIMEOUT};/" /etc/nginx/includes/misp

    # Adjust maximum allowed size of the client request body
    echo "... adjusting 'client_max_body_size' to ${NGINX_CLIENT_MAX_BODY_SIZE}"
    sed -i "s/client_max_body_size .*;/client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};/" /etc/nginx/includes/misp

    # Adjust forwarding header settings (clean up first)
    sed -i '/real_ip_header/d' /etc/nginx/includes/misp
    sed -i '/real_ip_recursive/d' /etc/nginx/includes/misp
    sed -i '/set_real_ip_from/d' /etc/nginx/includes/misp
    if [[ "$NGINX_X_FORWARDED_FOR" = "true" ]]; then
        echo "... enabling X-Forwarded-For header"
        echo "... setting 'real_ip_header X-Forwarded-For'"
        echo "... setting 'real_ip_recursive on'"
        sed -i "/index index.php/a real_ip_header X-Forwarded-For;\nreal_ip_recursive on;" /etc/nginx/includes/misp
        if [[ ! -z "$NGINX_SET_REAL_IP_FROM" ]]; then
            SET_REAL_IP_FROM_PRINT=$(echo $NGINX_SET_REAL_IP_FROM | tr ',' '\n')
            for real_ip in ${SET_REAL_IP_FROM_PRINT[@]}; do
                echo "... setting 'set_real_ip_from ${real_ip}'"
            done
            SET_REAL_IP_FROM=$(echo $NGINX_SET_REAL_IP_FROM | tr ',' '\n' | while read line; do echo -n "set_real_ip_from ${line};\n"; done)
            SET_REAL_IP_FROM_ESCAPED=$(echo $SET_REAL_IP_FROM | sed '$!s/$/\\/' | sed 's/\\n$//')
            sed -i "/real_ip_recursive on/a $SET_REAL_IP_FROM_ESCAPED" /etc/nginx/includes/misp
        fi
    fi

    # Adjust Content-Security-Policy
    echo "... adjusting Content-Security-Policy"
    # Remove any existing CSP header
    sed -i '/add_header Content-Security-Policy/d' /etc/nginx/includes/misp

    if [[ -n "$CONTENT_SECURITY_POLICY" ]]; then
        # If $CONTENT_SECURITY_POLICY is set, add CSP header
        echo "... setting Content-Security-Policy to '$CONTENT_SECURITY_POLICY'"
        sed -i "/add_header X-Download-Options/a add_header Content-Security-Policy \"$CONTENT_SECURITY_POLICY\";" /etc/nginx/includes/misp
    else
        # Otherwise, do not add any CSP headers
        echo "... no Content-Security-Policy header will be set as CONTENT_SECURITY_POLICY is not defined"
    fi

    # Adjust X-Frame-Options
    echo "... adjusting X-Frame-Options"
    # Remove any existing X-Frame-Options header
    sed -i '/add_header X-Frame-Options/d' /etc/nginx/includes/misp

    if [[ -z "$X_FRAME_OPTIONS" ]]; then
        echo "... setting 'X-Frame-Options SAMEORIGIN'"
        sed -i "/add_header X-Download-Options/a add_header X-Frame-Options \"SAMEORIGIN\" always;" /etc/nginx/includes/misp
    else
        echo "... setting 'X-Frame-Options $X_FRAME_OPTIONS'"
        sed -i "/add_header X-Download-Options/a add_header X-Frame-Options \"$X_FRAME_OPTIONS\";" /etc/nginx/includes/misp
    fi

    # Adjust HTTP Strict Transport Security (HSTS)
    echo "... adjusting HTTP Strict Transport Security (HSTS)"
    # Remove any existing HSTS header
    sed -i '/add_header Strict-Transport-Security/d' /etc/nginx/includes/misp

    if [[ -n "$HSTS_MAX_AGE" ]]; then
        # If $HSTS_MAX_AGE is defined, add the HSTS header
        echo "... setting HSTS to 'max-age=$HSTS_MAX_AGE; includeSubdomains'"
        sed -i "/add_header X-Download-Options/a add_header Strict-Transport-Security \"max-age=$HSTS_MAX_AGE; includeSubdomains\";" /etc/nginx/includes/misp
    else
        # Otherwise, do nothing, keeping without the HSTS header
        echo "... no HSTS header will be set as HSTS_MAX_AGE is not defined"
    fi

    # Testing for files also test for links, and generalize better to mounted files
    if [[ ! -f "/etc/nginx/sites-enabled/misp80" ]]; then
        echo "... enabling port 80 redirect"
        ln -s /etc/nginx/sites-available/misp80 /etc/nginx/sites-enabled/misp80
    else
        echo "... port 80 already enabled"
    fi
    if [[ "$DISABLE_IPV6" = "true" ]]; then
        echo "... disabling IPv6 on port 80"
        sed -i "s/[^#] listen \[/  # listen \[/" /etc/nginx/sites-enabled/misp80
    else
        echo "... enabling IPv6 on port 80"
        sed -i "s/# listen \[/listen \[/" /etc/nginx/sites-enabled/misp80
    fi
    if [[ "$DISABLE_SSL_REDIRECT" = "true" ]]; then
        echo "... disabling SSL redirect"
        sed -i "s/[^#] return /  # return /" /etc/nginx/sites-enabled/misp80
        sed -i "s/# include /include /" /etc/nginx/sites-enabled/misp80
    else
        echo "... enabling SSL redirect"
        sed -i "s/[^#] include /  # include /" /etc/nginx/sites-enabled/misp80
        sed -i "s/# return /return /" /etc/nginx/sites-enabled/misp80
    fi

    # Testing for files also test for links, and generalize better to mounted files
    if [[ ! -f "/etc/nginx/sites-enabled/misp443" ]]; then
        echo "... enabling port 443"
        ln -s /etc/nginx/sites-available/misp443 /etc/nginx/sites-enabled/misp443
    else
        echo "... port 443 already enabled"
    fi
    if [[ "$DISABLE_IPV6" = "true" ]]; then
        echo "... disabling IPv6 on port 443"
        sed -i "s/[^#] listen \[/  # listen \[/" /etc/nginx/sites-enabled/misp443
    else
        echo "... enabling IPv6 on port 443"
        sed -i "s/# listen \[/listen \[/" /etc/nginx/sites-enabled/misp443
    fi
    
    if [[ ! -f /etc/nginx/certs/cert.pem || ! -f /etc/nginx/certs/key.pem ]]; then
        echo "... generating new self-signed TLS certificate"
        openssl req -x509 -subj '/CN=localhost' -nodes -newkey rsa:4096 -keyout /etc/nginx/certs/key.pem -out /etc/nginx/certs/cert.pem -days 365 \
            -addext "subjectAltName = DNS:localhost, IP:127.0.0.1, IP:::1"
    else
        echo "... TLS certificates found"
    fi
    
    if [[ ! -f /etc/nginx/certs/dhparams.pem ]]; then
        echo "... generating new DH parameters"
        openssl dhparam -out /etc/nginx/certs/dhparams.pem 2048
    else
        echo "... DH parameters found"
    fi

    if [[ "$FASTCGI_STATUS_LISTEN" != "" ]]; then
        echo "... enabling php-fpm status page"
        ln -s /etc/nginx/sites-available/php-fpm-status /etc/nginx/sites-enabled/php-fpm-status
        sed -i -E "s/ listen [^;]+/ listen $FASTCGI_STATUS_LISTEN/" /etc/nginx/sites-enabled/php-fpm-status
    elif [[ -f /etc/nginx/sites-enabled/php-fpm-status ]]; then
        echo "... disabling php-fpm status page"
        rm /etc/nginx/sites-enabled/php-fpm-status
    fi

    flip_nginx false false
}


# Initialize MySQL
echo "INIT | Initialize MySQL ..." && init_mysql

# Initialize NGINX
echo "INIT | Initialize NGINX ..." && init_nginx
nginx -g 'daemon off;' & master_pid=$!

# Initialize MISP
echo "INIT | Initialize MISP files and configurations ..." && init_misp_data_files
echo "INIT | Update MISP app/files directory ..." && update_misp_data_files
echo "INIT | Enforce MISP permissions ..." && enforce_misp_data_permissions
echo "INIT | Flip NGINX live ..." && flip_nginx true true

# Run configure MISP script
echo "INIT | Configure MISP installation ..."
/configure_misp.sh

if [[ -x /custom/files/customize_misp.sh ]]; then
    echo "INIT | Customize MISP installation ..."
    /custom/files/customize_misp.sh
fi

# Restart PHP workers
echo "INIT | Configure PHP ..."
supervisorctl restart php-fpm
echo "INIT | Done ..."

# Wait for it
wait "$master_pid"
