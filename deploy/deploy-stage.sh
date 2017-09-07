#!/bin/bash 
. $(dirname $0)/deploy-functions.sh

deployment_id="${1}"
branch_name="${2}"

# Get the version from a pom file. parent is used because it is small and MUST have nwf.version.
function get_rev() {
   svn --quiet checkout https://svn.networkfleet.com/repos/ted3/parent/branches/$1 parent
   FROM_REV=$(grep "<nwf.version>"  parent/pom.xml  | cut -d '>' -f 2 | cut -d '<' -f 1)
   export artifacts_version=$FROM_REV
   rm -fr parent
}


# check that we have a branch name from where to get the full version.
if [ -z $branch_name ] ; then
   echo "branch name is required as second parameter. Aborting..."
   exit 999
else
   echo "Using branch $branch_name"
   get_rev $branch_name
fi

echo "Deploying version $artifacts_version"

#exit 0

# DEPLOYMENT-SPECIFIC SETTINGS AND OVERRIDES
case ${deployment_id} in

#  alertengine)
#
#    artifacts=( com.networkfleet:alertengine:NIGHTLY-SNAPSHOT:war )
#    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
#    target_dir='/usr/local/eda/tomcat_AA/webapps'
#    stop_cmd_seq='cd /usr/local/eda/tomcat_AA/bin; ./shutdown.sh; sleep 60'
#    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_AA/webapps/alertengine'
#    start_cmd_seq='cd /usr/local/eda/tomcat_AA/bin; ./startup.sh'
#    ;;

  api)

    artifacts=( com.networkfleet:api-server:${artifacts_version}:war
                com.networkfleet:api-management:${artifacts_version}:war
                com.networkfleet:oauth2-authorization-server:${artifacts_version}:war )
    target_hosts=( bea@starsky bea@hutch )
    target_dir='/usr/local/bea/domains11/api-stage/deployments'
    stop_cmd_seq='cd /usr/local/bea/domains11/api-stage; ./stopApiNode?.sh --force'
    post_stop_cmds_sleep='60'
    clean_cmd_seq='rm -rf /usr/local/bea/domains11/api-stage/servers/API.Node?'
    start_cmd_seq='cd /usr/local/bea/domains11/api-stage; ./startApiNode?.sh'
    ;;

  nwftoa)

    artifacts=( com.networkfleet:nwftoa:${artifacts_version}:war )
    target_hosts=( tomcat@toa1-xo)
    target_dir='/usr/local/tomcat/nwftoa1/webapps'
    stop_cmd_seq='cd /usr/local/tomcat/nwftoa1/bin; ./stopNwftoa.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/arch_node1/webapps/nwftoa'
    # Changing the name from arch-nightly to arch
    start_cmd_seq='cd /usr/local/tomcat/nwftoa1/bin; ./startNwftoa.sh'
    post_start_cmds_sleep='30'
    ;;


  arch)

    artifacts=( com.networkfleet:arch:${artifacts_version}:war )
    target_hosts=( tomcat@arch1-stage tomcat@arch2-stage )
    target_dir='/usr/local/tomcat/arch_node/webapps'
    stop_cmd_seq='cd /usr/local/tomcat; ./stopArch.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/tomcat/arch_node/webapps/arch'
    start_cmd_seq='mv /usr/local/tomcat/arch_node/webapps/arch-staging.war /usr/local/tomcat/arch_node/webapps/arch.war; cd /usr/local/tomcat; ./startArch.sh'
    post_start_cmds_sleep='60'
    ;;

  dataconnect)

    artifacts=( com.networkfleet:dataconnect:${artifacts_version}:war )
    target_hosts=( datapipe@dp1-stage datapipe@dp2-stage )
    target_dir='/usr/local/datapipe/tomcat_DC/webapps'
    stop_cmd_seq='cd /usr/local/datapipe/tomcat_DC/bin; ./shutdown.sh;'
    post_stop_cmds_sleep='180'
    clean_cmd_seq='rm -rf /usr/local/datapipe/tomcat_DC/webapps/dataconnect-staging'
    start_cmd_seq='cd /usr/local/datapipe/tomcat_DC/bin; ./startup.sh;'
    post_start_cmds_sleep='60'
    ;;

  ssp)

    artifacts=( com.networkfleet:ssp:${artifacts_version}:war )
    target_hosts=( bea@starsky bea@hutch )
    target_dir='/usr/local/bea12.1.2/user_projects/domains/ssp_domain/deployments'
    stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/ssp_domain; ./stopSsp?.sh --force'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/ssp_domain/servers/SSP.Node?/*'
    start_cmd_seq='cd      /usr/local/bea12.1.2/user_projects/domains/ssp_domain; ./startSsp?.sh'
    ;;

  eda-jjk)

    artifacts=( com.networkfleet.eda:eda-jjk:${artifacts_version}:war )
    target_hosts=( eda@eda-admin-stage )
    target_dir='/usr/local/eda/tomcat_jjk/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_jjk/bin; ./shutdown.sh'
    post_stop_cmds_sleep='30'
    #clean_cmd_seq='rm -rf /usr/local/eda/tomcat_jjk/webapps/eda-jjk-*'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_jjk/webapps/eda-jjk-stage'
    start_cmd_seq='cd /usr/local/eda/tomcat_jjk/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;

  eda-tax)
    artifacts=( com.networkfleet.eda:eda-tax:${artifacts_version}:war )
    target_hosts=( eda@eda-admin-stage )
    target_dir='/usr/local/eda/tomcat_tax/webapps'
    stop_cmd_seq='cd /usr/local/eda/tomcat_tax/bin; ./shutdown.sh'
    post_stop_cmds_sleep='30'
    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_tax/webapps/eda-tax'
    start_cmd_seq='cd /usr/local/eda/tomcat_tax/bin; ./startup.sh'
    post_start_cmds_sleep='30'
    ;;

  portal)
      artifacts=( com.networkfleet:allstate-ws:${artifacts_version}:war
                  com.networkfleet:nwf-portal:${artifacts_version}:war)
      target_hosts=( bea@starsky bea@hutch )
      target_dir='/usr/local/bea12.1.2/user_projects/domains/nwf-portal/deployments'
      stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/nwf-portal; ./stopPortal?.sh --force'
      post_stop_cmds_sleep='30'
      clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/nwf-portal/servers/STAGE.portal* '
      start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/nwf-portal; ./startPortal?.sh'
      ;;

  reports)
      artifacts=( com.networkfleet:nwf-portal:${artifacts_version}:war)
      target_hosts=( bea@rep1-stage )
      target_dir='/usr/local/bea12.1.2/user_projects/domains/report/deployments'
      stop_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/report; ./stopAdmin.sh; sleep 15;  ./stopReport1.sh --force'
      post_stop_cmds_sleep='30'
      clean_cmd_seq='rm -rf /usr/local/bea12.1.2/user_projects/domains/report/servers/STAGE.report* '
      start_cmd_seq='cd /usr/local/bea12.1.2/user_projects/domains/report; ./startAdmin.sh; sleep 15; ./startReport1.sh'
      ;;

  rungps)

      artifacts=( com.networkfleet.rungps:rungps-web:${artifacts_version}:war )
      target_hosts=( tomcat@rungps-stage  )
      target_dir='/usr/share/tomcat6/rungps_node/webapps'
      stop_cmd_seq='cd /usr/share/tomcat6/rungps_node/bin; ./stop-rungps.sh --force'
      post_stop_cmds_sleep='30'
      clean_cmd_seq='rm -rf /usr/share/tomcat6/rungps_node/webapps/rungps-web'
      # Changing the name
      start_cmd_seq='cd /usr/share/tomcat6/rungps_node; mv webapps/rungps-web-*.war webapps/rungps-web.war; ./bin/start-rungps.sh'
      post_start_cmds_sleep='30'
      ;;


#  lobbymap)
#
#    artifacts=( com.networkfleet:lobbymap:NIGHTLY-SNAPSHOT:war )
#    target_hosts=( tomcat@lobbymap-nightly )
#    target_dir='/usr/share/tomcat6/webapps'
#    stop_cmd_seq='cd /usr/share/tomcat6; ./stopTomcat.sh'
#    post_stop_cmds_sleep='60'
#    clean_cmd_seq='rm -rf /usr/share/tomcat6/webapps/lobbymap'
#    start_cmd_seq='cd /usr/share/tomcat6; ./startTomcat.sh'
#    ;;


 
#  message-processor)
#
#    artifacts=( com.networkfleet:message-processor:NIGHTLY-SNAPSHOT:war )
#    target_hosts=( eda@eda1-nightly eda@eda2-nightly eda@eda3-nightly eda@eda4-nightly )
#    target_dir='/usr/local/eda/tomcat_MP/webapps'
#    stop_cmd_seq='cd /usr/local/eda/tomcat_MP/bin; ./shutdown.sh; sleep 60'
#    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_MP/webapps/message-processor'
#    start_cmd_seq='cd /usr/local/eda/tomcat_MP/bin; ./startup.sh'
#    ;;
 
#  message-processor-activation)
#
#    artifacts=( com.networkfleet:message-processor:NIGHTLY-SNAPSHOT:war )
#    target_hosts=( eda@eda5-nightly )
#    target_dir='/usr/local/eda/tomcat_activation/webapps'
#    stop_cmd_seq='cd /usr/local/eda/tomcat_activation/bin; ./shutdown.sh; sleep 60'
#    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_activation/webapps/message-processor'
#    start_cmd_seq='cd /usr/local/eda/tomcat_activation/bin; ./startup.sh'
#    ;;	  
 
#  message-processor-email)
#
#    artifacts=( com.networkfleet:message-processor:NIGHTLY-SNAPSHOT:war )
#    target_hosts=( eda@eda5-nightly )
#    target_dir='/usr/local/eda/tomcat_email/webapps'
#    stop_cmd_seq='cd /usr/local/eda/tomcat_email/bin; ./shutdown.sh; sleep 60'
#    clean_cmd_seq='rm -rf /usr/local/eda/tomcat_email/webapps/message-processor'
#    start_cmd_seq='cd /usr/local/eda/tomcat_email/bin; ./startup.sh'
#    ;;


  *)

    echo "Error: '"${deployment_id}"' is not a supported deployment."
    exit 1
    ;;
 
esac

date >>  /tmp/deploy-stage.txt
echo -e "Snapshot ${artifacts_version}\n deployment id ${deployment_id} \n" >> /tmp/deploy-stage.txt

deploy artifacts[@] target_hosts[@] "${stop_cmd_seq}" "${clean_cmd_seq}" "${start_cmd_seq}"
