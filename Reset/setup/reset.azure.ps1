Param([string] $settingsFile, [bool]$local=$false)

$Error.Clear()

$scriptDir = (split-path $myinvocation.mycommand.path -parent)
Set-Location $scriptDir

# import demo tookit
Import-Module ".\tasks\demo-toolkit\DemoToolkit.psd1" -DisableNameChecking

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
Write-Host "Reset Azure $environment"
Write-Host "".PadRight(68, "=")

# --------------------------------- #

. ".\load.dependencies.ps1" $settings

. ".\tasks\reset-storage-account.ps1" $settings $local

if (!$local) {
	. ".\tasks\reset-documentdb.ps1" $settings
	. ".\tasks\provision-images.ps1" $settings
}