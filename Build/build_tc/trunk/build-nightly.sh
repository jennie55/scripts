#!/bin/bash

PYTHON=/usr/bin/python
CFG_FILE=/usr/local/teamcity-data/automation/tc/build-nightly.xml
PATH=/usr/lib64/qt-3.3/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/local/teamcity-data/bin

cd /usr/local/teamcity-data/automation/tc
$PYTHON /usr/local/teamcity-data/automation/tc/build_tc.py $CFG_FILE




