#!/bin/bash

source /rest_client.sh
source /utilities.sh

# We now use envsubst for safe variable substitution with pseudo-json objects for env var enforcement
# envsubst won't evaluate anything like $() or conditional variable expansion so lets do that here
export PYTHON_BIN="$(which python3)"
export GPG_BINARY="$(which gpg)"
export SETTING_CONTACT="${MISP_CONTACT-$ADMIN_EMAIL}"
export SETTING_EMAIL="${MISP_EMAIL-$ADMIN_EMAIL}"

init_minimum_config() {
    # Temporarily disable DB to apply config file settings, reenable after if needed 
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "MISP.system_setting_db" false
    init_settings "minimum_config"
}

init_configuration() {
    init_settings "db_enable"
    init_settings "initialisation"
}

init_workers() {
    echo "... starting background workers"
    stdbuf -oL supervisorctl start misp-workers:*
}

configure_gnupg() {
    if [ "$AUTOCONF_GPG" != "true" ]; then
        echo "... GPG auto configuration disabled"
        return
    fi

    export GPG_DIR=/var/www/MISP/.gnupg
    GPG_ASC=/var/www/MISP/app/webroot/gpg.asc
    GPG_TMP=/tmp/gpg.tmp

    if [ ! -f "${GPG_DIR}/trustdb.gpg" ]; then
        echo "... generating new GPG key in ${GPG_DIR}"
        cat >${GPG_TMP} <<GPGEOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 3072
Name-Real: MISP Admin
Name-Email: ${MISP_EMAIL-$ADMIN_EMAIL}
Expire-Date: 0
Passphrase: $GPG_PASSPHRASE
%commit
%echo Done
GPGEOF
        mkdir -p ${GPG_DIR}
        gpg --homedir ${GPG_DIR} --gen-key --batch ${GPG_TMP}
        rm -f ${GPG_TMP}
    else
        echo "... found pre-generated GPG key in ${GPG_DIR}"
    fi

    # Fix permissions
    chown -R www-data:www-data ${GPG_DIR}
    find ${GPG_DIR} -type f -exec chmod 600 {} \;
    find ${GPG_DIR} -type d -exec chmod 700 {} \;

    if [ ! -f ${GPG_ASC} ]; then
        echo "... exporting GPG key"
        sudo -u www-data gpg --homedir ${GPG_DIR} --export --armor ${MISP_EMAIL-$ADMIN_EMAIL} > ${GPG_ASC}
    else
        echo "... found exported key ${GPG_ASC}"
    fi

    init_settings "gpg"
}

set_up_oidc() {
    if [[ "$OIDC_ENABLE" == "true" ]]; then
        if [[ -z "$OIDC_ROLES_MAPPING" ]]; then
            OIDC_ROLES_MAPPING="\"\""
        fi

        # Check required variables
        # OIDC_ISSUER may be empty
        check_env_vars OIDC_PROVIDER_URL OIDC_CLIENT_ID OIDC_CLIENT_SECRET OIDC_ROLES_PROPERTY OIDC_ROLES_MAPPING OIDC_DEFAULT_ORG

        # Configure OIDC in MISP
        sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
            \"Security\": {
                \"auth\": [\"OidcAuth.Oidc\"]
            }
        }" > /dev/null

        # Set OIDC authentication details in MISP
        sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
            \"OidcAuth\": {
                \"provider_url\": \"${OIDC_PROVIDER_URL}\",
                ${OIDC_ISSUER:+\"issuer\": \"${OIDC_ISSUER}\",}
                \"client_id\": \"${OIDC_CLIENT_ID}\",
                \"client_secret\": \"${OIDC_CLIENT_SECRET}\",
                \"roles_property\": \"${OIDC_ROLES_PROPERTY}\",
                \"role_mapper\": ${OIDC_ROLES_MAPPING},
                \"default_org\": \"${OIDC_DEFAULT_ORG}\"
            }
        }" > /dev/null

        # Check if OIDC_SCOPES is set and is an array
        if [[ "$(echo "$OIDC_SCOPES" | jq type -r)" == "array" ]]; then
            # Run the modify_config.php script to update OidcAuth configuration with the provided OIDC_SCOPES
            # The 'scopes' field will only be added if OIDC_SCOPES has a value
            sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
                \"OidcAuth\": {
                    \"scopes\": ${OIDC_SCOPES}
                }
            }" > /dev/null
        fi

        # Set the custom logout URL for OIDC if it is defined
        if [[ -n "${OIDC_LOGOUT_URL}" ]]; then
            sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Plugin.CustomAuth_custom_logout" "${OIDC_LOGOUT_URL}&post_logout_redirect_uri=${BASE_URL}/users/login"
        else
            echo "OIDC_LOGOUT_URL is not set"
        fi

        # Disable password confirmation as recommended in https://github.com/MISP/MISP/issues/8116
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.require_password_confirmation" false

        echo "... OIDC authentication enabled"

    else
        # Reset OIDC authentication settings to empty values
        sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
            \"OidcAuth\": {
                \"provider_url\": \"\",
                \"issuer\": \"\",
                \"client_id\": \"\",
                \"client_secret\": \"\",
                \"roles_property\": \"\",
                \"role_mapper\": \"\",
                \"default_org\": \"\"
            }
        }" > /dev/null

        # Remove the line containing 'scopes' => from config.php
        # This prevents an empty scopes entry from being loaded in the configuration.
        sudo -u www-data sed -i "/'scopes' =>/d" /var/www/MISP/app/Config/config.php

        # Use sed to remove the OidcAuth.Oidc entry from the 'auth' array in the config.php
        sudo -u www-data sed -i "/'auth' =>/,/)/ { /0 => 'OidcAuth.Oidc',/d; }" /var/www/MISP/app/Config/config.php

        # Remove the custom logout URL
        sudo -u www-data sed -i "/'CustomAuth_custom_logout' =>/d" /var/www/MISP/app/Config/config.php

        # Re-enable password confirmation if necessary
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.require_password_confirmation" true

        echo "... OIDC authentication disabled"
    fi
}

set_up_apachesecureauth() {
    if [[ "$APACHESECUREAUTH_LDAP_ENABLE" != "true" ]]; then
        echo "... LDAP APACHESECUREAUTH authentication disabled"
        return
    fi


    if [ ! -z "$APACHESECUREAUTH_LDAP_OLD_VAR_DETECT" ]; then
        echo "WARNING: old variables used for APACHESECUREAUTH bloc in env file. Switch to the new naming convention."
    fi

    # Check required variables
    # APACHESECUREAUTH_LDAP_SEARCH_FILTER may be empty
    check_env_vars APACHESECUREAUTH_LDAP_APACHE_ENV APACHESECUREAUTH_LDAP_SERVER APACHESECUREAUTH_LDAP_STARTTLS APACHESECUREAUTH_LDAP_READER_USER APACHESECUREAUTH_LDAP_READER_PASSWORD APACHESECUREAUTH_LDAP_DN APACHESECUREAUTH_LDAP_SEARCH_ATTRIBUTE APACHESECUREAUTH_LDAP_FILTER APACHESECUREAUTH_LDAP_DEFAULT_ROLE_ID APACHESECUREAUTH_LDAP_DEFAULT_ORG APACHESECUREAUTH_LDAP_OPT_PROTOCOL_VERSION APACHESECUREAUTH_LDAP_OPT_NETWORK_TIMEOUT APACHESECUREAUTH_LDAP_OPT_REFERRALS

    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
        \"ApacheSecureAuth\": {
            \"apacheEnv\": \"${APACHESECUREAUTH_LDAP_APACHE_ENV}\",
            \"ldapServer\": \"${APACHESECUREAUTH_LDAP_SERVER}\",
            \"starttls\": ${APACHESECUREAUTH_LDAP_STARTTLS},
            \"ldapProtocol\": ${APACHESECUREAUTH_LDAP_OPT_PROTOCOL_VERSION},
            \"ldapNetworkTimeout\": ${APACHESECUREAUTH_LDAP_OPT_NETWORK_TIMEOUT},
            \"ldapReaderUser\": \"${APACHESECUREAUTH_LDAP_READER_USER}\",
            \"ldapReaderPassword\": \"${APACHESECUREAUTH_LDAP_READER_PASSWORD}\",
            \"ldapDN\": \"${APACHESECUREAUTH_LDAP_DN}\",
            \"ldapSearchFilter\": \"${APACHESECUREAUTH_LDAP_SEARCH_FILTER}\",
            \"ldapSearchAttribut\": \"${APACHESECUREAUTH_LDAP_SEARCH_ATTRIBUTE}\",
            \"ldapFilter\": ${APACHESECUREAUTH_LDAP_FILTER},
            \"ldapDefaultRoleId\": ${APACHESECUREAUTH_LDAP_DEFAULT_ROLE_ID},
            \"ldapDefaultOrg\": \"${APACHESECUREAUTH_LDAP_DEFAULT_ORG}\",
            \"ldapAllowReferrals\": ${APACHESECUREAUTH_LDAP_OPT_REFERRALS},
            \"ldapEmailField\": ${APACHESECUREAUTH_LDAP_EMAIL_FIELD}
        }
    }" > /dev/null

    # Disable password confirmation as stated at https://github.com/MISP/MISP/issues/8116
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.require_password_confirmation" false
}

set_up_ldap() {
    if [[ "$LDAPAUTH_ENABLE" != "true" ]]; then
        echo "... LDAPAUTH authentication disabled"
        return
    fi

    # Check required variables
    # LDAPAUTH_LDAPSEARCHFILTER may be empty
    check_env_vars LDAPAUTH_LDAPSERVER LDAPAUTH_LDAPDN LDAPAUTH_LDAPREADERUSER LDAPAUTH_LDAPREADERPASSWORD LDAPAUTH_LDAPSEARCHATTRIBUTE LDAPAUTH_LDAPDEFAULTROLEID LDAPAUTH_LDAPDEFAULTORGID LDAPAUTH_LDAPEMAILFIELD LDAPAUTH_LDAPNETWORKTIMEOUT LDAPAUTH_LDAPPROTOCOL LDAPAUTH_LDAPALLOWREFERRALS LDAPAUTH_STARTTLS LDAPAUTH_MIXEDAUTH LDAPAUTH_UPDATEUSER LDAPAUTH_DEBUG LDAPAUTH_LDAPTLSREQUIRECERT LDAPAUTH_LDAPTLSCUSTOMCACERT LDAPAUTH_LDAPTLSCRLCHECK LDAPAUTH_LDAPTLSPROTOCOLMIN

    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
        \"LdapAuth\": {
          \"ldapServer\": \"${LDAPAUTH_LDAPSERVER}\",
          \"ldapDn\": \"${LDAPAUTH_LDAPDN}\",
          \"ldapReaderUser\": \"${LDAPAUTH_LDAPREADERUSER}\",
          \"ldapReaderPassword\": \"${LDAPAUTH_LDAPREADERPASSWORD}\",
          \"ldapSearchFilter\": \"${LDAPAUTH_LDAPSEARCHFILTER}\",
          \"ldapSearchAttribute\": \"${LDAPAUTH_LDAPSEARCHATTRIBUTE}\",
          \"ldapEmailField\": ${LDAPAUTH_LDAPEMAILFIELD},
          \"ldapNetworkTimeout\": ${LDAPAUTH_LDAPNETWORKTIMEOUT},
          \"ldapProtocol\": ${LDAPAUTH_LDAPPROTOCOL},
          \"ldapAllowReferrals\": ${LDAPAUTH_LDAPALLOWREFERRALS},
          \"starttls\": ${LDAPAUTH_STARTTLS},
          \"mixedAuth\": ${LDAPAUTH_MIXEDAUTH},
          \"ldapDefaultOrgId\": ${LDAPAUTH_LDAPDEFAULTORGID},
          \"ldapDefaultRoleId\": ${LDAPAUTH_LDAPDEFAULTROLEID},
          \"updateUser\": ${LDAPAUTH_UPDATEUSER},
          \"debug\": ${LDAPAUTH_DEBUG},
          \"ldapTlsRequireCert\": \"${LDAPAUTH_LDAPTLSREQUIRECERT}\",
          \"ldapTlsCustomCaCert\": ${LDAPAUTH_LDAPTLSCUSTOMCACERT},
          \"ldapTlsCrlCheck\": \"${LDAPAUTH_LDAPTLSCRLCHECK}\",
          \"ldapTlsProtocolMin\": \"${LDAPAUTH_LDAPTLSPROTOCOLMIN}\"
       }
    }" > /dev/null

    # Configure LdapAuth in MISP
    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
            \"Security\": {
                \"auth\": [\"LdapAuth.Ldap\"]
            }
        }" > /dev/null


    # Disable password confirmation as stated at https://github.com/MISP/MISP/issues/8116
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.require_password_confirmation" false
}

set_up_aad() {
    if [[ "$AAD_ENABLE" != "true" ]]; then
        echo "... Entra (AzureAD) authentication disabled"
        return
    fi

    # Check required variables
    check_env_vars AAD_CLIENT_ID AAD_TENANT_ID AAD_CLIENT_SECRET AAD_REDIRECT_URI AAD_PROVIDER AAD_PROVIDER_USER AAD_MISP_ORGADMIN AAD_MISP_SITEADMIN AAD_CHECK_GROUPS

    # Note: Not necessary to edit bootstrap.php to load AadAuth Cake plugin because 
    # existing loadAll() call in bootstrap.php already loads all available Cake plugins

    # Set auth mechanism to AAD in config.php file
    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
        \"Security\": {
            \"auth\": [\"AadAuth.AadAuthenticate\"]
        }
    }" > /dev/null

    # Configure AAD auth settings from environment variables in config.php file
    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
        \"AadAuth\": {
            \"client_id\": \"${AAD_CLIENT_ID}\",
            \"ad_tenant\": \"${AAD_TENANT_ID}\",
            \"client_secret\": \"${AAD_CLIENT_SECRET}\",
            \"redirect_uri\": \"${AAD_REDIRECT_URI}\",
            \"auth_provider\": \"${AAD_PROVIDER}\",
            \"auth_provider_user\": \"${AAD_PROVIDER_USER}\",
            \"misp_user\": \"${AAD_MISP_USER}\",
            \"misp_orgadmin\": \"${AAD_MISP_ORGADMIN}\",
            \"misp_siteadmin\": \"${AAD_MISP_SITEADMIN}\",
            \"check_ad_groups\": ${AAD_CHECK_GROUPS}
        }
    }" > /dev/null

    # Disable self-management, username change, and password change to prevent users from circumventing AAD login flow
    # Recommended per https://github.com/MISP/MISP/blob/2.4/app/Plugin/AadAuth/README.md
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "MISP.disableUserSelfManagement" true
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "MISP.disable_user_login_change" true
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "MISP.disable_user_password_change" true

    # Disable password confirmation as stated at https://github.com/MISP/MISP/issues/8116
    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.require_password_confirmation" false
}

set_up_session() {
    # Command to modify MISP session configuration
    sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
        \"Session\": {
            \"timeout\": ${PHP_SESSION_TIMEOUT},
            \"cookie_timeout\": ${PHP_SESSION_COOKIE_TIMEOUT},
            \"defaults\": \"${PHP_SESSION_DEFAULTS}\",
            \"autoRegenerate\": ${PHP_SESSION_AUTO_REGENERATE},
            \"checkAgent\": ${PHP_SESSION_CHECK_AGENT},
            \"ini\": {
                \"session.cookie_secure\": ${PHP_SESSION_COOKIE_SECURE},
                \"session.cookie_domain\": \"${PHP_SESSION_COOKIE_DOMAIN}\",
                \"session.cookie_samesite\": \"${PHP_SESSION_COOKIE_SAMESITE}\"
            }
        }
    }" > /dev/null

    echo "... Session configured"
}

set_up_proxy() {
    if [[ "$PROXY_ENABLE" == "true" ]]; then
        echo "... configuring proxy settings"
        init_settings "proxy"
    else
        echo "... Proxy disabled"
    fi
}

apply_updates() {
    # Disable 'ZeroMQ_enable' to get better logs when applying updates
#    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Plugin.ZeroMQ_enable" false
    # Run updates (strip colors since output might end up in a log)
    sudo -u www-data /var/www/MISP/app/Console/cake Admin runUpdates | stdbuf -oL sed -r "s/[[:cntrl:]]\[[0-9]{1,3}m//g"
    # Re-enable 'ZeroMQ_enable'
#    sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Plugin.ZeroMQ_enable" true
}

init_user() {
    # Create the main user if it is not there already
    sudo -u www-data /var/www/MISP/app/Console/cake user init -q > /dev/null 2>&1

    echo "UPDATE $MYSQL_DATABASE.users SET email = \"${ADMIN_EMAIL}\" WHERE id = 1;" | ${MYSQL_CMD}

    if [ ! -z "$ADMIN_ORG" ]; then
        echo "... setting admin org to '${ADMIN_ORG}'"
        echo "UPDATE $MYSQL_DATABASE.organisations SET name = \"${ADMIN_ORG}\" where id = 1;" | ${MYSQL_CMD}
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "MISP.org" "${ADMIN_ORG}"
    fi

    if [ ! -z "$ADMIN_ORG_UUID" ]; then
        echo "... setting admin org uuid to '${ADMIN_ORG_UUID}'"
        echo "UPDATE $MYSQL_DATABASE.organisations SET uuid = \"${ADMIN_ORG_UUID}\" where id = 1;" | ${MYSQL_CMD}
    fi

    if [ -n "$ADMIN_KEY" ]; then
        echo "... setting admin key to '${ADMIN_KEY}'"
        CHANGE_CMD=(sudo -u www-data /var/www/MISP/app/Console/cake User change_authkey 1 "${ADMIN_KEY}")
    elif [ -z "$ADMIN_KEY" ] && [ "$AUTOGEN_ADMIN_KEY" == "true" ]; then
        echo "... regenerating admin key (set \$ADMIN_KEY if you want it to change)"
        CHANGE_CMD=(sudo -u www-data /var/www/MISP/app/Console/cake User change_authkey 1)
    else
        echo "... admin user key auto generation disabled"
    fi

    if [[ -v CHANGE_CMD[@] ]]; then
        ADMIN_KEY=$("${CHANGE_CMD[@]}" | awk 'END {print $NF; exit}')
        echo "... admin user key set to '${ADMIN_KEY}'"
    fi

    if [ ! -z "$ADMIN_PASSWORD" ]; then
        echo "... setting admin password to '${ADMIN_PASSWORD}'"
        PASSWORD_POLICY=$(sudo -u www-data /var/www/MISP/app/Console/cake Admin getSetting "Security.password_policy_complexity" | jq ".value" -r)
        PASSWORD_LENGTH=$(sudo -u www-data /var/www/MISP/app/Console/cake Admin getSetting "Security.password_policy_length" | jq ".value" -r)
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.password_policy_length" 1
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.password_policy_complexity" '/.*/'
        sudo -u www-data /var/www/MISP/app/Console/cake User change_pw "${ADMIN_EMAIL}" "${ADMIN_PASSWORD}"
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.password_policy_complexity" "${PASSWORD_POLICY}"
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q "Security.password_policy_length" "${PASSWORD_LENGTH}"
    else
        echo "... setting admin password skipped"
    fi
    echo "UPDATE $MYSQL_DATABASE.users SET change_pw = 0 WHERE id = 1;" | ${MYSQL_CMD}
}

apply_critical_fixes() {
    init_settings "critical"

    # Kludge for handling Security.auth array.  Unrecognised by tools like cake admin setsetting.
    local config_json=$(echo '<?php require_once "/var/www/MISP/app/Config/config.php"; echo json_encode($config, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES); ?>'|/usr/bin/php)
    if $(echo $config_json |jq -e 'getpath(("Security.auth" | split("."))) == null'); then
        echo "Updating unset critical setting 'Security.auth' to 'Array()'..."
        sudo -u www-data php /var/www/MISP/tests/modify_config.php modify "{
            \"Security\": {
                \"auth\": {}
            }
        }" > /dev/null
    fi
}

apply_optional_fixes() {
    init_settings "optional"
}

# Some settings return a value from cake Admin getSetting even if not set in config.php and database.
# This means we cannot rely on that tool which inspects both db and file.
# Leaving this here though in case the serverSettings model for those odd settings is fixed one day.
#setting_is_set() {
#    local setting="$1"
#    local current_value="$(sudo -u www-data /var/www/MISP/app/Console/cake Admin getSetting $setting)"
#    local error_value="$(jq -r '.errorMessage' <<< $current_value)"
#
#    if [[ "$current_value" =~ ^\{.*\}$ && "$error_value" != "Value not set." && "$error_value" != Invalid* ]]; then
#       return 0
#    else
#       return 1
#    fi
#}

update_components() {
    UPDATE_SUDO_CMD="sudo -u www-data"
    if [ ! -z "${DB_ALREADY_INITIALISED}" ]; then
        if [[ "$ENABLE_BACKGROUND_UPDATES" = "true" ]]; then
            echo "... updates will run in the background"
            UPDATE_SUDO_CMD="sudo -b -u www-data"
        fi
    fi
    ${UPDATE_SUDO_CMD} /var/www/MISP/app/Console/cake Admin updateGalaxies
    ${UPDATE_SUDO_CMD} /var/www/MISP/app/Console/cake Admin updateTaxonomies
    ${UPDATE_SUDO_CMD} /var/www/MISP/app/Console/cake Admin updateWarningLists
    ${UPDATE_SUDO_CMD} /var/www/MISP/app/Console/cake Admin updateNoticeLists
    ${UPDATE_SUDO_CMD} /var/www/MISP/app/Console/cake Admin updateObjectTemplates "$CRON_USER_ID"
}

update_ca_certificates() {
    # Upgrade host os certificates
    update-ca-certificates
    # Upgrade cake cacert.pem file from Mozilla project
    echo "Updating /var/www/MISP/app/Lib/cakephp/lib/Cake/Config/cacert.pem..."
    sudo -E -u www-data curl -s --etag-compare /var/www/MISP/app/Lib/cakephp/lib/Cake/Config/etag.txt --etag-save /var/www/MISP/app/Lib/cakephp/lib/Cake/Config/etag.txt https://curl.se/ca/cacert.pem -o /var/www/MISP/app/Lib/cakephp/lib/Cake/Config/cacert.pem
}

create_sync_servers() {
    if [ -z "$ADMIN_KEY" ]; then
        echo "... admin key auto configuration is required to configure sync servers"
        return
    fi

    SPLITTED_SYNCSERVERS=$(echo $SYNCSERVERS | tr ',' '\n')
    for ID in $SPLITTED_SYNCSERVERS; do
        DATA="SYNCSERVERS_${ID}_DATA"

        # Validate #1
        NAME=$(echo "${!DATA}" | jq -r '.name')
        if [[ -z $NAME ]]; then
            echo "... error missing sync server name"
            continue
        fi

        # Skip sync server if we can
        echo "... searching sync server ${NAME}"
        SERVER_ID=$(get_server ${BASE_URL} ${ADMIN_KEY} ${NAME})
        if [[ -n "$SERVER_ID" ]]; then
            echo "... found existing sync server ${NAME} with id ${SERVER_ID}"
            continue
        fi

        # Validate #2
        UUID=$(echo "${!DATA}" | jq -r '.remote_org_uuid')
        if [[ -z "$UUID" ]]; then
            echo "... error missing sync server remote_org_uuid"
            continue
        fi

        # Get remote organization
        echo "... searching remote organization ${UUID}"
        ORG_ID=$(get_organization ${BASE_URL} ${ADMIN_KEY} ${UUID})
        if [[ -z "$ORG_ID" ]]; then
            # Add remote organization if missing
            echo "... adding missing organization ${UUID}"
            add_organization ${BASE_URL} ${ADMIN_KEY} ${NAME} false ${UUID} > /dev/null
            ORG_ID=$(get_organization ${BASE_URL} ${ADMIN_KEY} ${UUID})
        fi

        # Add sync server
        echo "... adding new sync server ${NAME} with organization id ${ORG_ID}"
        JSON_DATA=$(echo "${!DATA}" | jq --arg org_id ${ORG_ID} 'del(.remote_org_uuid) | . + {remote_org_id: $org_id} | del(..|select(. == ""))')
        add_server ${BASE_URL} ${ADMIN_KEY} "$JSON_DATA" > /dev/null
    done
}

echo "MISP | Update CA certificates ..." && update_ca_certificates

echo "MISP | Apply minimum configuration directives ..." && init_minimum_config

echo "MISP | Initialize configuration ..." && init_configuration

echo "MISP | Initialize workers ..." && init_workers

echo "MISP | Apply DB updates ..." && apply_updates

echo "MISP | Configure GPG key ..." && configure_gnupg

echo "MISP | Init default user and organization ..." && init_user

echo "MISP | Resolve critical issues ..." && apply_critical_fixes

echo "MISP | Start component updates ..." && update_components

echo "MISP | Resolve non-critical issues ..." && apply_optional_fixes

echo "MISP | Create sync servers ..." && create_sync_servers

echo "MISP | Set Up OIDC ..." && set_up_oidc

echo "MISP | Set Up apachesecureauth ..." && set_up_apachesecureauth

echo "MISP | Set Up LDAP ..." && set_up_ldap

echo "MISP | Set Up AAD ..." && set_up_aad

echo "MISP | Set Up Session ..." && set_up_session

echo "MISP | Set Up Proxy ..." && set_up_proxy

echo "MISP | Mark instance live"
sudo -u www-data /var/www/MISP/app/Console/cake Admin live 1
