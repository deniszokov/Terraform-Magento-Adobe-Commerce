#!/bin/bash

declare -A parameter
while IFS== read -r key value; do parameter["$key"]="$value"; done < <(echo ${PARAMETERSTORE} | jq -r 'to_entries[] | .key + "=" + .value')
composer -n -q config -g http-basic.repo.magento.com ${parameter["COMPOSER_USER"]} ${parameter["COMPOSER_PASS"]}
composer install -n
## make magento 2 great again
sed -i "s/2-4/2-5/" app/etc/di.xml
## install magento 2
chmod +x bin/magento
bin/magento setup:install \
--base-url=https://${parameter["DOMAIN"]}/ \
--base-url-secure=https://${parameter["DOMAIN"]}/ \
--db-host=${parameter["DATABASE_ENDPOINT"]} \
--db-name=${parameter["DATABASE_NAME"]} \
--db-user=${parameter["DATABASE_USER_NAME"]} \
--db-password=${parameter["DATABASE_PASSWORD"]} \
--admin-firstname=${parameter["ADMIN_FIRSTNAME"]} \
--admin-lastname=${parameter["ADMIN_LASTNAME"]} \
--admin-email=${parameter["ADMIN_EMAIL"]} \
--admin-user=${parameter["ADMIN_LOGIN"]} \
--admin-password=${parameter["ADMIN_PASSWORD"]} \
--backend-frontname=${parameter["ADMIN_PATH"]} \
--language=${parameter["LANGUAGE"]} \
--currency=${parameter["CURRENCY"]} \
--timezone=${parameter["TIMEZONE"]} \
--cleanup-database \
--session-save=files \
--use-rewrites=1 \
--use-secure=1 \
--use-secure-admin=1 \
--consumers-wait-for-messages=0 \
--amqp-host=${parameter["RABBITMQ_ENDPOINT"]} \
--amqp-port=5671 \
--amqp-user=${parameter["RABBITMQ_USER"]} \
--amqp-password=${parameter["RABBITMQ_PASSWORD"]} \
--amqp-virtualhost='/' \
--amqp-ssl=true \
--search-engine=elasticsearch7 \
--elasticsearch-host=${parameter["ELASTICSEARCH_ENDPOINT"]} \
--elasticsearch-port=443 \
--elasticsearch-index-prefix=${parameter["BRAND"]} \
--elasticsearch-enable-auth=0
## installation check
if [[ $? -ne 0 ]]; then
echo
echo "Installation error - check command output log"
exit 1
fi
if [ ! -f app/etc/env.php ]; then
echo
echo "Installation error - env.php not available"
exit 1
fi
## cache backend
bin/magento setup:config:set \
--cache-id-prefix=${parameter["CACHE_PREFIX"]} \
--cache-backend=redis \
--cache-backend-redis-server=${parameter["REDIS_CACHE_BACKEND"]} \
--cache-backend-redis-port=6379 \
--cache-backend-redis-db=0 \
--cache-backend-redis-compress-data=1 \
--cache-backend-redis-compression-lib=l4z \
-n
## session
bin/magento setup:config:set \
--session-save=redis \
--session-save-redis-host=${parameter["REDIS_SESSION_BACKEND"]} \
--session-save-redis-port=6379 \
--session-save-redis-log-level=3 \
--session-save-redis-db=0 \
--session-save-redis-compression-lib=lz4 \
--session-save-redis-persistent-id=${parameter["SESSION_PERSISTENT"]} \
-n
## add cache optimization
sed -i "/${parameter["REDIS_CACHE_BACKEND"]}/a\            'load_from_slave' => '${parameter["REDIS_CACHE_BACKEND_RO"]}:6379', \\
      'master_write_only' => '0', \\
      'retry_reads_on_master' => '1', \\
      'persistent' => '${parameter["SESSION_PERSISTENT"]}', \\
      'preload_keys' => [ \\
              '${parameter["CACHE_PREFIX"]}_EAV_ENTITY_TYPES', \\
              '${parameter["CACHE_PREFIX"]}_GLOBAL_PLUGIN_LIST', \\
              '${parameter["CACHE_PREFIX"]}_DB_IS_UP_TO_DATE', \\
              '${parameter["CACHE_PREFIX"]}_SYSTEM_DEFAULT', \\
          ],"  app/etc/env.php
## clean cache
rm -rf var/cache var/page_cache
## enable s3 remote storage
bin/magento setup:config:set --remote-storage-driver=aws-s3 \
--remote-storage-bucket=${parameter["S3_MEDIA_BUCKET"]} \
--remote-storage-region=${parameter["AWS_DEFAULT_REGION"]} \
-n
## sync to s3 remote storage
bin/magento remote-storage:sync
## install modules to properly test magento 2 production-ready functionality
composer -n require mageplaza/module-smtp
if [ "${parameter["FASTLY"]}" == "enabled" ]; then
composer -n require fastly/magento2
fi
bin/magento setup:upgrade -n --no-ansi
## module initialization check
if [[ $? -ne 0 ]]; then
echo
echo "Module initialization error - check command output log"
exit 1
fi
## correct general contact name and email address
bin/magento config:set trans_email/ident_general/name ${parameter["BRAND"]}
bin/magento config:set trans_email/ident_general/email ${parameter["ADMIN_EMAIL"]}
## configure smtp ses 
bin/magento config:set smtp/general/enabled 1
bin/magento config:set smtp/general/log_email 0
bin/magento config:set smtp/configuration_option/host ${parameter["SES_ENDPOINT"]}
bin/magento config:set smtp/configuration_option/port 587
bin/magento config:set smtp/configuration_option/protocol tls
bin/magento config:set smtp/configuration_option/authentication login
bin/magento config:set smtp/configuration_option/username ${parameter["SES_KEY"]}
bin/magento config:set smtp/configuration_option/password ${parameter["SES_PASSWORD"]}
bin/magento config:set smtp/configuration_option/test_email/from general
bin/magento config:set smtp/configuration_option/test_email/to ${parameter["ADMIN_EMAIL"]}
bin/magento config:set smtp/developer/developer_mode 0
## explicitly set the new catalog media url format
bin/magento config:set web/url/catalog_media_url_format image_optimization_parameters
## configure media
bin/magento config:set web/unsecure/base_media_url https://${parameter["S3_MEDIA_BUCKET_URL"]}/media/
bin/magento config:set web/secure/base_media_url https://${parameter["S3_MEDIA_BUCKET_URL"]}/media/
## minify js and css
bin/magento config:set dev/css/minify_files 1
bin/magento config:set dev/js/minify_files 1
bin/magento config:set dev/js/move_script_to_bottom 1
## enable hsts upgrade headers
bin/magento config:set web/secure/enable_hsts 1
bin/magento config:set web/secure/enable_upgrade_insecure 1
## enable eav cache
bin/magento config:set dev/caching/cache_user_defined_attributes 1
## enable local varnish cache yay!
if [ "${parameter["FASTLY"]}" == "disabled" ]; then
bin/magento config:set --scope=default --scope-code=0 system/full_page_cache/caching_application 2
bin/magento setup:config:set --http-cache-hosts=127.0.0.1:80
fi
echo 007 > magento_umask
echo -e '/pub/media/*\n/var/*' > .gitignore

