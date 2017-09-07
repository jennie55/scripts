#!/bin/bash

set -e

[[ $# -eq 0 ]] && { echo "Usage: create-overlay-project [BASE_ARTIFACT_COORD]"; exit 1; }

baseline_artifact_coord="${1}"

IFS=':' read -a coord_tokens <<< "${baseline_artifact_coord}"
baseline_group_id="${coord_tokens[0]}"
baseline_artifact_id="${coord_tokens[1]}"
baseline_version="${coord_tokens[2]}"
baseline_packaging="${coord_tokens[3]}"

overlay_artifact_id="${baseline_artifact_id}-env"

resolve_baseline_artifact(){

  printf '%-31s' 'Resolving baseline artifact...'

  dependency='org.apache.maven.plugins:maven-dependency-plugin:2.8'

  mvn -q -P repos ${dependency}:get -Dartifact="${baseline_artifact_coord}" \
                                    -Dtransitive=false

  printf 'Complete\n'

}

create_overlay_project(){

  printf '%-31s' 'Creating overlay project...'

  archetype='org.apache.maven.plugins:maven-archetype-plugin:2.2'

  mvn -U -q -P repos ${archetype}:generate -DarchetypeGroupId=com.networkfleet \
                                           -DarchetypeArtifactId=overlay-archetype \
                                           -DarchetypeVersion=1.0.0-SNAPSHOT \
                                           -DgroupId="${baseline_group_id}" \
                                           -DartifactId="${overlay_artifact_id}" \
                                           -Dversion="${baseline_version}" \
                                           -DbaselineArtifactId="${baseline_artifact_id}" \
                                           -DbaselinePackaging="${baseline_packaging}" \
                                           -DinteractiveMode=false

  printf 'Complete\n'

}

customize_modules(){

  printf '%-31s' 'Customizing modules...'
 
  pushd "${overlay_artifact_id}" > /dev/null

  search_term='-env-'
  replacement='-'
  
  # SEARCH/REPLACE FILE CONTENTS
  files=`grep -rl --include=pom.xml "${search_term}" *`
  for file in ${files[@]}; do
    sed -i 's|'"${search_term}"'|'"${replacement}"'|g' "${file}"
  done
  
  # SEARCH/REPLACE FOLDER NAMES
  folders=`find -name "*${search_term}*"`
  for folder in ${folders[@]}; do
  	new_folder=`echo "${folder}" | sed "s|${search_term}|${replacement}|g"`
    mv "${folder}" "${new_folder}"
  done

  popd > /dev/null

  printf 'Complete\n'
}

resolve_baseline_artifact
create_overlay_project
customize_modules
