<#
.SYNOPSIS
    A script to be incorperated in an Azure Devops release pipeline. Installs software from an exe with appropriate parameters. 
    Variables with the format $(X) come from the pipeline.
#>

$CertThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -match "$(VistaServerFQDN)"}).Thumbprint

$VistaUserMappingApiInstaller = Get-Childitem          `
    -Path       "C:/Installers"                        `
    -Filter     "*vp-user-mapping-api*.exe"            `
    -File                                              `
    -Recurse

if (!$VistaUserMappingApiInstaller) {
    throw "Could not find a user mapping api installer in the directory."
}

if ($VistaUserMappingApiInstaller.count -gt 1) {
    throw "More than one user mapping api installer was found in the directory."
}

$Arguments = @(
            "/S"
            "/v`"/qn"
            "IS_SQLSERVER_SERVER=$(VistaServerFQDN)"
            "IS_SQLSERVER_DATABASE=Viewpoint"
            "IS_SQLSERVER_AUTHENTICATION=1"
            "IS_SQLSERVER_USERNAME=$(DatabaseUsername)"
            "IS_SQLSERVER_PASSWORD=$(DatabasePassword)"
            "IS_SQLSERVER_UM_SERVER=$(VistaServerFQDN)"
            "IS_SQLSERVER_UM_DATABASE=UserManagement"
            "IS_SQLSERVER_UM_AUTHENTICATION=1"
            "IS_SQLSERVER_UM_USERNAME=$(DatabaseUsername)"
            "IS_SQLSERVER_UM_PASSWORD=$(DatabasePassword)"
            "VISTA_APP_SERVER_NAME=$(VistaServerFQDN)"
            "VISTA_CONFIG_SERVICE_PORT_NUM=444"
            "VISTA_IDENTITY_PORT_NUM=443"
            "VPONE_ENTERPRISE=0"
            "USERMAPPING_PORT_HTTPS=448"
            "LOGGING_LEVEL=Debug"
            "SSLCERT=$CertThumbprint"
            "/l \`"C:\Installers\UserManagementAPI\installerlog.txt`"`""
) -Join " "

$InstallerFullName = $VistaUserMappingApiInstaller.FullName

Start-Process                                  `
    -FilePath       $InstallerFullName         `
    -ArgumentList   $Arguments                 `
    -Wait

if((Select-String -Path "C:\Installers\UserManagementAPI\installerlog.txt" -Pattern "Installation operation completed successfully" -Quiet) -ne "True") {
    throw "User mapping API installation failed, consult log located at 'C:\Installers\UserManagementAPI\installerlog.txt' for details."
}