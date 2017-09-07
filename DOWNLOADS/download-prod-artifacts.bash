#!/bin/bash

VERSION='3.41.0-SNAPSHOT'
ENV='prod'

artifacts=( 
  "com.networkfleet:api-server-${ENV}:${VERSION}:war"
  "com.networkfleet:api-management-${ENV}:${VERSION}:war"
  "com.networkfleet:oauth2-authorization-server-${ENV}:${VERSION}:war"
  "com.networkfleet:dataconnect-${ENV}:${VERSION}:war"
  "com.networkfleet.eda:eda-jjk-${ENV}:${VERSION}:war"
  "com.networkfleet:arch-${ENV}:${VERSION}:war"


);



for artifact in ${artifacts[@]}; do
  mvn -P repos -U org.apache.maven.plugins:maven-dependency-plugin:2.8:copy -Dartifact="${artifact}" -Dmdep.stripVersion=false -DoutputDirectory=.
done
