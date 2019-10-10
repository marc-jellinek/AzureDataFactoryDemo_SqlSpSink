$deployment = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ".\0010_DeploySourceAndTargetDatabase.json" -TemplateParameterFile "./0010_DeploySourceAndTargetDatabase.parameters.json"

$deployment | Out-Host

$sourceDatabaseServerName = $deployment.Outputs.sourceDatabaseServerName.Value
$targetDatabaseServerName = $deployment.Outputs.targetDatabaseServerName.Value
$dataFactoryName = $deployment.Outputs.dataFactoryName.Value 