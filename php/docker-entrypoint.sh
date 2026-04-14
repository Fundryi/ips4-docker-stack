#!/bin/sh
set -e

INI=/usr/local/etc/php/conf.d/zz-env.ini
FPM=/usr/local/etc/php-fpm.d/zz-env.conf

: > "$INI"
: > "$FPM"

emit_ini() { if [ -n "$2" ]; then echo "$1=$2" >> "$INI"; fi; }
emit_fpm() { if [ -n "$2" ]; then echo "$1 = $2" >> "$FPM"; fi; }

emit_ini memory_limit                       "$PHP_MEMORY_LIMIT"
emit_ini upload_max_filesize                "$PHP_UPLOAD_MAX_FILESIZE"
emit_ini post_max_size                      "$PHP_POST_MAX_SIZE"
emit_ini max_execution_time                 "$PHP_MAX_EXECUTION_TIME"
emit_ini max_input_time                     "$PHP_MAX_INPUT_TIME"
emit_ini max_input_vars                     "$PHP_MAX_INPUT_VARS"
emit_ini date.timezone                      "$PHP_DATE_TIMEZONE"
emit_ini display_errors                     "$PHP_DISPLAY_ERRORS"
emit_ini opcache.memory_consumption         "$PHP_OPCACHE_MEMORY_CONSUMPTION"
emit_ini opcache.max_accelerated_files      "$PHP_OPCACHE_MAX_ACCELERATED_FILES"
emit_ini opcache.validate_timestamps        "$PHP_OPCACHE_VALIDATE_TIMESTAMPS"
emit_ini opcache.revalidate_freq            "$PHP_OPCACHE_REVALIDATE_FREQ"
emit_ini opcache.interned_strings_buffer    "$PHP_OPCACHE_INTERNED_STRINGS_BUFFER"

if [ -n "$FPM_PM" ] || [ -n "$FPM_PM_MAX_CHILDREN" ] || [ -n "$FPM_PM_START_SERVERS" ] \
   || [ -n "$FPM_PM_MIN_SPARE_SERVERS" ] || [ -n "$FPM_PM_MAX_SPARE_SERVERS" ] \
   || [ -n "$FPM_PM_MAX_REQUESTS" ] || [ -n "$FPM_REQUEST_TERMINATE_TIMEOUT" ]; then
    echo "[www]" >> "$FPM"
    emit_fpm pm                         "$FPM_PM"
    emit_fpm pm.max_children            "$FPM_PM_MAX_CHILDREN"
    emit_fpm pm.start_servers           "$FPM_PM_START_SERVERS"
    emit_fpm pm.min_spare_servers       "$FPM_PM_MIN_SPARE_SERVERS"
    emit_fpm pm.max_spare_servers       "$FPM_PM_MAX_SPARE_SERVERS"
    emit_fpm pm.max_requests            "$FPM_PM_MAX_REQUESTS"
    emit_fpm request_terminate_timeout  "$FPM_REQUEST_TERMINATE_TIMEOUT"
fi

exec docker-php-entrypoint "$@"
