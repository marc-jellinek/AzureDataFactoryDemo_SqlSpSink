#$resourceGroupName = Read-Host "Enter the resource group to remove"

Remove-AzResourceGroup -Name $resourceGroupName -Force
