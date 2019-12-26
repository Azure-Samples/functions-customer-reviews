param(
    [Parameter(Mandatory=$True)]
    [string]
    $resourceGroup,

    [Parameter(Mandatory=$True)]
    [string]
    $uniqueKey
)

# sign in
if ([string]::IsNullOrEmpty($(Get-AzureRmContext).Account))
{
    Write-Host "Logging in...";
    Login-AzureRmAccount;
}

$storageKey=Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroup `
                                         -AccountName $uniqueKey'stor' `
            | Select-Object -first 1
$storageConnection="DefaultEndpointsProtocol=https;AccountName=$($uniqueKey)stor;AccountKey=$($storageKey.Value);EndpointSuffix=core.windows.net"
$docdbUri="https://$($uniqueKey)docdb.documents.azure.com:443/"
$docdbKey=Invoke-AzureRmResourceAction -Action listKeys `
              -ResourceType 'Microsoft.DocumentDb/databaseAccounts' `
              -ResourceGroupName $resourceGroup `
              -Name $uniqueKey'docdb' `
			  -Force `
          | Select-Object -first 1
$computerVisionKey=Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $resourceGroup `
                                                          -AccountName $uniqueKey'computervision' `
                   | Select -ExpandProperty Key1
$contentModeratorKey=Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $resourceGroup `
                                                          -AccountName $uniqueKey'contentmoderator' `
                   | Select -ExpandProperty Key1
$location=Get-AzureRmCognitiveServicesAccount `
           | ?{ $_.accountName -eq "custer6computervision" } `
           | Select -ExpandProperty Location

$appInsights=Get-AzureRmApplicationInsights -ResourceGroupName $resourceGroup

(Get-Content $PSScriptRoot\local.settings.json) -replace "__AzureWebJobsStorage__",$storageConnection `
                                    -replace "__MicrosoftVisionApiKey__",$computerVisionKey `
									-replace "__ContentModerationApiKey__",$contentModeratorKey `
                                    -replace "__AssetsLocation__",$location `
                                    -replace "__customerReviewDataDocDB__","AccountEndpoint=$docdbUri;AccountKey=$($docdbKey.primaryMasterKey);" `
                                    -replace "__APPINSIGHTS_INSTRUMENTATIONKEY__",$appInsights.InstrumentationKey `
| Set-Content $PSScriptRoot\local.settings.json