New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile ".\0100_UpdateDataFactory.json" -TemplateParameterFile "./0040_DeployDataFactory.parameters.json"