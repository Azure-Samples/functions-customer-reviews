Write-Host ""
Write-Host "Loading Assemblies Dependencies"
Write-Host "".PadRight(68, "=")

$storageClientDir = (split-path $myinvocation.mycommand.path -parent) + "\tasks\storageClient"

pushd $storageClientDir

[Reflection.Assembly]::LoadFile((Get-Item 'System.Spatial.dll').FullName)
[Reflection.Assembly]::LoadFile((Get-Item 'Microsoft.Data.Edm.dll').FullName)
[Reflection.Assembly]::LoadFile((Get-Item 'Microsoft.Data.Odata.dll').FullName)
[Reflection.Assembly]::LoadFile((Get-Item 'Microsoft.WindowsAzure.Storage.dll').FullName)
[Reflection.Assembly]::LoadFile((Get-Item 'Microsoft.Data.Services.Client.dll').FullName)

popd

$documentDBClientDir = (split-path $myinvocation.mycommand.path -parent) + "\tasks\documentDBClient"

pushd $documentDBClientDir

[Reflection.Assembly]::LoadFile((Get-Item 'Newtonsoft.Json.dll').FullName)
[Reflection.Assembly]::LoadFile((Get-Item 'Microsoft.Azure.Documents.Client.dll').FullName)

popd