Param([xml] $settings, 	[bool]$local)

Write-Host ""
Write-Host "Cleaning Up Storage"
Write-Host "".PadRight(68, "-")

$connectionString = $settings.configuration.storageConnectionString

$azureStorage = [Microsoft.WindowsAzure.Storage.CloudStorageAccount]::Parse($connectionString)

if (!$local) {
	$blobClient = $azureStorage.CreateCloudBlobClient()

	$container = $blobClient.GetContainerReference($settings.configuration.containerName)
	$container.CreateIfNotExists()
	Foreach ($blob in $container.ListBlobs())
	{
		$blob.Delete()
	}

	$permissions = $container.GetPermissions()
	$permissions.PublicAccess = [Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType]::Blob
	$container.SetPermissions($permissions)
}

$queueClient = $azureStorage.CreateCloudQueueClient()
if (!$local) {
	$queue = $queueClient.GetQueueReference($settings.configuration.queueName)
	$queue.CreateIfNotExists()
	$queue.Clear()
}

$queue = $queueClient.GetQueueReference($settings.configuration.queueNameLocal)
$queue.CreateIfNotExists()
$queue.Clear()