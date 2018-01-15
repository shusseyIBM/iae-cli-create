
# Function that stops the specified Ambari managed service
function ambariServiceStateChange(){

targetState = ""

  if [ $2 == "START" ]
  then
   targetState="STARTED"
   
  fi
  
  if [ $2 == "STOP" ]
  then
   targetState="INSTALLED"
  fi

  echo "Requesting $1 to $2"
  curl -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d  \
    '{"RequestInfo": {"context": "Stop '"$1"' via REST"}, "ServiceInfo": {"state":"'$targetState'"}}' \
    https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services/$1

  echo "Waiting for $1 to change to $targetState state"
  waitforservicechange $1 $targetState
  echo "Finished waiting for $1"

}

# Function that waits for the specified service to reach the specified state
function waitforservicechange(){
  targetService=$1 # Which service name are we monitoring the state of
  targetState=$2 # The target state of the service we are monitoring
  responseStatusProperty="state" # The property name in the service response that shows its status
  propertyValueElement="1" # For multi value properties, this is the element number we want

  echo "Target service state = $targetState"

  curlCommand="curl -s -u $AMBARI_USER:$AMBARI_PASSWORD https://{$AMBARI_HOST:$AMBARI_PORT}/api/v1/clusters/$CLUSTER_NAME/services/$targetService"
  
  finished=0
  while [ $finished -ne 1 ]
  do
    
    str=$($curlCommand | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$responseStatusProperty'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${propertyValueElement}p )

    echo "Sevice Status = $str"
    
    if [ $str == "$targetState" ] 
    then
      finished=1
    fi

    if [ $str == "" ] # if we dont get a value back, the service status inquiry isnt working
    then
      echo "Failed to get service state"
      finished=1
    fi

    sleep 3
  done
}


AMBARI_USER="clsadmin"
AMBARI_PASSWORD="W7Xi3kH9tBx5"
AMBARI_HOST="chs-zdn-156-mn001.bi.services.us-south.bluemix.net"
AMBARI_PORT="9443"
CLUSTER_NAME="AnalyticsEngine"


# wait "HIVE" "INSTALLED"

# stopWait "HIVE"


# sleep 5

# stopWait "HIVE"
ambariServiceStateChange "HIVE" "STOP"

sleep 10 # Sometimes if you start again too quickly after a stop, it wont work. This sleep is a workaround.

# startWait "HIVE"
ambariServiceStateChange "HIVE" "START"

# newwait HIVE started
