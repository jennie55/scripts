#!/bin/bash

source projects_3.46.list

for F in ${PROJECTS[@] }
do
   echo $F
   svn del http://144.70.182.112/ted3/${F}/branches/REL_3.47   -m "CC"
done 
