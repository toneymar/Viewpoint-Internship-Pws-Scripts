<#
.SYNOPSIS
    Creates a new work item in azure devops for software deployments that is linked to a specified parent work item. Uses the azure devops API.
    Script "UpdateWorkItemEndTime.ps1" follows this after the deployment is finished.
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
$WorkItemExists = $false
foreach ($child in $CloudDeployData.relations) {
    $Split = $child.url -split '/'
    $ChildUri = 'https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workitems/' + $Split[-1] + '?$expand=Relations&api-version=6.0'
    $ChildData = Invoke-WebRequest -Method Get -Uri $ChildUri -Headers $JsonHeader -ContentType 'application/json' | ConvertFrom-Json
    if ($ChildData.fields.'system.title' -eq $ServerName) {
        $WorkItemExists = $true
        break
    }
}

#Create a new work item for this deployment
if (!$WorkItemExists) {
    $CreateWorkItemUri = 'https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workitems/$releasetask?$expand=Relations&api-version=6.0'
    $CurrentTime = [DateTime]::UtcNow | Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $WorkItemtBody = 
@"
    [
        {
            "op": "add",
            "path": "/fields/System.Title",
            "from": null,
            "value": "$ServerName"
        },
        {
            "op": "add",
            "path": "/fields/Custom.Releasestarttime",
            "from": null,
            "value": "$CurrentTime"
        },
        {
            "op": "add",
            "path": "/fields/Custom.Geo",
            "from": null,
            "value": "Global"
        },
        {
            "op": "add",
            "path": "/fields/System.State",
            "from": null,
            "value": "Active"
        },
        {
            "op": "add",
            "path": "/relations/-",
            "value": {
                "rel": "System.LinkTypes.Hierarchy-Reverse",
                "url": "https://dev.azure.com/ViewpointVSO/ReleaseManagement/_apis/wit/workItems/$AzdoTicketID",
                "attributes": {
                    "isLocked": false,
                    "name": "Parent"
                }
            }
        }
    ]
"@

    $Response = Invoke-WebRequest -Method Patch -Uri $CreateWorkItemUri -Headers $JsonHeader -Body $WorkItemtBody -ContentType "application/json-patch+json" | ConvertFrom-Json
    $WorkItemId = $Response.id
    Write-Host "Created a work item for $ServerName with ID $WorkItemId"
} else {
    Write-Host "A work item for $ServerName already exists"
}