# Customizing the IBM Analytics Engines from a command line

The goal of this sample is to help you understand the mechanics of deploying an instance of IAE with customization for your purpose. many customizations can be performed after the instance has been created even dynamically when using it through data science tools like Jupyter notebooks. 

However, there are situations where the manageability of these addons needs to be baked into a foundation regardless of what application or experience is using the engine. The methods described here allow you not only to modify an indivitual cluster but to deliver a repeatable baseline configuration across multiple clusters. It is also useful if you want to tear down a cluster between uses and rebuild it when workloads return.

## Your IBM Cloud organization

The structure of IBM Cloud provides ways to orginize resources in a number of ways. It is important to know how you or your organization is using the IBM Cloud so that when you create or change instances of IAE you will be using the right constructs. 

Find out what your company is using for:

* Resource Group 
* Region
* Cloud Foundry Org
* Cloud Foundry Space

These selections should be visible at the top of the page in IBM Cloud when you are in Dashboard views. For further understanding of how to use them to organize your resources refer to [IBM Cloud documentation](https://console.bluemix.net/docs/admin/patterns.html#patterns)


## Getting set up and connected to IBM Cloud

Follow the instructions [here](ibmcloudlogin.md) to set up your workstation, login and select the right options for your organization to manage IBM Cloud services.

## Creating standard and custom IAE clusters

Once you are connected [this tutorial](createiaeinstances.md) will guide you through the steps to create repeatable IAE instances using the IBM Cloud Command Line Interface and through it, the Cloud Foundry CLI. 