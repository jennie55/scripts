#!/usr/bin/env bash
# LOCAL CONFIG
MVN_HOME=../../../tools/maven3/bin
#MVN_HOME=/usr/local/teamcity-data/buildAgent4/tools/maven3/bin

function resolveArtifacts(){

  declare -a mvn_coords=("${!1}")

  echo -e "\nRESOLVE/DOWNLOAD ARTIFACTS"
  #for mvn_coord in ${mvn_coords[@]}
  for artifact_coord in ${mvn_coords[@]}
  do
    # SET PATH AND MVN COORD
    PATH=${MVN_HOME}:$PATH
  
    # RESOLVE/DOWNLOAD MAVEN ARTIFACT

  IFS=':' read -a coord_tokens <<< "${artifact_coord}"

  group_id=${coord_tokens[0]}
  artifact_id=${coord_tokens[1]}
  version=${coord_tokens[2]}
  packaging=${coord_tokens[3]}

  echo "group_id=${coord_tokens[0]}"
  echo "artifact_id=${coord_tokens[1]}"
  echo "version=${coord_tokens[2]}"
  echo "packaging=${coord_tokens[3]}"

  pom_coord="${group_id}:${artifact_id}:${version}:pom"
  pom_filename="${artifact_id}.pom"

  mvn -q org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact=${pom_coord} -Dmdep.stripVersion=true -DoutputDirectory=.

  mvn -q -f ${pom_filename} org.apache.maven.plugins:maven-dependency-plugin:2.8:purge-local-repository -DmanualInclude="${group_id}:${artifact_id}" -DreResolve=false -DactTransitively=false

  mvn -U -q org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact=${group_id}:${artifact_id}:${version}:${packaging} -Dmdep.useBaseVersion=false -DoutputDirectory=.

  downloaded_artifacts=( ${artifact_id}*.${packaging} )
  [[ ${#downloaded_artifacts[@]} -eq 1 ]] || { echo "Expected one and only one artifact to download"; exit 1; }
  artifact_filename=${downloaded_artifacts[0]}
  echo "downloaded: ${artifact_filename}"
#    mvn -U -q org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact=${mvn_coord} -Dmdep.useBaseVersion=false -DoutputDirectory=.
    [[ $? -eq 0 ]] || { echo "Deployment failed. Cannot resolve/download: ${mvn_coord}"; exit 1; }
  done
}

function copyArtifacts(){

  declare -a target_hosts=("${!1}")
  target_dir=${2}
  declare -a mvn_coords=("${!3}")

  tmp='/tmp/deploy'

  for mvn_coord in ${mvn_coords[@]}
  do

    # PARSE MAVEN COORDINATE
    IFS=':' read -a mvn_coord_tokens <<< "${mvn_coord}"
    [[ ${#mvn_coord_tokens[@]} -lt 4 ]] && { echo "Error - Invalid Maven Coord: ${mvn_coord} "; exit 1; }

    artifact_id=${mvn_coord_tokens[1]}
    version=${mvn_coord_tokens[2]}
    packaging=${mvn_coord_tokens[3]}
    custom_filename=${mvn_coord_tokens[4]}

    echo "mvn_coord=${mvn_coord}"
    echo "artifact_id=${artifact_id}"
    echo "version=${version}"
    echo "packaging=${packaging}"
    echo "custom_filename=${custom_filename}"

    downloaded_artifacts=( ${artifact_id}*.${packaging} )
    for da in $downloaded_artifacts
    do
	    echo -e "\tdownladed artifactd: $da"
    done

    [[ ${#downloaded_artifacts[@]} -eq 1 ]] || { echo "Expected one and only one artifact to download"; exit 1; }

    filename_versioned="${downloaded_artifacts[0]}"
    if [[ -z ${custom_filename} ]]
    then
    	filename_base="${artifact_id}.${packaging}"
    else
    	filename_base="${custom_filename}.${packaging}"
    fi
    echo "filename_base=${filename_base}"

    # WORKAROUND
    # allstate-ws gets deployed as webservice.war. To deploy it as allstate-ws.war
    # while still maintaining the context-root of /webservice would require the use
    # of a deployment descriptor which is more complex than what we need to do
    # right now. As a result, we change the name of the file to webservice.war
#    [[ ${artifact_id} = "allstate-ws" ]] && { filename_base=webservice.war; };	

    echo -e "\nBACKUP CURRENT ARTIFACTS"
    for target_host in ${target_hosts[@]}
    do
      backup_cmd="mkdir -p ${tmp}; cp -p ${target_dir}/${filename_base} ${tmp}/${filename_base}.last;"
      echo "${target_host}: ${backup_cmd}"
      ssh ${target_host} "${backup_cmd}"
    done

    echo -e "\nREMOVE OLD ARTIFACTS"
    for target_host in ${target_hosts[@]}
    do
      rm_cmd="rm -f ${tmp}/${artifact_id}*${packaging};"
      echo "${target_host}: ${rm_cmd}"
      ssh ${target_host} "${rm_cmd}"
    done

    echo -e "\nCOPY VERSIONED ARTIFACTS TO TMP DIR ON TARGETS"
    for target_host in ${target_hosts[@]}
    do
      rsync --progress ${filename_versioned} "${target_host}:${tmp}"
      [[ $? -eq 0 ]] || { echo "Deployment failed. Cannot rsync ${filename_versioned} to ${target_host}:${tmp}"; exit 1; }
    done

    echo -e "\nCOPY VERSIONED ARTIFACTS TO BASE ARTIFACTS"
    copy_cmd="cp -p ${tmp}/${filename_versioned} ${target_dir}/${filename_base};"
    for target_host in ${target_hosts[@]}
    do
      echo "${target_host}: ${copy_cmd}"
      ssh ${target_host} "${copy_cmd}"
      [[ $? -eq 0 ]] || { echo "Deployment failed. Cannot copy ${filename_versioned} to ${filename_base} on ${target_host}"; exit 1; }
    done

  done
}

function stopContainers(){

  declare -a target_hosts=("${!1}")
  stop_cmd_seq="${2}"

  echo -e "\nSTOP CONTAINERS"
  for target_host in ${target_hosts[@]}
  do
    echo "${target_host}: ${stop_cmd_seq}"
    ssh "${target_host}" "${stop_cmd_seq}" > stop.log 2>&1
    [[ $? -eq 0 ]] || { echo "Warning: Cannot stop container on ${target_host}"; }
  done
  sleep 30
}

function cleanup(){

  declare -a target_hosts=("${!1}")
  clean_cmd_seq=${2}

  # OPTIONAL
  if [ ! -z "${clean_cmd_seq}" ]; then

    echo -e "\nPERFORM CLEANUPS"
    for target_host in ${target_hosts[@]}
    do
      echo "${target_host}: ${clean_cmd_seq}"
      ssh "${target_host}" "${clean_cmd_seq}" > cleanup.log 2>&1
      [[ $? -eq 0 ]] || { echo "Deployment failed. Cannot cleanup with ${clean_cmd_seq}"; exit 1; }
    done

  fi
}

function startContainers(){

  declare -a target_hosts=("${!1}")
  start_cmd_seq=${2}

  echo -e "\nSTART CONTAINERS"
  for target_host in ${target_hosts[@]}
  do
    echo "${target_host}: ${start_cmd_seq}"
    #ssh "${target_host}" "${start_cmd_seq}" &
    ssh "${target_host}" "${start_cmd_seq}" > start.log 2>&1
    [[ $? -eq 0 ]] || { echo "Deployment failed. Cannot start container on ${target_host}"; exit 1; }
  done
  sleep 30

}

function setUpTmpDir(){

  rm -rf tmp; mkdir tmp; pushd tmp
}

function tearDownTmpDir(){

  popd; rm -r tmp
}

function deploy(){

  declare -a artifacts=("${!1}")
  declare -a target_hosts=("${!2}")
  stop_cmd_seq=${3}
  clean_cmd_seq=${4}
  start_cmd_seq=${5}

  setUpTmpDir

  resolveArtifacts artifacts[@]

  stopContainers target_hosts[@] "${stop_cmd_seq}"

  [[ ! -z "${post_stop_cmds_sleep}" ]] && { sleep "${post_stop_cmds_sleep}"; }

  copyArtifacts target_hosts[@] "${target_dir}" artifacts[@]

  cleanup target_hosts[@] "${clean_cmd_seq}"

  startContainers target_hosts[@] "${start_cmd_seq}"

  [[ ! -z "${post_start_cmds_sleep}" ]] && { sleep "${post_start_cmds_sleep}"; }

#  tearDownTmpDir

  echo -e "\nDEPLOYMENT COMPLETE"
}
