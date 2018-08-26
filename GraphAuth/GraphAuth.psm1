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
    Write-Host "Using UPN: " $Exportuser -ForegroundColor Yellow
    $Global:userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $Exportuser

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

    #$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    if(!$clientId -or $clientId  -eq ""){

        Write-Host "Please confirm your Application ID" -ForegroundColor Yellow

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $CIDtitle = 'Graph Application ID'
        $CIDmsg   = 'Please confrim your Graph Application ID:'

        $Global:clientId = [Microsoft.VisualBasic.Interaction]::InputBox($CIDmsg, $CIDtitle)
        Write-Host "Using AppID: " $clientId -ForegroundColor Yellow
    }else{

        Write-Host "Using AppID: " $clientId -ForegroundColor Yellow
    }
    #$redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    if(!$redirectUri -or $redirectUri  -eq ""){

        Write-Host "Please confirm you Application uri" -ForegroundColor Yellow

    [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $ReURititle = 'Application Redirect URL'
        $ReURimsg   = 'Please confrim the application redirect url:'

        $Global:redirectUri = [Microsoft.VisualBasic.Interaction]::InputBox($ReURimsg, $ReURititle)

        Write-Host "Using RedirectUri: " $redirectUri -ForegroundColor Yellow
    }else{

        Write-Host "Using RedirectUri: " $RedirectUri -ForegroundColor Yellow
    }

    $resourceAppIdURI = "https://graph.microsoft.com"

    $authority = "https://login.microsoftonline.com/$Tenant"

        try {

        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

        # https://msdn.microsoft.com/en-us/library/azure/microsoft.identitymodel.clients.activedirectory.promptbehavior.aspx
        # Change the prompt behaviour to force credentials each time: Auto, Always, Never, RefreshSession

        $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

        $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

            # If the accesstoken is valid then create the authentication header

            if($authResult.AccessToken){

            # Creating header for Authorization token

            $Global:authHeader = @{
                'Content-Type'='application/json'
                'Authorization'="Bearer " + $authResult.AccessToken
                'ExpiresOn'=$authResult.ExpiresOn
                }

            return $authHeader

            Write-Host "Authentication Token aquired" -ForegroundColor Cyan
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
    The function will check the for a vaid authentication token and refresh if it has expired. If not token is found the function with acquire a token
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

        if(!$Exportuser -or $Exportuser -eq ""){

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $EUtitle = 'Azure user account'
        $EUmsg   = 'To export the policies, please enter you Azure user account email address:'

        $Global:Exportuser = [Microsoft.VisualBasic.Interaction]::InputBox($EUmsg, $EUtitle)

        }

    # Getting the authorization token
    $global:authToken = Get-GraphAuthToken -User $Exportuser

    }
    }
function Remove-GrapAppLognin {
    param (

    )

    Clear-Variable authToken -Scope Global
    Clear-Variable authHeader -Scope Global
    Clear-Variable Exportuser -Scope Global
    Clear-Variable clientId -Scope Global
    Clear-Variable redirectUri -Scope Global

}

function Remove-GrapAppID {
    param (

    )

    Clear-Variable authToken -Scope Global
    Clear-Variable authHeader -Scope Global
    Clear-Variable clientId -Scope Global
    Clear-Variable redirectUri -Scope Global

}

Function Remove-GraphApp{

    <#
    .SYNOPSIS
    This function is used to force the user to authenticate
    .DESCRIPTION
    The function will clear all the variables used to aquire an authentication token
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

        Remove-GrapAppLognin
    }

    'No' {

        Remove-GrapAppID

    }

    'Cancel' {

        Write-Host "Application removal canceled" -ForegroundColor Red

    }

  }

}