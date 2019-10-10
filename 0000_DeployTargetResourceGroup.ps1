$subscriptionName = "Free Trial" #Read-Host "Enter the name of the subscription you will be using"
$resourceGroupName = "AzDataFactoryDemo_SqlSpSink_backup" #Read-Host -Prompt "Enter a resource group name where all Azure objects will live"
$location = "eastus" #Read-Host -Prompt "Enter an Azure location for the resource group $resourceGroupName"

Connect-AzAccount -Subscription $subscriptionName

#  Verify the Resource Group doesn't currently exist
Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent) {
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}
else {
    "Resource Group $resourceGroupName already exists, use another resource group name" | Out-Host 
    $resourceGroupName = ""
}

