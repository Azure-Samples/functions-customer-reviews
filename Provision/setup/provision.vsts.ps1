Param([string] $settingsFile)

$Error.Clear()

$scriptDir = (split-path $myinvocation.mycommand.path -parent)
Set-Location $scriptDir

# import progress functions
. ".\tasks\progress-functions.ps1"

# "========= Initialization =========" #
pushd ".."

if($settingsFile -eq $nul -or $settingsFile -eq "")
{
	$settingsFile = "config.xml"
}

[string] $environment = "Primary"

# Import required settings
[xml] $settings = Get-Content $settingsFile

popd
# "========= Main Script =========" #

Write-Host ""
Write-Host "Provisioning Environment"
Write-Host "".PadRight(68, "=")

# --------------------------------- #

. ".\tasks\provision-vsts1.ps1" $settings