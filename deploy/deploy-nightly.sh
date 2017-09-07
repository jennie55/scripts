#!/bin/bash

. $(dirname $0)/deploy-functions.sh

deployment_id="${1}"

# DEPLOYMENT-SPECIFIC SETTINGS AND OVERRIDES
case ${deployment_id} in

  alertengine)

    artifacts=( com.networkfleet.eda:alertengine:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
    target_dir='/usr/local/eda/tomcat_AA/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_AA/webapps/alertengine*'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh'
    post_start_cmds_sleep='30'
    ;;
 
  api)

    artifacts=( com.networkfleet:api-server:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-management:NIGHTLY-SNAPSHOT:war
                com.networkfleet:oauth2-authorization-server:NIGHTLY-SNAPSHOT:war 
                com.networkfleet:api-sandbox:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@app1-nightly)
    target_dir='/usr/local/bea12.1.2/user_projects/domains/api-nightly/deployments'
    stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/api-nightly; ./stopAPI.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/api-nightly/servers/API.Nightly'
    start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/api-nightly; ./startAPI.sh'
    post_start_cmds_sleep='60'
    ;;

  api-v2)

    artifacts=( com.networkfleet:api-v2-spatial-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-driver-schedules-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-profile-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-triggered-alerts-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-triggered-activity-alerts-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-single-field-search-webapp:NIGHTLY-SNAPSHOT:war
                com.networkfleet:api-v2-app-version-webapp:NIGHTLY-SNAPSHOT:war
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

  nwftoa)

    artifacts=( com.networkfleet:nwftoa:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@toa1-dev )
    target_dir='/usr/local/tomcat/nwftoa1/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/nwftoa1/bin; ./stopNwftoa.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/nwftoa1/webapps/nwftoa'
    #
    start_cmd_seq='cd /usr/local/tomcat/nwftoa1/bin; ./startNwftoa.sh'
    post_start_cmds_sleep='30'
    ;;

  arch)

    artifacts=( com.networkfleet:arch:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@arch1-nightly tomcat@arch2-nightly )
    target_dir='/usr/local/tomcat/arch_node/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/arch_node/bin; ./stopArch.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/arch_node/webapps/arch'
    # Changing the name from arch-nightly to arch
    start_cmd_seq='mv /usr/local/tomcat/arch_node/webapps/arch-nightly.war /usr/local/tomcat/arch_node/webapps/arch.war; cd /usr/local/tomcat/arch_node/bin; ./startArch.sh'
    post_start_cmds_sleep='30'
    ;;


  rungps)

    artifacts=( com.networkfleet.rungps:rungps-web:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@rungps-nightly  )
    target_dir='/usr/local/tomcat/rungps_node/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/rungps_node/bin; ./stop-rungps.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/rungps_node/webapps/rungps-web'
    # Changing the name
    start_cmd_seq='cd /usr/local/tomcat/rungps_node; mv webapps/rungps-web-NIGHTLY*.war webapps/rungps-web.war; ./bin/start-rungps.sh'
    post_start_cmds_sleep='30'
    ;;

  arch-webservices)

    artifacts=( com.networkfleet:arch-webservices:NIGHTLY-SNAPSHOT:war )
    target_hosts=( tomcat@arch1-nightly tomcat@arch2-nightly )
    target_dir='/usr/local/tomcat/archws_node/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/archws_node/bin; ./stopArchWS.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/archws_node/webapps/arch-webservices'
    # Changing the name from arch-nightly to arch
    start_cmd_seq='cd /usr/local/tomcat/archws_node/bin; ./startArchWS.sh'
    post_start_cmds_sleep='30'
    ;;

  dataconnect)

    artifacts=( com.networkfleet:dataconnect:NIGHTLY-SNAPSHOT:war )
    target_hosts=( datapipe@dc1-nightly datapipe@dc2-nightly )
    target_dir='/usr/local/datapipe/tomcat_DC/webapps'
    stop_cmd_seq='cd /usr/local/datapipe; ./stop_all.sh --app DATACONNECT'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/datapipe/tomcat_DC/webapps/dataconnect'
    start_cmd_seq='cd /usr/local/datapipe; ./start_all.sh --app DATACONNECT'
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

    artifacts=( com.networkfleet.eda:message-processor:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
    target_dir='/usr/local/eda/tomcat_MP/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_MP/webapps/message-processor*'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh'
    post_start_cmds_sleep='30'
    ;;
 
  message-processor-activation)

    artifacts=( com.networkfleet.eda:message-processor:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_activation/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_activation/webapps/message-processor*'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh'
    post_start_cmds_sleep='30'
    ;;
 
  portal)

    artifacts=( com.networkfleet:nwf-portal:NIGHTLY-SNAPSHOT:war
                com.networkfleet:allstate-ws:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@app1-nightly )
    # target_dir='/usr/local/bea12.1.2/user_projects/domains/Nightly.Portal/deployments'
    target_dir='/usr/local/bea12.1.3/user_projects/domains/nwf-portal/deployments'
    #stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal; ./stopPortal.sh --force'
    stop_cmd_seq='cd /usr/local/bea12.1.3/user_projects/domains/nwf-portal; ./stopPortal.sh --force'
    post_stop_cmds_sleep='15'
    #clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal/servers/*'
    #clean_cmd_seq='find /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal/servers/Nightly.Portal/* -maxdepth 1 -type d -not -name security | xargs rm -fr'
    #start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Portal; ./startPortal.sh'
    clean_cmd_seq='find /usr/local/bea12.1.3/user_projects/domains/nwf-portal/servers/portal-nightly/* -maxdepth 1 -type d -not -name security | xargs rm -fr'
    start_cmd_seq='cd /usr/local/bea12.1.3/user_projects/domains/nwf-portal; ./startPortal.sh'

    ;;  	  


  portal-feature1)
    artifacts=( com.networkfleet:nwf-portal:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@app1-nightly )
    # /usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1
    target_dir='/usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1/deployments'
    stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1; ./stopPortal.sh --force'
    post_stop_cmds_sleep='15'
    #clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1/servers/*'
    clean_cmd_seq='find /usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1/servers/Nightly.Feature1/* -maxdepth 1 -type d -not -name security | xargs rm -fr'
    start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/Nightly.Feature1; ./startPortal.sh'
    ;;

  ssp)

    artifacts=( com.networkfleet:ssp:NIGHTLY-SNAPSHOT:war )
    target_hosts=( bea@ssp1-nightly )
    target_dir='/usr/local/bea_latest/user_projects/domains/ssp_domain/deployments'
    stop_cmd_seq='cd /usr/local/bea_latest/user_projects/domains/ssp_domain; ./stopSsp.sh --force'
    post_stop_cmds_sleep='15'
    clean_cmd_seq='find /usr/local/bea_latest/user_projects/domains/ssp_domain/servers/sspServer/* -maxdepth 1 -type d -not -name security | xargs rm -fr'
    start_cmd_seq='cd /usr/local/bea_latest/user_projects/domains/ssp_domain; ./startSsp.sh'
	    ;;

  eda-jjk)

    artifacts=( com.networkfleet.eda:eda-jjk:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_jjk/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_jjk/webapps/eda-jjk'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh'
    post_start_cmds_sleep='30'
    ;;

  eda-tax)

    artifacts=( com.networkfleet.eda:eda-tax:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@eda-admin-nightly )
    target_dir='/usr/local/eda/tomcat_tax/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh'
    post_stop_cmds_sleep='0'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_tax/webapps/eda-tax'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh'
    post_start_cmds_sleep='30'
    ;;

  eda-rp)

    artifacts=( com.networkfleet.eda:eda-report-preprocessor:NIGHTLY-SNAPSHOT:war )
    target_hosts=( eda@edarp1-nightly eda@edarp2-nightly  )
    target_dir='/usr/local/eda/tomcat_RP/webapps'
    stop_cmd_seq='cd /usr/local/eda; ./stop_all.sh --app RP'
    post_stop_cmds_sleep='0'
    #clean_cmd_seq='rm -rf /usr/local/eda/tomcat_RP/webapps/eda-*'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_RP/webapps/eda-report-preprocessor'
    start_cmd_seq='cd /usr/local/eda; ./start_all.sh --app RP'
    post_start_cmds_sleep='30'
    ;;


  *)

    echo "Error: '"${deployment_id}"' is not a supported deployment."
    exit 1
    ;;
 
esac

deploy artifacts[@] target_hosts[@] "${stop_cmd_seq}" "${clean_cmd_seq}" "${start_cmd_seq}"
