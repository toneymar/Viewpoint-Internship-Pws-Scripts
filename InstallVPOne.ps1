<#
.SYNOPSIS
    A script to be incorperated in an Azure Devops release pipeline. Installs software from an exe with appropriate parameters. 
    Variables with the format $(X) come from the pipeline.
#>

$CertThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "$(VistaServerFQDN)"}).Thumbprint

$VPOneInstaller = Get-Childitem                         `
    -Path       "C:/Installers"                         `
    -Filter     "*vp-vista-vpone-integration*.exe"      `
    -File                                               `
    -Recurse

if (!$VPOneInstaller) {
    throw "Could not find a Viewpoint One integration installer in the directory."
}

if ($VPOneInstaller.count -gt 1) {
    throw "More than one Viewpoint One integration installer was found in the directory."
}

$Arguments = @(
            "/S"
            "/v`"/qn"
            "IS_SQLSERVER_SERVER=$(VistaServerFQDN)"
            "IS_SQLSERVER_DATABASE=Viewpoint"
            "IS_SQLSERVER_AUTHENTICATION=1"
            "IS_SQLSERVER_USERNAME=$(DatabaseUsername)"
            "IS_SQLSERVER_PASSWORD=$(DatabasePassword)"
            "VISTA_APP_SERVER_NAME=$(VistaServerFQDN)"
            "VISTA_CONFIG_SERVICE_PORT_NUM=444"
            "VISTA_IDENTITY_PORT_NUM=443"
            "VPINT_PORT_HTTPS=449"
            "VPONE_ENTERPRISE=0"
            "VPID_CLIENT_ID=vista-client-qa"
            "VPID_CLIENT_PWD=$(IdentityClientSecret-VistaClient)"
            "VPONE_REGION=qa"
            "LOGGING_LEVEL=Debug"
            "SSLCERT=$CertThumbprint"
            "/l \`"C:\Installers\ViewpointOneIntegration\installerlog.txt`"`""
) -Join " "

$InstallerFullName = $VPOneInstaller.FullName

Start-Process                                                `
       -FilePath            $InstallerFullName      `
       -ArgumentList   $Arguments                `
       -Wait

if ((Select-String -Path "C:\Installers\ViewpointOneIntegration\installerlog.txt" -Pattern "Installation operation completed successfully" -Quiet) -ne "True") {
    throw "Viewpoint One integration installation failed, consult log located at 'C:\Installers\ViewpointOneIntegration\installerlog.txt' for details."
}