# Implement your module commands in this script.


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
Add-Type -AssemblyName PresentationFramework
Function Get-GraphAuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory=$true)]
        $user
    )
    Write-Host "Using UPN: " $user -ForegroundColor Yellow
    $Global:userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $user

    Write-Host "Searching for tenant..." -ForegroundColor Yellow
    $Global:tenant = $userUpn.Host
    Write-Host "Using tenant" $tenant -ForegroundColor Yellow
    Write-Host "Checking for AzureAD module..." -ForegroundColor Yellow

        $AadModule = Get-Module -Name "AzureAD" -ListAvailable

        if (!$AadModule) {

            Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
            $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

        }

        if (!$AadModule) {
            write-host
            write-host "AzureAD Powershell module not installed..." -f Red
            write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
            write-host "Script can't continue..." -f Red
            write-host
            exit
        }

    # Getting path to ActiveDirectory Assemblies
    # If the module count is greater than 1 find the latest version

        if($AadModule.count -gt 1){

            $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]

            $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }

                # Checking if there are multiple versions of the same module found

                if($AadModule.count -gt 1){

                $aadModule = $AadModule | Select-Object -Unique

                }

            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

        }

        else {

            $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
            $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

        }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
   
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    
    $resourceAppIdURI = "https://graph.microsoft.com"

    $authority = "https://login.microsoftonline.com/$Tenant"

        try {

        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

            # If the access token is valid then create the authentication header

            if($authResult.AccessToken){

            # Creating header for Authorization token

            $Global:authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }

            return $authHeader

            Write-Host "Authentication Token acquired" -ForegroundColor Cyan
            Write-Host $authHeader -ForegroundColor Cyan

            }

            else {

            Write-Host
            Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
            Write-Host
            Clear-Variable Exportuser -Scope Global
            break

            }

        }

        catch {

        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        Clear-Variable Exportuser -Scope Global
        break

        }

    }
Function New-GraphAuthToken {

    <#
    .SYNOPSIS
    This function is used to check for a current authentication token
    .DESCRIPTION
    The function will check the for a valid authentication token and refresh if it has expired. If not token is found the function with acquire a token
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: New-GraphAuthToken
    #>

    [cmdletbinding()]

    param
    (

    )

    write-host

    # Checking if authToken exists before running authentication
    if($authToken){

        # Setting DateTime to Universal time to work in all timezones
        $DateTime = (Get-Date).ToUniversalTime()

        # If the authToken exists checking when it expires
        $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

            if($TokenExpires -le 0){

            write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
            write-host

                # Defining User Principal Name if not present

                if(!$Exportuser -or $Exportuser -eq ""){

                $Exportuser = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                Write-Host

                }

            $global:authToken = Get-GraphAuthToken -User $Exportuser

            }else{

                Write-Host "You current token is still valid, it expires in: $TokenExpires minutes." -ForegroundColor Yellow

            }
    }

    # Authentication doesn't exist, calling Get-AuthToken function

    else {

        if(!$Graphuser -or $Graphuser -eq ""){

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $EUtitle = 'Azure user account'
        $EUmsg   = 'To connect to your graph application, please enter you Azure user account email address:'

        $Global:Graphuser = [Microsoft.VisualBasic.Interaction]::InputBox($EUmsg, $EUtitle)

        }

    # Getting the authorization token
    $global:authToken = Get-GraphAuthToken -User $Graphuser

    }
    }
function Remove-GraphAppLogin {
    param (

    )

    Clear-Variable authToken -Scope Global
    Clear-Variable authHeader -Scope Global
    Clear-Variable Graphuser -Scope Global
    }
function Remove-GraphAppID {
    param (

    )

    Clear-Variable authToken -Scope Global
    Clear-Variable authHeader -Scope Global
}
Function Remove-GraphApp{

    <#
    .SYNOPSIS
    This function is used to force the user to authenticate
    .DESCRIPTION
    The function will clear all the variables used to acquire an authentication token
    .EXAMPLE
    Remove-GraphApp
    Removes tokens and headers
    .NOTES
    NAME: Remove-GraphApp
    #>

    [CmdletBinding()]
    Param(

    )

    $msgBoxInput =  [System.Windows.MessageBox]::Show('Do you want to log out of the Application too?','Sign out','YesNoCancel','Error')

    switch  ($msgBoxInput) {

    'Yes' {

        Remove-GraphAppLogin
    }

    'No' {

        Remove-GraphAppID

    }

    'Cancel' {

        Write-Host "Application removal canceled" -ForegroundColor Red

    }

  }

}