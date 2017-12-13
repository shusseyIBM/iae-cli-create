### Use the Cloud Foundry command line without the IBM CLoud CLI

If you want to use the Cloud Foundry command line exclusively you can do that

[Logon IAE docs](https://console.bluemix.net/docs/services/AnalyticsEngine/provisioning.html#creating-a-service-instance-using-the-cloud-foundry-rest-api)

#### Assign the URL endpoint for your Region
Depending on your IBM Cloud Region you will have a different API endpoint. use the `bx api` command to get a current list.

```
$ bx api
eu-de      https://api.eu-de.bluemix.net   
au-syd     https://api.au-syd.bluemix.net   
us-south   https://api.ng.bluemix.net   
eu-gb      https://api.eu-gb.bluemix.net 
```

Use the command `cf api` to set the endpoint for this session.

```
cf api https://api.ng.bluemix.net
```

### Log on

If you have an individual user id for IBM Cloud use the command `cf login` . Depending on your account and organiztion you will see something similar to the following

```

$ cf login
API endpoint: https://api.ng.bluemix.net

Email> shussey@us.ibm.com

Password> 

Authenticating...
OK

Select an org (or press enter to skip):
1. zxy987@ca.ibm.com
2. abc123@us.ibm.com

Org> 2
Targeted org abc123@us.ibm.com

Select a space (or press enter to skip):
1. dev
2. prod

Space> 1
Targeted space dev

API endpoint:   https://api.ng.bluemix.net (API version: 2.92.0)
User:           abc123@us.ibm.com
Org:            abc123@us.ibm.com
Space:          dev

$
```

If your organization is using Single Sign On the initial steps of the command above will fail and you will be redirected to use the command `cf login --sso` instead.


```

> cf login --sso
API endpoint: https://api.ng.bluemix.net //

One Time Code (Get one at https://login.ng.bluemix.net/UAALoginServerWAR/passcode)> 
Authenticating...
OK

...
```

The remainder of the sequence should be the same.