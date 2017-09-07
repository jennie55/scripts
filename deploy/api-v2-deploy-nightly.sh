#!/bin/bash

. $(dirname $0)/deploy-functions-rename.sh

deployment_id="${1}"

# DEPLOYMENT-SPECIFIC SETTINGS AND OVERRIDES
case ${deployment_id} in
  api-v2)

    artifacts=( com.networkfleet:api-v2-spatial-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-driver-schedules-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-profile-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-triggered-alerts-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-triggered-activity-alerts-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-single-field-search-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-app-version-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-device-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-documentation:NIGHTLY-SNAPSHOT:war:api-v2-documentation#documentation
              )
    target_hosts=( tomcat@api1-nightly tomcat@api2-nightly )
    target_dir='/usr/local/tomcat/tomcat_api_v2/webapps'
    stop_cmd_seq='cd /usr/local/tomcat; ./stopApiV2.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/tomcat_api_v2/webapps/*/'
    start_cmd_seq='cd /usr/local/tomcat; ./startApiV2.sh'
    post_start_cmds_sleep='30'
    ;;

  feature-flip-console)

    artifacts=( com.networkfleet:feature-flip-console:NIGHTLY-SNAPSHOT:war
              )
    target_hosts=( tomcat@api1-nightly)
    target_dir='/usr/local/tomcat/tomcat_feature_flip_console/webapps'
    stop_cmd_seq='cd /usr/local/tomcat; ./stopFeatureFlipConsole.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/tomcat_feature_flip_console/webapps/*/'
    start_cmd_seq='cd /usr/local/tomcat; ./startFeatureFlipConsole.sh'
    post_start_cmds_sleep='30'
    ;;

  *)

    echo "Error: '"${deployment_id}"' is not a supported deployment."
    exit 1
    ;;
 
esac

deploy artifacts[@] target_hosts[@] "${stop_cmd_seq}" "${clean_cmd_seq}" "${start_cmd_seq}"
