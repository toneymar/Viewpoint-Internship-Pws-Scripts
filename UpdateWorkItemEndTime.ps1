<#
.SYNOPSIS
    Updates a work item in azure devops to reflect the current (end of deployment) time and switches its state to 'closed'.
    Follows "AddAzDOWorkItem.ps1".
#>

#Set this to the provided work item ID
$AzdoTicketID = "284747"




$ServerName = $env:COMPUTERNAME

#Creds for requests
$CredPair = "Basic:PLACEHOLDER(PAT)"
$EncodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($CredPair))
$JsonHeader = @{ Authorization = "Basic $EncodedCredentials" }

#Get the data from the cloud deploy work item
$CloudDeployUri = 'https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workitems/' + $AzdoTicketID + '?$expand=Relations&api-version=6.0'
$CloudDeployData = Invoke-WebRequest -Method Get -Uri $CloudDeployUri -Headers $JsonHeader -ContentType 'application/json' | ConvertFrom-Json

#See if there's a child with a title that matches the current server name
$WorkItemId = $null
foreach ($child in $CloudDeployData.relations) {
    $Split = $child.url -split '/'
    $ChildUri = 'https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workitems/' + $Split[-1] + '?$expand=Relations&api-version=6.0'
    $ChildData = Invoke-WebRequest -Method Get -Uri $ChildUri -Headers $JsonHeader -ContentType 'application/json' | ConvertFrom-Json
    if ($ChildData.fields.'system.title' -eq $ServerName) {
        $WorkItemId = $Split[-1]
        break
    }
}

#Add an end time and switch the status to 'closed'
if ($WorkItemId) {
    $UpdateWorkItemUri = 'https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workitems/' + $WorkItemId + '?$expand=Relations&api-version=6.0'
    $CurrentTime = [DateTime]::UtcNow | Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

    $PatchBody = 
@"
    [
        {
            "op": "add",
            "path": "/fields/Custom.Releaseendtime",
            "from": null,
            "value": "$CurrentTime"
        },
        {
            "op": "add",
            "path": "/fields/System.State",
            "from": null,
            "value": "Closed"
        }
    ]
"@

    Invoke-WebRequest -Method Patch -Uri $UpdateWorkItemUri -Headers $JsonHeader -Body $PatchBody -ContentType "application/json-patch+json"
    Write-Host "Updated the end time for $Servername's work item ($WorkItemId)"
} else {
    Write-Host "Couldn't find a work item for $ServerName"
}
