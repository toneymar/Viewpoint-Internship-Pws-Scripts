<#
.SYNOPSIS
    Updates a json file containing server connection urls for the Vista client. Replaces the date field in each url with the current date. For daily testing of software.
#>

$Date = Get-Date -Format "MMdd"

$ConnectionsFile = Get-Childitem                           `
    -Path       "C:\Users\$env:USERNAME\AppData\Roaming"   `
    -Filter     "*VistaUserConfiguration.json"             `
    -File                                                  `
    -Recurse

$Json = Get-Content $ConnectionsFile.FullName | ConvertFrom-Json

$Json.MaxConnectionConfigurations = 10

foreach ($server in $Json.ConnectionConfigurations) {
    
    if ($server.ServerLocator -match '-\d{4}V') {
        $server.ServerLocator = $server.ServerLocator -replace '-\d{4}V', "-$($Date)V"
    } 
    elseif ($server.ServerLocator -match '-\d{4}\.') {
        $server.ServerLocator = $server.ServerLocator -replace '-\d{4}\.', "-$($Date)."
    }
}

$Json | ConvertTo-Json -depth 32 | Set-Content $ConnectionsFile.FullName