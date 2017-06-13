Param([xml] $settings)

Write-Host ""
Write-Host "Provisioning Images"
Write-Host "".PadRight(68, "-")

function UploadImage {Param ([string]$scriptDir, [string]$fileName, $container, $client, $docCollUri)
	$assetsFolder = $scriptDir + "\..\..\assets\";

	$recordId = [System.Guid]::NewGuid()

	$bytes = [System.IO.File]::ReadAllBytes($assetsFolder + $fileName)

	$blockBlob = $container.GetBlockBlobReference($recordId.ToString())
    $blockBlob.UploadFromByteArray($bytes, 0, $bytes.Length)

    $catReview = @{}
	$catReview.id = $recordId
	$catReview.MediaUrl = $blockBlob.Uri.ToString()
	$catReview.IsApproved = $fileName.StartsWith("A", [System.StringComparison]::InvariantCultureIgnoreCase)
	$catReview.Created = [System.DateTime]::UtcNow
	$catReview.reviewId = $settings.configuration.documentDbPartValue

    $client.CreateDocumentAsync($docCollUri, $catReview)
}

$connectionString = $settings.configuration.storageConnectionString
$azureStorage = [Microsoft.WindowsAzure.Storage.CloudStorageAccount]::Parse($connectionString)
$blobClient = $azureStorage.CreateCloudBlobClient()
$container = $blobClient.GetContainerReference($settings.configuration.containerName)

$dbUri = New-Object System.Uri($settings.configuration.documentDbEndpoint)
$client = New-Object Microsoft.Azure.Documents.Client.DocumentClient($dbUri, $settings.configuration.documentDbKey)
$docCollUri = [Microsoft.Azure.Documents.Client.UriFactory]::CreateDocumentCollectionUri($settings.configuration.documentDbName, $settings.configuration.documentDbCollName)

$scriptDir = (split-path $myinvocation.mycommand.path -parent)
UploadImage $scriptDir "approved-01.jpg" $container $client $docCollUri
UploadImage $scriptDir "approved-02.jpg" $container $client $docCollUri
UploadImage $scriptDir "approved-03.jpg" $container $client $docCollUri
UploadImage $scriptDir "approved-04.jpg" $container $client $docCollUri
UploadImage $scriptDir "rejected-01.jpg" $container $client $docCollUri