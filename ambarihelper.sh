# Helper functions for service restart

# Function that stops the specified Ambari managed service
function ambariServiceStateChange(){

targetState=""

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

  curlCommand="curl -v -u $AMBARI_USER:$AMBARI_PASSWORD https://{$AMBARI_HOST:$AMBARI_PORT}/api/v1/clusters/$CLUSTER_NAME/services/$targetService"
  
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


function stopAllServices(){

  response=$(curl -s --user $AMBARI_USER:$AMBARI_PASSWORD -X PUT \
   https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services \
  -H 'Cache-Control: no-cache' \
  -H 'X-Requested-By: ambari' \
  -d '{
	"RequestInfo": {
		"context": "Stop All Services via REST"
		},
	"ServiceInfo": {
		"state":"INSTALLED"
		}
}'
)

# echo "stopAllServices: $?"
}


function startAllServices(){

  response=$(curl -s --user $AMBARI_USER:$AMBARI_PASSWORD -X PUT \
   https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services \
  -H 'Cache-Control: no-cache' \
  -H 'X-Requested-By: ambari' \
  -d '{
	"RequestInfo": {
		"context": "Start All Services via REST"
		},
	"ServiceInfo": {
		"state":"STARTED"
		}
}'
)

# echo "startAllServices: $?"

}

function requestStatus(){

  response=$(curl -s --user $AMBARI_USER:$AMBARI_PASSWORD -X GET \
  https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/requests/$1?fields=Requests/request_status \
  -H 'Cache-Control: no-cache'
  )

 #  echo "requestStatus: $?"
}

function statusAllServices(){

  response=$(curl --user $AMBARI_USER:$AMBARI_PASSWORD -X GET \
  https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services?fields=ServiceInfo/state \
  -H 'Cache-Control: no-cache' )

echo $response
}

extractJSONPropertvalue(){
  propertyValueElement="1"
  
  extractedJSONPropertvalue=$(echo $response | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$1'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${propertyValueElement}p )
  echo "$1 = $extractedJSONPropertvalue"
}


# End of helper functions





function ambariStopAll(){

# Since there are a few ways for this to fail that might not be trapped, the default status is set to FAILED
ambariStopAllStatus="FAILED"


echo "Stopping all services"
stopAllServices

# Check if the action was accepted
extractJSONPropertvalue "status"
stopStatus=$extractedJSONPropertvalue

# If it was accepted get the ID of the async request
extractJSONPropertvalue "id"
requestId="$extractedJSONPropertvalue"

finished=0
echo "Checking status of request: $requestId"
  while [ $finished -ne 1 ]
  do
    
  # Using the ID ge the request details
  requestStatus $requestId

  # Extract the status from the request details. This is what we would monitor until done. Loop requestStatus while this is "IN_PROGRESS"
  extractJSONPropertvalue "request_status"
  requestCompleted="$extractedJSONPropertvalue"

    # Possible values COMPLETED, FAILED, PENDING(IF more than one start is sent)
    if [ $requestCompleted = "COMPLETED" ] 
    then
      echo "Completed"
      ambariStopAllStatus="COMPLETED"
      finished=1
    fi

    if [ $requestCompleted = "FAILED" ] 
    then
      echo "Failed"
      finished=1
    fi


    sleep 10
  done

}

function ambariStartAll(){

# Since there are a few ways for this to fail that might not be trapped, the default status is set to FAILED
ambariStartAllStatus="FAILED"

echo "Starting all services"
startAllServices

# echo "Response: $response"

# Check if the action was accepted
extractJSONPropertvalue "status"
stopStatus=$extractedJSONPropertvalue

# If it was accepted get the ID of the async request
extractJSONPropertvalue "id"
requestId="$extractedJSONPropertvalue"

finished=0
echo "Checking status of request: $requestId"
  while [ $finished -ne 1 ]
  do
    
  # Using the ID get the request details
  requestStatus $requestId

  # Extract the status from the request details. This is what we would monitor until done. Loop requestStatus while this is "IN_PROGRESS"
  extractJSONPropertvalue "request_status"
  requestCompleted="$extractedJSONPropertvalue"
  
    # Possible values COMPLETED, FAILED, PENDING(IF more than one start is sent)
    if [ $requestCompleted = "COMPLETED" ] 
    then
      echo "Completed"
      ambariStartAllStatus="COMPLETED"
      finished=1
    fi

    if [ $requestCompleted = "FAILED" ] 
    then
      echo "Failed"
      finished=1
    fi


    sleep 10
  done

}

AMBARI_USER="clsadmin"
AMBARI_PASSWORD="mAH3OTgd3c93"
AMBARI_HOST="chs-qxu-631-mn001.bi.services.us-south.bluemix.net"
AMBARI_PORT="9443"
CLUSTER_NAME="AnalyticsEngine"

echo "ambariStopAll begin:"
ambariStopAll

if [ $ambariStopAllStatus = "FAILED" ] 
    then
    echo "Retry the stop a second due to a current bug"
    ambariStopAll
    fi

echo "ambariStopAll final status = $ambariStopAllStatus"

echo "ambariStartAll begin:"
ambariStartAll
echo "ambariStartAll final status = $ambariStartAllStatus"

# {
#  "href" : "https://chs-qxu-631-mn001.bi.services.us-south.bluemix.net:9443/api/v1/clusters/AnalyticsEngine/requests/44",
#  "Requests" : {
#    "cluster_name" : "AnalyticsEngine",
#    "id" : 44,
#    "request_status" : "FAILED"
#  }
# }

# Response when start or stop isnt accepted
# {
#  "status" : 400,
#  "message" : "java.lang.IllegalArgumentException: Invalid transition for servicecomponenthost, clusterName=AnalyticsEngine, clusterId=2, serviceName=HDFS, componentName=NAMENODE, hostname=chs-qxu-631-mn002.bi.services.us-south.bluemix.net, currentState=STARTING, newDesiredState=INSTALLED"
# }

 
# Successful start response
# Response: {
#  "href" : "https://chs-qxu-631-mn001.bi.services.us-south.bluemix.net:9443/api/v1/clusters/AnalyticsEngine/requests/33",
#  "Requests" : {
#    "id" : 33,
#    "status" : "Accepted"
#  }
# }