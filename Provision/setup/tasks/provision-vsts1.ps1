param([xml]$settings)

$ErrorActionPreference = "Stop"

############################################################################
#                           CONSTANTS                                      #
############################################################################

$scriptDir = (split-path $myinvocation.mycommand.path -parent)
$vstsUrl = $settings.configuration.VSTS.vstsUrl
$projectName = $settings.configuration.VSTS.projectName
$buildName = $settings.configuration.VSTS.buildName
$headers = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($settings.configuration.VSTS.vstsToken)")) 
}

# do not change these
$agileTemplateId = "adcc42ab-9882-485e-a3ed-7678f01f66bc"
$createProjectUri = "defaultcollection/_apis/projects?api-version=2.0-preview"
$queryProjectUri = "defaultcollection/_apis/projects/$projectName" + "?api-version=1.0"
$buildDefUri = "defaultcollection/$projectName/_apis/build/definitions?api-version=2.0"
$queueBuildUri = "defaultcollection/$projectName/_apis/build/builds?api-version=2.0"

############################################################################
#                      START OF SCRIPT                                     #
############################################################################

Write-Host ""
Write-Host "Provisioning VSTS Project"
Write-Host "".PadRight(68, "=")

############################################################################
Write-Action "Copying files & Initializing Git repository"

Push-Location

if (Test-Path -Path $settings.configuration.VSTS.workingFolder) {
    & CMD /c rd /s /q $settings.configuration.VSTS.workingFolder
}

mkdir $settings.configuration.VSTS.workingFolder | Out-Null

Set-Location $settings.configuration.VSTS.workingFolder

git init | Out-Null

Copy-Item (Join-Path $scriptDir "..\..\..\Source\ContentModeratorFunction") (Join-Path $settings.configuration.VSTS.workingFolder "ContentModeratorFunction") -recurse
Copy-Item (Join-Path $scriptDir "..\..\..\Source\ContentModeratorFunction.Tests") (Join-Path $settings.configuration.VSTS.workingFolder "ContentModeratorFunction.Tests") -recurse
Copy-Item (Join-Path $scriptDir "..\..\..\Source\ContentModerator.sln")  $settings.configuration.VSTS.workingFolder
Copy-Item (Join-Path $scriptDir "..\..\..\.gitignore")  $settings.configuration.VSTS.workingFolder

git add .

git commit -m "Initial Commit" | Out-Null

Pop-Location

Write-Done
############################################################################
Write-Action "Checking if Project $projectName exists"

$uri = "$vstsUrl/$queryProjectUri" -f $projectName
$projectExists = $true
try {
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
} catch {
    $projectExists = $false
}

Write-Done
###########################################################################
if (!$projectExists) {
    Write-Action "Creating Project $projectName"
    $uri = "$vstsUrl/$createProjectUri"

    $body = @{
        name = $projectName
        description = "Project created for Build Azure Functions Demo"
        capabilities = @{
            versioncontrol = @{
                sourceControlType = "Git"
            }
            processTemplate = @{
            templateTypeId = $agileTemplateId
            }
        }
    }

    $response = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Headers $headers -Body (ConvertTo-Json $body)

    # wait for the project to be created
    $uri = "$vstsUrl/$queryProjectUri"
    $projectId = ""
    for ($i = 0; $i -lt 15; $i++) {
        sleep 20
        
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
        if ($response.state -eq "wellFormed") {
            $projectId = $response.id
            break
        }
    }

    if ($projectId -eq "") {
        throw "Could not create VSTS project (timeout)"
    }

    Write-Done
}
############################################################################
Push-Location

if (!$projectExists) {
    Write-Action "Pushing Code to VSTS"

    Set-Location $settings.configuration.VSTS.workingFolder

    git remote add origin "$vstsUrl/DefaultCollection/_git/$projectName" | Out-Null
    git push -u origin --all | Out-Null

    Write-Done
}

Pop-Location
###########################################################################
Write-Action "Checking if Build Definition $buildName exists"

$uri = "$vstsUrl/$buildDefUri&name=$buildName" -f $projectName

$response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
$buildDefExists = $response.count -ne 0

Write-Done
###########################################################################
if (!$buildDefExists) {
    Write-Action "Creating Build Definition $buildName"
    $uri = "$vstsUrl/$buildDefUri"

    $buildDefinitionRelPath = $settings.configuration.VSTS.buildDefinitionFilePath
    $buildDefinitionFilePath = Join-Path $scriptDir "\..\..\$buildDefinitionRelPath"
    $buildDef = (Get-Content $buildDefinitionFilePath) -join "`n" | ConvertFrom-Json

    # set some parameters for the build definition
    $buildDef.repository.url = "$vstsUrl/DefaultCollection/_git/$projectName"

    $response = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Headers $headers -Body (ConvertTo-Json $buildDef -Depth 10)
    $buildDefId = $response.Id

    Write-Done
}
############################################################################
Write-Action "Queueing Build for $buildName"

$uri = "$vstsUrl/$queueBuildUri"  -f $projectName

$body = @{
    definition = @{
        id = $buildDefId
    }
    sourceBranch = "refs/heads/master"
}

$response = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Headers $headers -Body (ConvertTo-Json $body -Depth 10)

Write-Done
############################################################################

############################################################################
#                        END OF SCRIPT                                     #
############################################################################