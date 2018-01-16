# Using a Compose MySQL instance for an IAE cluster Hive Metastore

The purpose of this customization is to create a new cluster and immediately after creation to change the HIVE Metastore configuration from using a local Derby database to connect to an IBM Cloud hosted Compose MySQL instance. 

To complete this change, we will be using Ambari commands to make the configuration changes, to stop and start services and to monitor the progress of those restart actions. 

Formal documentation for this topic can be found [here](https://console.bluemix.net/docs/services/AnalyticsEngine/working-with-hive.html#working-with-hive) 

As with other customizations in this tutorial there are two elements. The cluster configuration json and the bootstrap script. 

To ensure that the bootstrap script does not need to be modified for each use, I have parameterized the MySQL database connection parameters in the json `script_params` property. This makes changes to the parameters simpler since the file is local to wherever you run the cluster creation command. It has the added benefit that credentials dont get stored in the URL addressable boostrap script file that could present security concerns.


# [cluster-custom-mysql.json](./cluster-custom-mysql.json)

```
{
    "num_compute_nodes": 1,
    "hardware_config": "default",
    "software_package": "ae-1.0-hadoop-spark",
    "customization": [{
        "name": "action1",
        "type": "bootstrap",
        "script": {
            "source_type": "https",
            "source_props": {
                "username": "",
                "password": ""
            },
            "script_path": "https://raw.githubusercontent.com/shusseyIBM/iae-cli-create/master/bootstrap-mysql.sh"
        },
        "script_params": ["admin", "ZCBWXXXXXXMJET", "hive", "sl-us-south-1-portal.13.dblayer.com", "32023"]
    }]
}
```

The script_path points to the url addressable location of the customization script (currently in this github project) that will be run once your cluster has been created. The script_params property has 5 values. The bootstrap script will assign these properties to the following variables.

```
DB_USER_NAME=$1
DB_PWD=$2
DB_NAME=$3
DB_CXN_URL_HOST=$4
DB_CXN_URL_PORT=$5
```

These values are easy to discover from the IBM Cloud console for your MySQL instance. From the Manage view of Compose MySQL the first entry in the Connection Strings HTTPS secton gives you all the neccesary elements. For example: 

```
mysql://admin:ZCBWXXXXXXMJET@sl-us-south-1-portal.13.dblayer.com:32023/compose
```

becomes

```
"script_params": ["admin", "ZCBWXXXXXXMJET", "compose", "sl-us-south-1-portal.13.dblayer.com", "32023"]
```

You will notice, however that in the full example above, the third parameter is `hive` rather than `compose`. For MySQL this value is both the database name and schema name. MySQL uses the terms interchangeably.  

When you create a new Compose MySQL instance, the `compose` schema is created for you. You could have Hive use this schema to create its tables but it is a good practice to create a fresh schema in the instance for Hive use. You could also use one MySQL instance for more than one cluster but with different schema names to separate the data if you wish. In that case you would alter the schema name value for each unique cluster you create.

You do not need to do anything besides setting this value correctly to create each schema. The bootstrap script includes an option `?createDatabaseIfNotExist=true` that will take care of this for you.

So if you use this recommendation your parameters will look like this

```
"script_params": ["admin", "ZCBWXXXXXXMJET", "hive", "sl-us-south-1-portal.13.dblayer.com", "32023"]
```

# [bootstrap-mysql.sh](./bootstrap-mysql.sh)

To make the change to the cluster after it has been created, you have to go through Ambari. The first step is to change the neccesary parameters. Then you stop and start the services. 

Since we are setting these parameters using Ambari commands, it is not critical which node of the cluster they run on but they should only run on one node not all of them. For our purposes we have selected them to run on "management-slave2" with the statement `if [ "x$NODE_TYPE" == "xmanagement-slave2" ]` . The simple reason for this is that, if you use the ssh url from the cluster credentials to connect, this is the node you connect to. Therefore the /var/log on this node will contain the bootstrap script log if you need to debug it.

## The Ambari parameters

The following parameters are set using /var/lib/ambari-server/resources/scripts/configs.sh

| Parameter | Value |
| --------- | ----- |
| javax.jdo.option.ConnectionUserName | The MySQL user name |
| javax.jdo.option.ConnectionPassword | The MySQL password |
| ambari.hive.db.schema.name | For MySQL schema name and database are synonymous |
| javax.jdo.option.ConnectionURL | The URL Hive uses to connect |

The ConnectionURL is constructed from the 5 script_params and will look similar to `jdbc:mysql://sl-us-south-1-portal.13.dblayer.com:32023/hive?createDatabaseIfNotExist=true`

## The service restart

To ensure a clean restart and adoption of the changed configuration the script uses helper function `ambariServiceStateChange` to request service stops and starts in the right order and monitors progress before continuing. The sub function waitforservicechange polls the service state every 3 seconds to ensure the target state has been reached.

```
echo "******* Restart HIVE Services"

ambariServiceStateChange "OOZIE" "STOP"
ambariServiceStateChange "HIVE" "STOP"
    
sleep 60 # Sometimes if you start again too quickly after a stop, it wont work. This sleep is a workaround.
    
ambariServiceStateChange "HIVE" "START"
ambariServiceStateChange "OOZIE" "START"
```

If your cluster stays in the Customizing state, you will have to connect to the slave2 node using ssh from the cluster credentials and look at the log file. The file name is a combination of the host name of the node and the process number of the customization script. e.g.

```
/var/log/chs-pxv-079-mn003.bi.services.us-south.bluemix.net_12756.log
```

## Creating the cluster

Now we have the configuration file and the script it references we construct the `bx cf create-service IBMAnalyticsEngine ...` command

If we use the `standard-hourly` plan, name the cluster `iae-custom-cluster-mysql` and choose configuration `cluster-custom-mysql.json` the complete command would be :-

```
bx cf create-service IBMAnalyticsEngine standard-hourly iae-custom-cluster-mysql -c ./cluster-custom-mysql.json
```

Refer to the Avro example for methods to monitor the creation progress. 

## Verifying Hive metastore customization worked

The simplest way to check if all is good is to log in to the Ambari console. Go to the IBM Cloud console to Manage your instance and launch Ambari. Once you connect you will see the health status of the cluster and any alerts requiring your attention. 

To use HIVE and through it, the HIVE Metastore, mouse over the 3x3 matrix icon in the top right of the page next to the clsadmin user name. Select either Hive View or Hive View 2.0 to excercise Hive.