# fed-court technical test

## Introduction

This is a project that deploys the architecture detailed below. It was Created using Azure Bicecp, Githup Actions and deploys to an Azure Subscription.

This is a fully working project that has been deployed and tested.

There is also an Api App under the FedCourt directory I created to deploy and test the infrastructure.

## DESIGN

The design of this system is an App service that talks to a SQL server. The App service is exposed to the public and has logging attached, scaled by CPU, and is placed in a vnet and subsiquent subnet. The SQL is to be secured by a private endpoint brings the SQL within the private endpoints own subnet.

Deployment is through Github Actions and the code to deploy the architecture is Azure Bicep.

![Alt text](diagram.jpg?raw=true "Title")

### Technical implementations

### Github

The project spec asked to use Azure Devops, unfortunatly to get the pipelines up and running I needed to apply to Microsoft for parallel job running and that would have taken 3 business days by Microsoft to activate. I have used Github extensively and as a Microsoft product thought it the next best thing.

#### Actions

There is a single Github action (pipeline) that takes a parameter of "environment". That being DEV, TEST or PROD. The settings and values to run the pipeline are then loaded from Githubs Environment Variables and Secrets. These are used to connect to the Azure Subscription and pass to the Bicep script pre defined parameters like EnviromentName, Location, Azure SQL admin password etc.

The pipeline is triggerd manually but can be set up using branching structures.

Steps in the pipeline

1. Checkout the bicep scripts from the main branch
2. Login to the Azure Subscription
3. Validate the Bicep scripts using azure/bicep-deploy@v1 Validate
4. Wat-If the Bicep scripts to get a full log of what the run will change on the Azure subscription through the deployment
5. Deploy to the Azure Subscription
6. Check that the system is up and running using jtalk/url-health-check-action@v4. This calls the /healthy url of the web app that uses the sql connection string in the keyvault and executes a simple query on the database. If there were any issues, this would fail.

### Bicep

The bicep has a main.bicep file and then components are split off into their own files (modules). This is a clean approach, cuts down on the size of one big main bicep file and allows the modules to be reused by other possible pipelines in the future.

#### Logging and Monitoring

Azure Monitor is used for all high level system health that plugs into deployed resources.

Application Insights backed by Log Analytics is provisioned and attached to the App service. This will collect any custom logging from the app itself as well as a miriad of out of the box metrics like App service CPU, health etc.

#### KeyVault

I deployed the keyvault to it's own resource group, this makes it easier to maintain if environemnts are destroyed and re-deployed as you would come up against the issue of purging the deleted keyvault. Access to the KeyVault is granted only to the AppService via an RBAC role thats only allowed to retrieve the secrets. It is accessed via the App Service code using the DefaultAzureCredential principal.

#### SQL Database vs SQL Managed Instance

I started out with a SQL Managed Instance so I could put it directly into the subnet but the deployment was taking too long (30 minutes +) and after multiple teardowns that took 40 minutes plus I decided to use an Azure SQL database and connect the App Service to the Azure SQL Database via a private link this was deployed to the sql subnet, therefore via connection brining the SQL Database into the subnet

#### SQL tracking

Sql tracking is automatically turned on as a dependency item for Application Insights. This can be expanded with full text logging using:

https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-dependencies#advanced-sql-tracking-to-get-full-sql-query

SQL pwrformance is also viewable through Query Performance Monitoring as a tab through the azure portal. More detail available here:

https://learn.microsoft.com/en-us/azure/azure-sql/database/query-performance-insight-use?view=azuresql

Through Azure Monitor it is also recommended to use the new Database Watcher... (in preview)

https://learn.microsoft.com/en-us/azure/azure-sql/database-watcher-overview?view=azuresql

### Other things I'd use in v2.0

#### App Service Service Connector

An App Service Service Connector when set up correctly will build and add the connection string to the key vault and automatially add the right App Settings to retrieve that connection string. It also gives a great portal representation of the health of the connection to the database. This can siplify the Bicep so you don't have to add the Connection String yourself

https://learn.microsoft.com/en-us/azure/service-connector/overview

#### Resource Groups

I'd split the resources into more resource groups so secutity access can be granted at the resource group level depending on your operational support:

- logging: only available to ops teams
- data: sql administrators
- networking: keep critical netorking infrastructure in one place

#### Application Dashboard

I'd create an application dashboard that would pull in critical information for the application as a single pane of glass reporting

#### Pipeline steps and jobs

I'd split the pipleine into more jobs and group steps and not have a singe job that had multiple steps
