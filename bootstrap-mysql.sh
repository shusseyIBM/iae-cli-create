# Helper functions for service restart

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

# End of helper functions


# Start of main code

# Capture parameters passed in to the script
# Assumes IAE customization JSON includes "script_params": ["DB_USER_NAME", "DB_PWD", "DB_NAME", "DB_CXN_URL_HOST" , "DB_CXN_URL_PORT"]

DB_USER_NAME=$1
DB_PWD=$2
DB_NAME=$3
DB_CXN_URL_HOST=$4
DB_CXN_URL_PORT=$5
DB_CXN_URL="jdbc:mysql://"$DB_CXN_URL_HOST":"$DB_CXN_URL_PORT"/$DB_NAME?createDatabaseIfNotExist=true"

# Uncomment to debug if needed
# echo "MySQL User: $DB_USER_NAME"
# echo "MySQL DB Name: $DB_NAME"
# echo "MySQL HOST: $DB_CXN_URL_HOST"
# echo "MySQL PORT: $DB_CXN_URL_PORT"
# echo "MySQL URL: $DB_CXN_URL"
# echo "NODE_TYPE: $NODE_TYPE"

# NODE_TYPE options are data, management-slave1, or manangement-slave2
if [ "x$NODE_TYPE" == "xmanagement-slave2" ]
then
    
    echo "******* Updating settings to point to external database"

    echo "javax.jdo.option.ConnectionURL = $DB_CXN_URL"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionURL" $DB_CXN_URL

    echo "javax.jdo.option.ConnectionUserName = $DB_USER_NAME"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionUserName" $DB_USER_NAME

    # echo "javax.jdo.option.ConnectionPassword = $DB_PWD"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionPassword" $DB_PWD

    echo "ambari.hive.db.schema.name = $DB_NAME"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST $CLUSTER_NAME hive-site "ambari.hive.db.schema.name" $DB_NAME

    echo "******* Restart HIVE Services"
    ambariServiceStateChange "HIVE" "STOP"
    sleep 10 # Sometimes if you start again too quickly after a stop, it wont work. This sleep is a workaround.
    ambariServiceStateChange "HIVE" "START"
    
    echo "******* Completed customization"
fi