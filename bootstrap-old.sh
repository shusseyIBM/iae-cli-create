# FIXME:
# The ambari service may not be ready after running this script - how do we check (and wait) until ambari has finished?

echo "NODE_TYPE: $NODE_TYPE" 

set

set -e # abort on error
set -u # abort on undefined variables

if [ "x$NODE_TYPE" != "xmaster-management" ]
then
    DESTDIR=/home/wce/clsadmin/spark-avro
    mkdir ${DESTDIR}
    
    TMPDIR=$(mktemp -d)
    
    if [ ! -d apache-ivy-2.4.0 ]; then
       wget -q -c http://apache.mirror.anlx.net//ant/ivy/2.4.0/apache-ivy-2.4.0-bin.zip
       unzip -q apache-ivy-2.4.0-bin.zip
    fi
    
cat << EOF > ivysettings.xml
<ivysettings>
    <settings defaultResolver="chain"/>
    <caches  defaultCacheDir="${TMPDIR}" />
    <resolvers>
        <chain name="chain">
            <ibiblio name="central" m2compatible="true"/>
        </chain>
    </resolvers>
</ivysettings>
EOF
    
    java -jar apache-ivy-2.4.0/ivy-2.4.0.jar -settings ivysettings.xml -dependency com.databricks spark-avro_2.11 4.0.0
    
    find $TMPDIR -name *.jar | xargs cp -t $DESTDIR
    rm -rf $TMPDIR
else
    # The configs.py script on the cluster had a bug that wouldn't allow it to save a content field
    echo 'Downloading configs.py ambari script'
    curl https://raw.githubusercontent.com/apache/ambari/9e93c476ddd8d4397f550062fd1645ac5422ed2e/ambari-server/src/main/resources/scripts/configs.py > configs.py

    echo 'Getting the latest spark2-env configuration'
    # grab the latest spark2-env configuration file
    ./configs.py -u ${AMBARI_USER} -p ${AMBARI_PASSWORD} -n ${CLUSTER_NAME} -s https --port ${AMBARI_PORT} -l ${AMBARI_HOST} -a get -c spark2-env -f spark2-env-content.json

    echo 'Current spark2-env configuartion:'
    cat spark2-env-content.json

    # append the spark-avro folder to the SPARK_DIST_CLASSPATH
    echo 'export SPARK_DIST_CLASSPATH=$SPARK_DIST_CLASSPATH:/home/clsadmin/spark-avro/*' >> spark2-env-content.json

    # save the changes back 
    ./configs.py -u ${AMBARI_USER} -p ${AMBARI_PASSWORD} -n ${CLUSTER_NAME} -s https --port ${AMBARI_PORT} -l ${AMBARI_HOST} -a set -c spark2-env -f spark2-env-content.json

    echo 'Uploaded new spark2-env configuartion:'
    cat spark2-env-content.json

    echo "stop and Start Services"
    curl -k -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d '{"RequestInfo": {"context": "Stop All Services via REST"}, "ServiceInfo": {"state":"INSTALLED"}}' https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services
    sleep 200

    curl -k -v --user $AMBARI_USER:$AMBARI_PASSWORD -H "X-Requested-By: ambari" -i -X PUT -d '{"RequestInfo": {"context": "Start All Services via REST"}, "ServiceInfo":{"state":"STARTED"}}' https://$AMBARI_HOST:$AMBARI_PORT/api/v1/clusters/$CLUSTER_NAME/services
    sleep 200

    echo 'Retrieving script to verify ambari service status'
    curl https://git.ng.bluemix.net/chris.snow/iae-spark-package-customization-example/raw/master/bootstrap/verify_ambari_service_status.py > verify_ambari_service_status.py

    echo 'Running script to verify ambari service status'
    # the script below will return 0 if all services are started
    # it will retry for 30 minutes
    python verify_ambari_service_status.py

    echo 'Ambari services have been restarted successfully'

fi