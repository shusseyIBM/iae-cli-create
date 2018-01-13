




# Helper functions for service restart

function stopWait(){
  curl -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d  \
    '{"RequestInfo": {"context": "Stop '"$1"' via REST"}, "ServiceInfo": {"state":"INSTALLED"}}' \
    https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services/$1
  wait $1 "INSTALLED"
}

function startWait(){
  curl -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d  \
    '{"RequestInfo": {"context" :"Start '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' \
    https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services/$1
  wait $1 "STARTED"
}


function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    str=$(curl -s -u $AMBARI_USER:$AMBARI_PASSWORD http://{$AMBARI_HOST:$AMBARI_PORT}/api/v1/clusters/$CLUSTER_NAME/services/$1)
    if [[ $str == *"$2"* ]] || [[ $str == *"Service not found"* ]] 
    then
      finished=1
    fi
    sleep 3
  done
}

# Assumes "script_params": ["DB_USER_NAME", "DB_PWD", "DB_NAME", "DB_CXN_URL_HOST" , "DB_CXN_URL_PORT"]

DB_USER_NAME=$1
DB_PWD=$2
DB_NAME=$3
DB_CXN_URL_HOST=$4
DB_CXN_URL_PORT=$5

DB_CXN_URL="jdbc:mysql://"$DB_CXN_URL_HOST":"$DB_CXN_URL_PORT"/$DB_NAME?createDatabaseIfNotExist=true"

echo "MySQL User: $DB_USER_NAME"
echo "MySQL DB Name: $DB_NAME"
echo "MySQL HOST: $DB_CXN_URL_HOST"
echo "MySQL PORT: $DB_CXN_URL_PORT"
echo "MySQL URL: $DB_CXN_URL"

echo "NODE_TYPE: $NODE_TYPE"

# NODE_TYPE options are data, management-slave1, or manangement-slave2

# if [ "x$NODE_TYPE" == "xmanagement" ]
if [ "x$NODE_TYPE" == "xmanagement-slave2" ]
then

    echo "Node type is xmanagement-slave2 hence updating ambari properties"
    
    echo "javax.jdo.option.ConnectionURL = $DB_CXN_URL"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionURL" $DB_CXN_URL

    echo "javax.jdo.option.ConnectionUserName = $DB_USER_NAME"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionUserName" $DB_USER_NAME

    # echo "javax.jdo.option.ConnectionPassword = $DB_PWD"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST  $CLUSTER_NAME hive-site "javax.jdo.option.ConnectionPassword" $DB_PWD

    echo "ambari.hive.db.schema.name = $DB_NAME"
    /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_USER -p $AMBARI_PASSWORD -port $AMBARI_PORT -s set $AMBARI_HOST $CLUSTER_NAME hive-site "ambari.hive.db.schema.name" $DB_NAME

    echo "Stop Services"
    stopWait HIVE 

    # curl -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d '{"RequestInfo": {"context": "Stop All Services via REST"}, "ServiceInfo": {"state":"INSTALLED"}}' https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services
    # sleep 100

    echo "Start Services"

    startWait HIVE

    #curl -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d '{"RequestInfo": {"context": "Start All Services via REST"}, "ServiceInfo": {"state":"STARTED"}}' https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services
    # sleep 700

    echo "Completed customization"
fi