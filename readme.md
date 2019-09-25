<p><b>Learning Azure Data Factory the Hard Way:  </b></p>
<p><i>Using a SQL Server Stored Procedure as a Data Factory Copy Activity Sink</i></p>
<p><i>Creating a Slowly Changing Dimension Type 4 using SQL Server Temporal Tables</i></p>

<u>The problem:</u>
I have a source system holding the names of employees.  I'd like to use this as the source for my data warehouse's Employee dimension.  The source holds only the current state of an Employee, with no history.  My business requirements say that I have to capture any changes to an Employee record as a Slowly Changing Dimension Type 4. (See https://en.wikipedia.org/wiki/Slowly_changing_dimension).

<u>The Context:</u>
I created a solution that gives you a quick but complete Slowly Changing Dimension Type 4 implementation, even where the source system doesn't keep history.  From implementation date forward, the source can be polled and the target updated with change history stored in a separate table.

Along the way, I learned something very important about Azure Data Factory.  I can't find this behavior documented anywhere, so I'm going to provide step-by-step instructions on how to demonstrate the behavior.

All source documents are provided in order to allow you to reproduce my results.  You can follow along with me, step by step.  <b>THIS WILL INCUR AZURE UTILIZATION CHARGES.</b>

I've kept this demonstration as lean as possible in order to keep associated costs to a minimum.  You can run this in an Azure subscription provided through Visual Studio subscribers https://azure.microsoft.com/en-us/pricing/member-offers/credit-for-visual-studio-subscribers/ or use the Azure Free Account and get $200 credit and 12 months of free services https://azure.microsoft.com/en-us/free/.

What are the costs?  

In this demo, I create two Azure SQL Servers (no cost) each hosting an Azure SQL Database (cost).  One is designated the source, the other, the sink.  Both are Basic tier Single Databases deployed to the East US region.  If I leave the databases deployed they will cost me $9.79 per month.  I give you a cleanup script that will drop all of the Azure resources deployed with this demo.  I regularly deploy this demo, work with it, then drop it, keeping my Azure charges to a minimum ($0.0067 per hour).

I'm an old database and data warehouse guy, so I'm very comfortable with using SQL Server as a data source, data sink or source of compute resources.  In this demo, the source and the sink are both instances of Azure SQL Database.  For the sake of the behavior I'll demonstrate, the source really doesn't matter.  The behavior I'll demonstrate will show what happens when you use a SQL Server Stored Procedure as a Copy Activity sink in an Azure Data Factory pipeline.

I've provided ARM templates, PowerShell scripts, Azure Resource Manager templates and Azure Resource Manager parameter files that will allow you to quickly and easily deploy all the resources you will need.

<b><u>Files:</u></b>
<li>0000_DeployTargetResourceGroup.ps1
<li>0010_DeploySourceAndTargetDatabase.json
<li>0010_DeploySourceAndTargetDatabase.ps1
<li>0020_DeploySourceDatabaseObjects.sql
<li>0030_DeployTargetDatabaseObjects.sql
<li>0040_DeployDataFactory.json
<li>0040_DeployDataFactory.ps1
<li>9999_RemoveTargetResourceGroup.ps1

<u>0000_DeployTargetResourceGroup.ps1</u>
Prompts you for the name of the Azure Subscription you will be using
Prompts you for the name of the Azure Resource Group where all associated resources will be deployed
Prompts you for the location where the Resource Group and all associated resources will be deployed

<u>0010_DeploySourceAndTargetDatabase.json</u>
Azure Resource Manager template that creates the following Azure resources:
<li>Azure SQL Server (source server)
<li>Azure SQL Database (SourceDatabase)
<li>Azure SQL Server (target server)
<li>Azure SQL Database (TargetDatabase)
<li>Azure SQL Database Admin Account (demoadmin)

In order to keep costs to a minimum, the source and sink databases are both hosted in the same region.  The names of the source server and target server have to be globally unique, so I generate guids as the server names.  When this template is successfully deployed, it will output the connection strings to both databases

<u>0010_DeploySourceAndTargetDatabase.ps1</u>
Powershell script that deploys the ARM template 0010_DeploySourceAndTargetDatabase.json.

<u>0020_DeploySourceDatabaseObjects.sql</u>
Creates the source database objects we will require.  These are:
<li>TABLE:  dbo.Employees
<li>DATA:   100 rows of sample data.

100 rows of data should be enough to test if this works.  <i>These are famous last words</i>.  But read on:

<u>0030_DeployTargetDatabaseObjects.sql</u>
Creates the target database objects will will require.  These are:
<li>SCHEMA: Audit - holds operational data
<li>SCHEMA: dim - holds dimension tables
<li>TABLE:  Audit.OperationsEventLog - holds runtime logging data
<li>TABLE:  dim.Employee, dim.Employee_History - holds latest and historical values for Employees
<li>PROC:   Audit.InsertOperationsEventLog - logs runtime logging data 
<li>PROC:   dim.Load_Employee - loads supplied data into dim.Employee

<u>0040_DeployDataFactory.json</u>
Azure Resource Manager template that creates the Data Factory that will copy data from source to target.

<u>0040_DeployDataFactory.ps1</u>  PowerShell script that deploys the ARM template 0040_DeployDataFactory.json

<u>9999_RemoveTargetResourceGroup.ps1</u>
Drops the Resource Group created by 0000_DeployTargetResourceGroup.ps1

Notice that dim.Employee is a temporal table, a feature introduced in SQL Server 2016.  This feature is also supported in Azure SQL Database.  See https://docs.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables?view=sql-server-2017

Setting up dim.Employee as a temporal table means the latest state of an Employee is to be held in the table dim.Employee.  Detected change history will be automatically kept in the table dim.Employee_History.

Data will be loaded into dim.Employee using an Azure Data Factory pipeline.  The pipeline will use a Copy Activity where the source is the source system and the sink is a SQL Server stored procedure (dim.Load_Employee) that MERGEs the supplied data into dim.Employee.  Any changes are automatically recorded in dim.Employee_History, as is the nature of Temporal Tables.

I'm using a stored procedure as the data sink so we can process the supplied data using a single MERGE statement.  Existing Employees will be updated, Employees supplied by the source that don't exist in dim.Employees are inserted and Employees that have been deleted from the source are also deleted from the dimension table.  A record of its existence will remain in dim.Employee_History.  See https://docs.microsoft.com/en-us/azure/data-factory/connector-sql-server#invoke-a-stored-procedure-from-a-sql-sink for details on using a stored procedure in a SQL Server sink in the Copy activity.

If you are following along, I'm working in Visual Studio Code with the following extensions:
<li>Azure Resource Manager Tools
<li>PowerShell
<li>SQL Server (mssql)

Also required are PowerShell 5.1 and the PowerShell Az module (https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-2.6.0)

// in reality, all connection strings, usernames, passwords and credentials should be stored in Azure Key Vault, but I'm leaving them in cleartext in the parameter files for the educational value and clarity.  To use references to Azure Key Vault secrets from within the parameter file, see https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-keyvault-parameter

// database firewall rules are intentionally wide-open.  <b>DO NOT DEPLOY THIS TO PRODUCTION OR USE THE DATABASES TO STORE PRODUCTION DATA</b>

// in reality, one would not connect to an instance of SQL Database using the administrators account.  Use a least-priv-user in each database

// <b>DO NOT DEPLOY THIS TO PRODUCTION OR USE THE DATABASES TO STORE PRODUCTION DATA</b>

<b>Deploying the solution:</b>

In Visual Studio Code open the folder holding the code.

![Open Visual Studio Code](./graphics/0010_Open_Visual_Studio_Code.png)

We're going to deploy the resource group that will hold all of our Azure resources. You will need the following information:
<li>The name of the Azure subscription you will be deploying to (I use "Marc Jellinek - Visual Studio Enterprise")
<li>The name of the resource group you will be deploying to (I use "AzDataFactoryDemo_SqlSpSink" - must be a NEW resource group, do not use an existing resource group)
<li>The name of the location you will be deploying to (I use eastus)

Open the file 0000_DeployTargetResourceGroup.ps1

Fill in the values for $subscriptionName, $resourceGroupName and $location.

![Deploy Target Resource Group](./graphics/0015_DeployTargetResourceGroup.png)

Hit F5 to run.  The script will ask you to log into your Azure account, then create a new resource group with the name you gave. 

If you use the name of a resource group that already exists, the script will tell you.  You must use a new resource group, do not use an existing one.

![Do not use an existing resource group name](./graphics/0020_DeployTargetResourceGroup_ResourceGroupExists.png)

Log into the Azure Portal at https://portal.azure.com, select Resource Groups (on the left side), filter based on your resource group name and confirm that it was created.

![Create New Resource Group](./graphics/0030_Validate_Create_New_Resource_Group.png)

Our next step is to deploy the source and target database servers and databases.  Open the file 0010_DeploySourceAndTargetDatabase.ps1 and hit F5.  This will deploy the ARM template stored in 0010_DeploySourceAndTargetDatabase.json.

![Create Source and Target Database Servers and Databases](./graphics/0040_DeploySourceAndTargetDatabaseServers.png)

This takes a bit of time, so be patient.  When the template is deployed, it will tell you the connection strings for your source and target databases.  Notice that the server names for the deployed Azure SQL Servers are named as GUIDs.  These are generated as part of the deployment.  The server names must be globally unique.

When this is complete, go into the Azure Portal, select your resource group and look at the resources it contains.  It should look like this (your server names will be different, but they should be named as guids).

![Confirm Source and Target Database Servers and Databases](./graphics/0045_ConfirmDeploySourceAndTargetDatabaseServers.png)

The next part is to set up database connections to the source and target databases so we can deploy database objects.

From within Visual Studio Code, open the file 0020_DeploySourceDatabaseObjects.sql
From within Visual Studio Code, hit F1 and type 'mssql' and select MS SQL: Connect.

![Set Up Source and Target Database Connections](./graphics/0050_SetupDatabaseConnections.png)

Copy-and-paste the sourceDatabaseConnectionString output by 0010_DeploySourceAndTargetDatabase.json.

Give the connection a profile name of "AzureDataFactoryDemo_SqlSpSink_SourceDatabase".

You can now run the script against the Source Database by hitting Ctrl-Shift-E.  This will create a table called dbo.Employees and populate it with 100 rows of sample data.  This is confirmed for you with the last line of the script.  You should see this as the result:

![Deploy Source Database Objects](./graphics/0060_DeploySourceDatabaseObjects.png)

Open the file 0030_DeployTargetDatabaseObjects.sql and connect to the target database.  Name the connection profile AzureDataFactoryDemo_SqlSpSink_TargetDatabase and run the script.  Your results will be this:

![Deploy Target Database Objects](./graphics/0070_DeployTargetDatabaseObjects.png)

Don't worry if there are errors like "Cannot find the object dim.Employee" or "Cannot drop the schema 'Audit'".  The script was meant to be run multiple times, so there is code that drops existing objects then re-creates them.  This is not a concern.

If you'd like to pause at this point to confirm the database objects have been created, open up SQL Server Management Studio or the client of your choice and connect to the source and target databases.

![Confirm Database Object Creation](./graphics/0080_ConfirmDatabaseObjectCreation.png)

Our last deployment step is to create the Data Factory that will copy data from our source database and merge it into our target database.  Open the file 0040_DeployDataFactory.ps1 and hit F5.

Go back into the Azure Portal, select your resource group and hit refresh.  You should see the data factory named AzureDataFactoryDemo-SqlSpSink-Data-Factory

![Confirm Data Factory Creation](./graphics/0090_ConfirmDataFactoryCreation.png)

In the Azure Portal, click on the Data Factory, then click on Author & Monitor.  When creating a new Data Factory, the first time I go into Author & Monitor, I'll see "Loading..." for a bit.  If you see "Loading..." for more than a few minutes, log out of all your Azure accounts (I often run multiple simultaneously) and log back in using only your the account that has access to your Azure subscription.  That often clears up the problem.  You should see a Data Factory that has no Connections, no Datasets and no Pipelines.



Now that we've created the Data Factory, we will populate it with all the elements required to pull data from the source database and merge it into the destination database.

Open the file 0040_DeployDataFactory.ps1 and hit F5.



