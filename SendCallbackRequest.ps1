<#
.SYNOPSIS
    A script that is incorperated in an azure devops release pipeline to register callback urls with an API
#>

#Get the bearer token
$VPIDbody = @{
    grant_type='client_credentials'
    client_id='$(VPClientID)'
    client_secret='$(VPClientSecret)'
    scope='servertoserver'
}

$Response = Invoke-WebRequest -Method POST -Uri  https://voidentity-qa.azurewebsites.net/connect/token -Body $VPIDbody -ContentType "application/x-www-form-urlencoded" -UseBasicParsing | ConvertFrom-Json

$AccessToken = $Response.access_token


#Send the callback request
$CallBackBody = @{
    clientId='PLACEHOLDER'
    url='https://$(VistaServerFQDN)/callback'
} | ConvertTo-Json

$CallBackHeader = @{Authorization = "Bearer $AccessToken"}

Invoke-WebRequest -Method POST -Uri https://voidentity-qa.azurewebsites.net/api/RedirectUrl -Body $CallBackBody -Headers $CallBackHeader -ContentType "application/json" -UseBasicParsing