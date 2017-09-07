#!/bin/bash

. $(dirname $0)/deploy-functions.sh

deployment_id="${1}"

# DEPLOYMENT-SPECIFIC SETTINGS AND OVERRIDES
case ${deployment_id} in

  alertengine)

    artifacts=( com.networkfleet.eda:alertengine-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
    target_dir='/usr/local/eda/tomcat_AA/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_AA/bin; ./shutdown.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_AA/webapps/alertengine*'
    start_cmd_seq='cd /usr/local/eda/tomcat_AA/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;
 
  api)

    artifacts=( com.networkfleet:api-server-nightly:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-management-nightly:NIGHTLY-SNAPSHOT:war
                com.networkfleet:oauth2-authorization-server-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@starsky )
    target_dir='/usr/local/bea12.1.2/user_projects/domains/api-nightly/deployments'
    stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/api-nightly; ./stopAPI.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/api-nightly/servers/API.Nightly'
    start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/api-nightly; ./startAPI.sh'
    post_start_cmds_sleep='60'
    ;;

  arch)

    artifacts=( com.networkfleet:arch-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@arch-nightly )
    target_dir='/usr/local/tomcat/arch_node1/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/arch_node1/bin; ./stopArch.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/arch_node1/webapps/arch'
    # Changing the name from arch-nightly to arch
    start_cmd_seq='cd /usr/local/tomcat/arch_node1/bin; mv /usr/local/tomcat/arch_node1/webapps/arch-nightly.war /usr/local/tomcat/arch_node1/webapps/arch.war; ./startArch.sh'
    post_start_cmds_sleep='30'
    ;;

  dataconnect)

    artifacts=( com.networkfleet:dataconnect-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( datapipe@dp1-nightly datapipe@dp2-nightly )
    target_dir='/usr/local/datapipe/tomcat_DC/webapps'
    stop_cmd_seq='cd /usr/local/datapipe/tomcat_DC/bin; ./shutdown.sh'
    post_stop_cmds_sleep='120'
    clean_cmd_seq='rm -rf /usr/local/datapipe/tomcat_DC/webapps/dataconnect-nightly'
    start_cmd_seq='cd /usr/local/datapipe/tomcat_DC/bin; ./startup.sh'
    post_start_cmds_sleep='60'
    ;;

  hcg)

    artifacts=( com.networkfleet:hcg:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@hcg-nightly )
    target_dir='/usr/local/tomcat/hcg1/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/hcg1/bin; ./stopHcg.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf  /usr/local/tomcat/hcg1/webapps/hcg'
    start_cmd_seq='cd /usr/local/tomcat/hcg1/bin;  ./startHcg.sh'
    post_start_cmds_sleep='30'
    ;;	  

  lobbymap)

    artifacts=( com.networkfleet:lobbymap:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@lobbymap-nightly )
    target_dir='/usr/share/tomcat6/webapps'
    stop_cmd_seq='cd /usr/share/tomcat6; ./stopTomcat.sh'
    post_stop_cmds_sleep='60'
    clean_cmd_seq='rm -rf /usr/share/tomcat6/webapps/lobbymap'
    start_cmd_seq='cd /usr/share/tomcat6; ./startTomcat.sh'
    ;;	  
 
  message-processor)

    artifacts=( com.networkfleet.eda:message-processor-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
    target_dir='/usr/local/eda/tomcat_MP/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_MP/bin; ./shutdown.sh'
    post_stop_cmds_sleep='60'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_MP/webapps/message-processor*'
    start_cmd_seq='cd /usr/local/eda/tomcat_MP/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;
 
  message-processor-activation)

    artifacts=( com.networkfleet.eda:message-processor-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_activation/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_activation/bin; ./shutdown.sh'
    post_stop_cmds_sleep='60'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_activation/webapps/message-processor*'
    start_cmd_seq='cd /usr/local/eda/tomcat_activation/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;
 
  message-processor-email)

    artifacts=( com.networkfleet.eda:message-processor-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_email/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_email/bin; ./shutdown.sh'
    post_stop_cmds_sleep='60'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_email/webapps/message-processor/*'
    start_cmd_seq='cd /usr/local/eda/tomcat_email/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;
 
  portal)

    artifacts=( com.networkfleet:nwf-portal:NIGHTLY-SNAPSHOT:war
                com.networkfleet:allstate-ws:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@app1-nightly )
    target_dir='/usr/local/bea12.1.2/user_projects/domains/Nightly.Portal/deployments'
    stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal; ./stopPortal.sh --force'
    post_stop_cmds_sleep='15'
    clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal/servers/*'
    start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal; ./startPortal.sh'
    ;;  	  

  ssp)

    artifacts=( com.networkfleet:ssp-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@ssp-dev )
    target_dir='/usr/local/bea/user_projects/domains/base_domain/deployments'
    stop_cmd_seq='cd /usr/local/bea/user_projects/domains/base_domain; ./stopSsp.sh --force'
    post_stop_cmds_sleep='15'
#    clean_cmd_seq='rm -rf /usr/local/bea/user_projects/domains/base_domain/servers/sspServer'
    start_cmd_seq='cd /usr/local/bea/user_projects/domains/base_domain; ./startSsp.sh'
	    ;;

  eda-jjk)

    artifacts=( com.networkfleet.eda:eda-jjk-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_jjk/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_jjk/bin; ./shutdown.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_jjk/webapps/eda-jjk-nightly'
    start_cmd_seq='cd /usr/local/eda/tomcat_jjk/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;

  eda-tax)

    artifacts=( com.networkfleet.eda:eda-tax-nightly:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_tax/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_tax/bin; ./shutdown.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_tax/webapps/eda-tax-nightly'
    start_cmd_seq='cd /usr/local/eda/tomcat_tax/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;

  *)

    echo "Error: '"${deployment_id}"' is not a supported deployment."
    exit 1
    ;;
 
esac

deploy artifacts[@] target_hosts[@] "${stop_cmd_seq}" "${clean_cmd_seq}" "${start_cmd_seq}"
