#!/bin/bash

#Script to manage a Spring Boot application running an embedded container.
#The manage options are start, stop, restart, status

#Script parameters
ACTION=$1
PORT_PARAMETER=$2

#Script variables
JARFile="trips-api.jar"
PIDFile="trips-api-app.pid"
HOST_NAME=$(hostname)
JMX_OPTIONS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=1099 \
             -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false \
             -Djava.rmi.server.hostname=$HOST_NAME"
JVM_OPTIONS="-Xmx2g -Djava.security.egd=file:/dev/./urandom $JMX_OPTIONS"
SPRING_OPTIONS=""
PORT_NUMBER=8080
SPRING_PORT_OPTION="--server.port="

 
function check_if_pid_file_exists {
    if [ ! -f $PIDFile ]
    then
 echo "PID file not found: $PIDFile"
        exit 1
    fi
} 
 
function check_if_process_is_running {
 if ps -p $(print_process) > /dev/null
 then
     return 0
 else
     return 1
 fi
}
 
function print_process {
    echo $(<"$PIDFile")
}
 
case "$ACTION" in
  status)
    check_if_pid_file_exists
    if check_if_process_is_running
    then
      echo $(print_process)" is running"
    else
      echo "Process not running: $(print_process)"
    fi
    ;;
    
  stop)
    check_if_pid_file_exists
    if ! check_if_process_is_running
    then
      echo "Process $(print_process) already stopped"
      exit 0
    fi
    
    PROCESS_ID=$(print_process);
    
    kill -TERM $(print_process)
    echo -ne "Waiting for process to stop"
    NOT_KILLED=1
    for i in {1..20}; do
      if ps -p $PROCESS_ID > /dev/null 
      then
        echo -ne "."
        sleep 1
      else
        NOT_KILLED=0
      fi
    done
    echo
    if [ $NOT_KILLED = 1 ]
    then
      echo "Cannot kill process $(print_process)"
      exit 1
    fi
    echo "Process stopped"
    ;;
    
  start)
    if [ -f $PIDFile ] && check_if_process_is_running
    then
      echo "Process $(print_process) already running"
      exit 1
    fi
    
    if [ $PORT_PARAMETER ]
    then
      PARAMETER_NAME=$(echo "$PORT_PARAMETER" | awk -F= '{ print $1 }')
      if [ $PARAMETER_NAME = "port" ]
      then
      	PORT_NUMBER=$(echo "$PORT_PARAMETER" | awk -F= '{ print $2 }')
      else
      	echo "Parameter $PARAMETER_NAME not recognized. The second parameter must be 'port'"
      fi
    fi
    
    nohup java $JVM_OPTIONS -jar $JARFile $SPRING_OPTIONS $SPRING_PORT_OPTION$PORT_NUMBER> trips-api.out 2>&1 &
    echo "Process started on port $PORT_NUMBER"
    ;;

  *)
    echo "Usage:  $0 {start|stop|status}"
    echo "Start:  $0 start port=[portnumber]"
    echo "Stop:   $0 stop"
    echo "Status: $0 status"
    exit 1
esac
 
exit 0