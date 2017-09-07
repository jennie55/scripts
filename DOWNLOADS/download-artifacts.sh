#!/bin/bash


usage_and_exit()
{
    echo "One parameter is needed, version.  (e.g.: download-artifacts.sh 3.42.0-SNAPSHOT)"
    exit 2
}


VERSION=$1

if [ -z "$VERSION" ] ; then
    usage_and_exit
fi

artifacts=( 
  "com.networkfleet:media:${VERSION}:war"
  "com.networkfleet:allstate-ws:${VERSION}:war"
  "com.networkfleet:api-server:${VERSION}:war"
  "com.networkfleet:api-management:${VERSION}:war"
  "com.networkfleet:oauth2-authorization-server:${VERSION}:war"
  "com.networkfleet:dataconnect:${VERSION}:war"
  "com.networkfleet.eda:eda-jjk:${VERSION}:war"
  "com.networkfleet.eda:eda-tax:${VERSION}:war"
  "com.networkfleet:arch:${VERSION}:war"
  "com.networkfleet:ssp:${VERSION}:war"
  "com.networkfleet:nwf-portal:${VERSION}:war"
  "com.networkfleet:nwf-portal:${VERSION}:war:prod"
  "com.networkfleet:nwf-portal:${VERSION}:war:preprod"
  "com.networkfleet.eda:message-processor:${VERSION}:war"
  "com.networkfleet.eda:alertengine:${VERSION}:war"
  "com.networkfleet.eda:eda-console-webapp:${VERSION}:war"
  "com.networkfleet:cache-server:${VERSION}:tar:linux"
  "com.networkfleet:cache-server:${VERSION}:tar:linux"
  "com.networkfleet.rungps:rungps-web:${VERSION}:war"
);


for artifact in ${artifacts[@]}; do
  mvn -U org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact="${artifact}" -Dmdep.stripVersion=false -DoutputDirectory=.
done

chmod 444 *.war *.tar

