Param([xml] $settings)

Write-Host ""
Write-Host "Cleaning Up Document DB"
Write-Host "".PadRight(68, "-")

$dbUri = New-Object System.Uri($settings.configuration.documentDbEndpoint)

$client = New-Object Microsoft.Azure.Documents.Client.DocumentClient($dbUri, $settings.configuration.documentDbKey)

$dbObjectUri = [Microsoft.Azure.Documents.Client.UriFactory]::CreateDatabaseUri($settings.configuration.documentDbName)
$client.DeleteDatabaseAsync($dbObjectUri)

$dbObject = New-Object Microsoft.Azure.Documents.Database 
$dbObject.Id = $settings.configuration.documentDbName
$client.CreateDatabaseIfNotExistsAsync($dbObject).GetAwaiter().GetResult()

$dbCollObject = New-Object Microsoft.Azure.Documents.DocumentCollection
$dbCollObject.Id = $settings.configuration.documentDbCollName
$partKeyDefinition = New-Object Microsoft.Azure.Documents.PartitionKeyDefinition
$partKeyDefinition.Paths = New-Object System.Collections.ObjectModel.Collection[String]
$partKeyDefinition.Paths.Add($settings.configuration.documentDbPartKeyPath)
$dbCollObject.PartitionKey = $partKeyDefinition

$client.CreateDocumentCollectionIfNotExistsAsync($dbObjectUri, $dbCollObject)