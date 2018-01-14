



function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    echo "curl -s -u $AMBARI_USER:$AMBARI_PASSWORD https://{$AMBARI_HOST:$AMBARI_PORT}/api/v1/clusters/$CLUSTER_NAME/services/$1"
    str=$(curl -s -u $AMBARI_USER:$AMBARI_PASSWORD https://{$AMBARI_HOST:$AMBARI_PORT}/api/v1/clusters/$CLUSTER_NAME/services/$1)
    echo "STR = $str"
    if [[ $str == *"$2"* ]] || [[ $str == *"Service not found"* ]] 
    then
      finished=1
    fi
    echo "sleep"
    sleep 3
  done
}

AMBARI_USER="clsadmin"
AMBARI_PASSWORD="u68Mma53GCKW"
AMBARI_HOST="chs-idu-866-mn001.bi.services.us-south.bluemix.net"
AMBARI_PORT="9443"
CLUSTER_NAME="AnalyticsEngine"

echo "Start wait"

wait "HIVE" "INSTALLED"

echo "End wait"