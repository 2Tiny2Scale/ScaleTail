#!/bin/bash

# Check whether passed env variables are defined
check_env_vars() {
    local required_vars=("$@")

    missing_vars=()
    for i in "${required_vars[@]}"
    do
        test -n "${!i:+y}" || missing_vars+=("$i")
    done
    if [ ${#missing_vars[@]} -ne 0 ]
    then
        echo "The following env variables are not set:"
        printf ' %q\n' "${missing_vars[@]}"
        exit 1
    fi
}

# Kludgy alternative to using cake Admin getSetting.
setting_is_set_alt() {
    local setting="$1"
    local config_json=$(echo '<?php require_once "/var/www/MISP/app/Config/config.php"; echo json_encode($config, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES); ?>'|/usr/bin/php)
    local db_settings_enabled=$(jq -e 'getpath(("MISP.system_setting_db" | split("."))) // false' <<< $config_json)
    local setting_in_config_file=$(jq -e 'getpath(("'"$setting"'" | split("."))) != null' <<< $config_json) 
    if $setting_in_config_file; then
        return 0
    elif $db_settings_enabled; then
        local setting_in_db=$(echo "SELECT EXISTS(SELECT 1 FROM $MYSQL_DATABASE.system_settings WHERE setting = \"${setting}\");" | ${MYSQL_CMD})
        if [[ $setting_in_db -eq 1 ]]; then
            return 0
        fi
    fi
    return 1
}

set_default_settings() {
    local settings_json="$1"
    local description="$2"

    for setting in $(jq -r 'keys[]' <<< $settings_json); do
        local default_value="$(jq -r '."'"$setting"'"["default_value"]' <<< $settings_json)"
        local command_args="$(jq -r '."'"$setting"'"["command_args"] // ""' <<< $settings_json)"

        set_safe_default "$setting" "$default_value" "$description" "$command_args"
    done
}

enforce_env_settings() {
    local settings_json="$1"
    local description="$2"
    for setting in $(jq -r 'keys[]' <<< $settings_json); do
        local default_value="$(jq -r '."'"$setting"'"["default_value"]' <<< $settings_json)"
        local command_args="$(jq -r '."'"$setting"'"["command_args"] // ""' <<< $settings_json)"
        echo "Enforcing $description setting '$setting' to env var or default value '$default_value'..."
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q $command_args "$setting" "$default_value"
    done
}

set_safe_default() {
    local setting="$1"
    local default_value="$2"
    local description="$3"
    local command_args="$4"

    if ! setting_is_set_alt "$setting"; then
        echo "Updating unset $description setting '$setting' to '$default_value'..."
        sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting -q $command_args "$setting" "$default_value"
    fi
}

init_settings() {
    local description="$1"
    local enforced="/etc/misp-docker/${description}.envars.json"
    local defaults="/etc/misp-docker/${description}.defaults.json"

    if [[ -e "$enforced" ]]; then
        echo "... enforcing env var settings"
        local settings_json="$(envsubst < $enforced)"
        enforce_env_settings "$settings_json" "$description"
    fi

    if [[ -e "$defaults" ]]; then
        echo "... checking for unset default settings"
        local settings_json="$(cat $defaults)"
        set_default_settings "$settings_json" "$description"
    fi
}