$resourceGroupName = Read-Host "Enter the resource group to remove"

Remove-AzureRmResourceGroup -Name $resourceGroupName