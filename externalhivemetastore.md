# Using a Compose MySQL instance for an IAE cluster Hive Metastore

Formal documentation for this topic can be found [here](https://console.bluemix.net/docs/services/AnalyticsEngine/working-with-hive.html#working-with-hive) 

As with other customizations in this tutorial there are two elements. The cluster configuration json and the bootstrap script. To ensure that the bootstrap does not need to be modified for each use, I have parameterized the MySQL database connection parameters. This moved the specification of those values to the json which, when used, will be local to the user running the command line. This makes changes simpler and more manageable.


# [cluster-custom-mysql.json](./cluster-custom-mysql.json)

The configuration parameters json is similar to the others we have used. 

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

The only changes being the script_path pointing to the url addressable location of the new customization script that will be run once your cluster has been created and the addition of the script_params entry with 5 properties. The bootstrap script will assign these properties to the following variables.

```
DB_USER_NAME=$1
DB_PWD=$2
DB_NAME=$3
DB_CXN_URL_HOST=$4
DB_CXN_URL_PORT=$5
```

These values are easy to discover from the IBM Cloud console for your MySQL instance. From the Manage view of Compose MySQL the first entry in the Connection Strings HTTPS secton gives you all the neccesary elements.

```
e.g. mysql://admin:ZCBWXXXXXXMJET@sl-us-south-1-portal.13.dblayer.com:32023/compose
```

becomes

```
"script_params": ["admin", "ZCBWXXXXXXMJET", "compose", "sl-us-south-1-portal.13.dblayer.com", "32023"]
```

You will notice, however that in the full example above, the third parameter is `hive` rather than `compose`. 

When you create a Compose MySQL instance, the compose schema is created for you. It is a good idea, however, to create a fresh schema in the instance for Hive use. You could also use the MySQL instance for more than one cluster but with different schemas if you wish. In that case you would alter the schema value for each unique cluster.
You do not need to do anything besides setting this value to create each schema in the instance. The bootstrap script includes an option `?createDatabaseIfNotExist=true` that will take care of this for you.

So if you use this recommendation your parameters will look like this

```
"script_params": ["admin", "ZCBWXXXXXXMJET", "compose", "sl-us-south-1-portal.13.dblayer.com", "32023"]
```

# [bootstrap-mysql.sh](./bootstrap-mysql.sh)

To make the change to the cluster after it has been created, you have to go through Ambari. The first step is to change the neccesary parameters. Then you stop and start the services. 

Since we are setting these parameters using Ambari commands, it is not critical which node management of the cluster they run on but they should only run on one. For our purposes we have selected them to run on "management-slave2" with the statement `if [ "x$NODE_TYPE" == "xmanagement-slave2" ]` . The simple reason for this is that, if you use the ssh url from the cluster credentials to connect, this is the node you connect to. Therefore the /var/log on this node will contain the bootstrap script log if you need to debug it.

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

The start and stop commands are separated in this script. There is a 100 second wait after initiating the stop and a 700 second wait after initiating start. This is helpful to know if you are monitoring the cluster creation through the IBM Cloud console. Once the baseline cluster creation has finished (10 to 20 minutes ) you will be able to open it from your services list. However in the Manage page you will see the status in the Customizing state for approximately 14 more minutes due to these wait times. Once complete, the cluster should move to an Active state. 

If this wait time presents operational challenges, it may be possible throguh additional scripting to more actively monitor the stop and start progress and return as soon as they are complete. 