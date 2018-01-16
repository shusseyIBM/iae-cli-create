# Create a custom IAE instance with Avro

The customization that we are applying in this example is to add [Avro](https://github.com/databricks/spark-avro) to our Spark cluster. This will be done using a [bootstrap.sh](./bootstrap.sh) script included in this project. When we execute the new cluster creation the bootstrap.sh script is executed on all nodes. If you take a look at the logic of bootstrap.sh you will see that although the Avro install runs on all nodes, the management node performs an additional services restart command. This ensures that the cluster adopts the new module correctly. It will, however, extend the cluster initialization time given that there are a couple of `sleep` commands to allow the restart to complete. 

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
