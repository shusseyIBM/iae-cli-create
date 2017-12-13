The goal of this sample is to help you understand the mechanics of deploying an instance of IAE with customization for yoru purpose. many customizations can be performed after the instance has been created even dynamically when using it through data science tools like Jupyter notebooks. 

However, there are situations where the manageability of these addons needs to be baked into a foundation regardless of what application or experience is using the engine. The methods described here allow you not only to modify an indivitual cluster but to deliver a repeatable baseline configuration across multiple clusters. It is also useful if you want to tear down a cluster between uses and rebuild it when workloads return.

The structure of IBM Cloud provides ways to orginize resources in a number of ways. It is important to know how you or your organization is using the IBM Cloud so that when you create or change instances of IEA you will be using the right constructs. Find out what your company is using for:

Resource Group 
Region
Cloud Foundry Org
Cloud Foundry Space

These selections should be visible at the top of the page in IBM Cloud when you are in Dashboard views

For the customization the first challenge for customizing a cluster on startup is choosing a location for the customization scripts. When you start the cluster you will be initiating it with additional options that point to a boostrap.sh file. This file must be reacheable by the cluster as it starts. This can be a public internet base location or a secure location requiring credential

