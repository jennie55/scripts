#!/bin/bash

VERSION=3.44.0.44794

chmod a+w *${VERSION}*

scp message-processor-${VERSION}.war eda@eda1-pre:/tmp
scp message-processor-${VERSION}.war eda@eda1-pre:/tmp
scp message-processor-${VERSION}.war eda@eda2-pre:/tmp
scp alertengine-${VERSION}.war eda@eda2-pre:/tmp
scp alertengine-${VERSION}.war eda@eda1-pre:/tmp
scp alertengine-${VERSION}.war eda@eda-admin-pre:/tmp
scp message-processor-${VERSION}.war eda@eda-admin-pre:/tmp
scp eda-console-webapp-${VERSION}.war eda@eda-admin-pre:/tmp
scp eda-jjk-${VERSION}.war eda@eda-admin-pre:/tmp
scp eda-tax-${VERSION}.war eda@eda-admin-pre:/tmp
scp dataconnect-${VERSION}.war datapipe@dc1-pre:/tmp


scp nwf-portal-${VERSION}.war bea@app1-pre:/tmp
scp nwf-portal-${VERSION}.war bea@rep1-pre:/tmp
scp ssp-${VERSION}.war  tomcat@app1-pre:/tmp
scp allstate-ws-${VERSION}.war  jimperialsosa@app1-pre:/tmp
scp api*  jimperialsosa@app1-pre:/tmp
scp oauth2-authorization-server-${VERSION}.war  jimperialsosa@app1-pre:/tmp
scp arch-${VERSION}.war jimperialsosa@arch1-pre:/tmp
scp media-REL_3.43-43491-preprod_profile.zip jimperialsosa@apache1-pre:/tmp

