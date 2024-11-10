# fed-court technical test

## Introduction

This is a project deploys the architecture detailed below. It was Created using Azure Bicecp, Githup Actions and deploys to an Azure Subscription.

## DESIGN

The design of this system is an App service that talks to a SQL server. The App service is exposed to the public and has logging attached, scaled by CPU, and is placed in a vnet and subsiquent subnet. The SQL is to be secured by a private endpoint brings the SQL within the private endpoints own subnet.

Deployment is through Github Actions and the code to deploy the architecture is Azure Bicep.

![Alt text](diagram.jpg?raw=true "Title")

### Reasons for technical 