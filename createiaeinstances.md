# Create IAE instances from the command line

This tutorial is in two steps to help you understand and troubleshoot effectively. The first is to initiate and verify the creation of an uncustomized IAE instance. Then you will use an alternate configuration to create an instance with additional capabilities.

## Create an uncustomized IAE instance

As part of instance creation you can include the cluster configuration parameters inline in the create command if you wish however to promote reusabiliy and consistency we are using the option to use a configuration file with the cluster configuration in it that could be reused across different creation scenarios. 

For the uncustomized IAE instance the configutation is [cluster-simple.json](cluster-simple.json) and just deploys a single spark compute node.

```
{
    "num_compute_nodes": 1,
    "hardware_config": "default",
    "software_package": "ae-1.0-spark"
}
```

Assuming you have already performed [Preparing to use the IBM Cloud CLI](ibmcloudlogin.md) initiating creation a cluster is a single command `bx cf create-service IBMAnalyticsEngine ...`

There are three additional parameters for this command that can change depending on your needs.

1. Billing plan - The plan the cluster will use ( lite, standard-hourly or standard-monthly are the current options )
2. Cluster name - The name of the new cluster being created
3. Configuration - using option `-c` define which configuration file is being used for the service ( cluster-simple.json or cluster-custom.json in our case )

If we use the `lite` plan, name the cluster `iae-simple-cluster` and choose the configuration file `cluster-simple.json` the complete command would be

```
bx cf create-service IBMAnalyticsEngine lite iae-simple-cluster -c ./cluster-simple.json
```

Response:

```
Invoking 'cf create-service IBMAnalyticsEngine lite iae-simple-cluster -c ./cluster-simple.json'...

Creating service instance iae-simple-cluster in org jdoe123@us.ibm.com / space dev as jdoe123@us.ibm.com...
OK

Create in progress. Use 'cf services' or 'cf service iae-simple-cluster' to check operation status.
```

## Monitor instance creation progress

As mentioned in the command response, the cluster may take some time to initialize. If you use the provided command to check the status of your specific cluster the response will initially be similar to the following

```
bx cf service iae-simple-cluster
```
Initial response:-

```
Invoking 'cf service iae-simple-cluster'...


Service instance: iae-simple-cluster
Service: IBMAnalyticsEngine
Bound apps: 
Tags: 
Plan: lite
Description: Flexible framework to deploy Hadoop and Spark analytics applications.
Documentation url: https://console.bluemix.net/docs/services/AnalyticsEngine/index.html
Dashboard: https://ibmae-ui.mybluemix.net/analytics/engines/paygo/jumpout?apiKey=20171211234529437-UaoXMqSUzmMO&instanceId=f05e3da0-8f20-4466-aa59-f4068e4e38ab

Last Operation
Status: create in progress
Message: 
Started: 2017-12-11T23:45:45Z
Updated: 2017-12-11T23:48:00Z 
```

When complete the "Status" will change to "create succeeded"

```
...
Last Operation
Status: create succeeded
Message: 
...
```

## Interacting with the instance

You can now use the Dashboard URL in the previous command response to open the dashboard. e.g. 

```
https://ibmae-ui.mybluemix.net/analytics/engines/paygo/jumpout?apiKey=20171211234529437-UaoXMqSUzmMO&instanceId=f05e3da0-8f20-4466-aa59-f4068e4e38ab
```

From the dashboard you are able to get the username (clsadmin) and its password for your instance and launch the Ambari console to use those credentials if needed.

## Creating credentials for your cluster

To allow the use of the cluster by other clients and services of your choosing you will need the service credentials and URLs for your new instance. These can be created using the command `bx cf create-service-key ...` and retrieved using  `bx cf service-key iae-simple-cluster [key name]` to retrieve a specific key.


Create new credentails for the service usign this command. "Credentials1" is the name of your new credentials. You could use a name of your choosing. The `-c {}` is for optional parameters for the command which we have none.

```
bx cf create-service-key iae-simple-cluster Credentials1 -c {}
```

Response:

```
Invoking 'cf create-service-key iae-simple-cluster Credentials1 -c {}'...

Creating service key Credentials1 for service instance iae-simple-cluster as jdoe123@us.ibm.com...
OK

```

Retrieving the credentials by name is performed as follows. This gets you the username and password and all the endpoints for connecting to the cluster.

```
bx cf service-key iae-simple-cluster Credentials1
```

Response:

```
Invoking 'cf service-key iae-simple-cluster Credentials1'...

Getting key Credentials1 for service instance iae-simple-cluster as jdoe123@us.ibm.com...

{
 "cluster": {
  "cluster_id": "20171212-231742-501-LkJMPjVv",
  "password": "1Y0H4cvR3OeS",
  "service_endpoints": {
   "ambari_console": "https://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:9443",
   "livy": "https://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:8443/gateway/default/livy/v1/batches",
   "notebook_gateway": "https://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:8443/gateway/default/jkg/",
   "notebook_gateway_websocket": "wss://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:8443/gateway/default/jkgws/",
   "spark_history_server": "https://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:8443/gateway/default/sparkhistory",
   "ssh": "ssh clsadmin@chs-sqk-923-mn003.bi.services.us-south.bluemix.net",
   "webhdfs": "https://chs-sqk-923-mn001.bi.services.us-south.bluemix.net:8443/gateway/default/webhdfs/v1/"
  },
  "service_endpoints_ip": {
   "ambari_console": "https://169.60.139.3:9443",
   "livy": "https://169.60.139.3:8443/gateway/default/livy/v1/batches",
   "notebook_gateway": "https://169.60.139.3:8443/gateway/default/jkg/",
   "notebook_gateway_websocket": "wss://169.60.139.3:8443/gateway/default/jkgws/",
   "spark_history_server": "https://169.60.139.3:8443/gateway/default/sparkhistory",
   "ssh": "ssh clsadmin@169.60.139.3",
   "webhdfs": "https://169.60.139.3:8443/gateway/default/webhdfs/v1/"
  },
  "user": "clsadmin"
 },
 "cluster_management": {
  "api_url": "https://api.dataplatform.ibm.com/v2/analytics_engines/44400588-e403-49b6-a666-6202032cd3cd",
  "instance_id": "44400588-e403-49b6-a666-6202032cd3cd"
 }
}
```

## Deleting the instance when done

If the purpose of the instance has a time limit, especically since billing is on the basis of node hours for the standard plan, it is useful to know how to delete the instance via the CLI too. 

If you created credentials in the previous section, you will need to delete them before you can delete the cluster itself. e.g.

```
bx cf delete-service-key iae-simple-cluster Credentials1 -f
```

The `-f` option turns of the need to confirm the deletion so you can script it without prompts.

Now you have cleaned up, the cluster deletion command is simple. 

```
bx cf delete-service iae-simple-cluster -f

Invoking 'cf delete-service iae-simple-cluster -f'...

Deleting service iae-simple-cluster in org jdoe123@us.ibm.com / space dev as jdoe123@us.ibm.com...
OK
```

## Command summary

In summary, here are the commands that cover the full service lifecycle for our simple cluster

```
bx cf create-service IBMAnalyticsEngine lite iae-simple-cluster -c ./cluster-simple.json
bx cf service iae-simple-cluster
bx cf create-service-key iae-simple-cluster Credentials1 -c {}
bx cf service-key iae-simple-cluster Credentials1
bx cf delete-service-key iae-simple-cluster Credentials1 -f
bx cf delete-service iae-simple-cluster -f

```

## Create a customized IAE instance

The specific customization that we are applying in this example is to add [Avro](https://github.com/databricks/spark-avro) to our Spark cluster. This will be done using a [bootstrap.sh](./bootstrap.sh) script included in this project. When we execute the new cluster creation the bootstrap.sh script is executed on all nodes. If you take a look at the logic of bootstrap.sh you will see that although the Avro install runs on all nodes, the management node performs an additional services restart command. This ensures that the cluster adopts the new module correctly. It will, however, extend the cluster initialization time given that there are a couple of `sleep` commands to allow the restart to complete. 

NOTE: Although the `cf service` response will indicate "create succeeded", the customization is triggered after this point. From the dashboard you will see a status of "Customizing" while this is happening and when complete it will show "Active".

The configuration we are using for the custom instance creation is [cluster-custom.json](cluster-custom.json) which includes a link to a custom bootstrap.sh script. 

```
{
    "num_compute_nodes": 1,
    "hardware_config": "default",
    "software_package": "ae-1.0-spark",
    "customization": [{
        "name": "action1",
        "type": "bootstrap",
        "script": {
            "source_type": "https",
            "source_props": {
                "username": "",
                "password": ""
            },
            "script_path": "https://raw.githubusercontent.com/shusseyIBM/iae-cli-create/master/bootstrap.sh"
        },
        "script_params": []
    }]
}
```

Notice the customization "script" section points to a web location ( In the default case, to a file in this git project ). The script must be in a location the cluster nodes can access themselves as they start. You cannot store this file on your local machine. There are multiple options for where it can be stored described in the documentation section titled [Location of the customization script](https://console.bluemix.net/docs/services/AnalyticsEngine/customizing-cluster.html#customizing-a-cluster)

Now we have the configuration file and the script it references we construct the `bx cf create-service IBMAnalyticsEngine ...` command

If we use the `standard-hourly` plan, name the cluster `iae-custom-cluster` and choose configuration `cluster-custom.json` the complete command would be :-

```
bx cf create-service IBMAnalyticsEngine standard-hourly iae-custom-cluster -c ./cluster-custom.json
```

If you do not have access to an account that can be billed for services, you can revert to 'lite' for the plan.

## Did the customization work?

Monitor the creation of the cluster as before using `bx cf service iae-custom-cluster` . 

The custom bootstrap.sh will be executed AFTER the cluster creation succeeds. So depending on your customization execution time, you may have to wait some additional time before you can effectively use the cluster. The Dashboard will visaully show the status of "Customizing" while this is still pending.

Debugging your customization if needed requires additional steps. 

To monitor the customization jobs directly you can use the `curl` commands described [here](https://console.stage1.bluemix.net/docs/services/AnalyticsEngine/customizing-cluster.html#getting-cluster-status) . 

You can also see references to log files for the jobs in the documentation. As a shortcut you can connect to the cluster using the `ssh` command  and password from the `bx cf service-key` response. Look for the log in the `/var/log` folder. The log filename will be similar in format to `chs-cvu-690-mn003.bi.services.us-south.bluemix.net_8997.log`. E.g.:-

```
ssh clsadmin@chs-cvu-690-mn003.bi.services.us-south.bluemix.net

The authenticity of host 'chs-cvu-690-mn003.bi.services.us-south.bluemix.net (169.60.137.171)' can't be established.
ECDSA key fingerprint is SHA256:5dITfzFQIP9ZvKqJwsE582IlHRbFzPM+jq7dvipJ6oc.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'chs-cvu-690-mn003.bi.services.us-south.bluemix.net,169.60.137.171' (ECDSA) to the list of known hosts.
clsadmin@chs-cvu-690-mn003.bi.services.us-south.bluemix.net's password: 
Last login: Wed Dec 13 19:58:14 2017

[clsadmin@chs-cvu-690-mn003 ~]$ cd /var/log

[clsadmin@chs-cvu-690-mn003 log]$ ls
ambari-agent                                                 hive2
ambari-metrics-collector                                     hive-hcatalog
ambari-metrics-monitor                                       jnbg
ambari-server                                                journal
btmp                                                         knox
cdslogging_install-configure.log                             lastlog
chs-cvu-690-mn003.bi.services.us-south.bluemix.net_8997.log  livy2
collectd                                                     lost+found
collectd.log                                                 oozie
cups                                                         spark
falcon                                                       spark2
flume                                                        sqoop
hadoop                                                       sssd
hadoop-hdfs                                                  webhcat
hadoop-mapreduce                                             wtmp
hadoop-yarn                                                  yum.log
hbase                                                        zookeeper
hive

```

A command like `more chs-cvu-690-mn003.bi.services.us-south.bluemix.net_8997.log` will let you page through the log.

While there, since our bootstrap is adding the Avro jar files to the  `/home/common/lib/scala/spark2/` folder, you can navigate there and look to ensure the contents is as expected. Since the script ran as the user `clsadmin` you can tell using `ls -l` which files were added by it.

Note: the ssh url returned by the `bx cf service-key` command will be to one of the management nodes in the cluster. If you want to examine other nodes, to perform diagnosis on a compute node for example, browse to the Dashboad and expand the Nodes list to see the other hostnames. All management nodes can be connected to directly from your workstation. If you need to connect to a compute node, you can only do this if you are already ssh connected to a master node as they have no public IP address.

As with any script there are many potential failure points. Failing to download it from the location you chose to host your boostrap.sh is an issue I encountered while creating this tutorial. 

While connected via ssh you can try using `wget` with the url to your bootstrap.sh to check the location is reacheable from the cluster nodes. This is also a quick way to get the file onto a node so you can run it maunally if you want to make changes or enhancments for your purposes.

## Using the custom IAE cluster from a local Jupyter instance

Finally, the real test for our purposes is to try the new functionality. 

Make sure your cluster is finished creating and customizing. Use the `bx cf create-service-key` command to create the credentials and then `bx cf service-key` to retrieve them. Copy the portion response starting and ending with `{ ... }` and replace the contents of `vcap.json` in this project.

Now, if you have Docker installed on your client, use the `./run_docker_notebook.sh` command to initialize a Jupyter instance on your workstation. It will read the file you just updated and connect the instance to your customized cluster in the IBM Cloud. 

Copy the localhost URL and launch it in a browser. You will find a notebook `avro_test` already loaded. Open that notebook and select `Cell->Run All` . If the result is as follows, you know that Avro was used to retrieve the data

```
+----------+--------------------+----------+
|  username|               tweet| timestamp|
+----------+--------------------+----------+
|    miguno|Rock: Nerf paper,...|1366150681|
|BlizzardCS|Works as intended...|1366154481|
+----------+--------------------+----------+
```

## Command summary

For quick reuse, these are the commands required for the full lifecycle of our custom cluster

```
bx cf create-service IBMAnalyticsEngine standard-hourly iae-custom-cluster -c ./cluster-custom.json
bx cf service iae-custom-cluster
bx cf create-service-key iae-custom-cluster Credentials1 -c {}
bx cf service-key iae-custom-cluster Credentials1
bx cf delete-service-key iae-custom-cluster Credentials1 -f
bx cf delete-service iae-custom-cluster -f
```

## Dynamic use of bootstrap.sh

Since this example of customization includes a script used by cluster nodes when they boot, you will be able to raise and lower the number of nodes in your cluster as needed. Each new node will use the provided bootstrap.sh file as it is initialized. This maintains configuration consistency as you scale the cluster resources. 

This is, however, a consideration when making changes to the bootstrap.sh . Re-initializing all clusters that use it would be recommended to ensure you dont have nodes in each cluster having run different versions of the script.
