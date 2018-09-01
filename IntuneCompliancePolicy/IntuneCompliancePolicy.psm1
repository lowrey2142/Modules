<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>
Import-Module GraphAuth
Function Get-DeviceCompliancePolicy() {

    <#
    .SYNOPSIS
    This function is used to get device compliance policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device compliance policies
    .EXAMPLE
    Get-DeviceCompliancePolicy
    Returns any device compliance policies configured in Intune
    .EXAMPLE
    Get-DeviceCompliancePolicy -Android
    Returns any device compliance policies for Android configured in Intune
    .EXAMPLE
    Get-DeviceCompliancePolicy -iOS
    Returns any device compliance policies for iOS configured in Intune
    .NOTES
    NAME: Get-DeviceCompliancePolicy
    #>
    
    [cmdletbinding()]
    
    param
    (
        [switch]$Android,
        [switch]$iOS,
        [switch]$Win10
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceCompliancePolicies"
        
    try {
    
        $Count_Params = 0
    
        if ($Android.IsPresent) { $Count_Params++ }
        if ($iOS.IsPresent) { $Count_Params++ }
        if ($Win10.IsPresent) { $Count_Params++ }
    
        if ($Count_Params -gt 1) {
            
            write-host "Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function" -f Red
            
        }
            
        elseif ($Android) {
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("android") }
            
        }
            
        elseif ($iOS) {
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ios") }
            
        }
    
        elseif ($Win10) {
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") }
            
        }
            
        else {
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
        }
    
    }
        
    catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
    }
    
}

function New-DeviceCompExportPath {
    param (

    )

    if (!$DevCompExportPath -or $DevCompExportPath -eq "") {

        Write-Host "Confirm export directory" -ForegroundColor Yellow

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $DevConfigtitle = 'Export Directory'
        $DevConfigmsg = 'Please confirm the export directory:'

        $Global:DevCompExportPath = [Microsoft.VisualBasic.Interaction]::InputBox($DevConfigmsg, $DevConfigtitle)
    }
    # If the directory path doesn't exist prompt user to create the directory
    $DevCompExportPath = $DevCompExportPath.replace('"', '')

    if (!(Test-Path "$DevCompExportPath")) {

        Write-Host
        Write-Host "Path '$DevCompExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow

        $Confirm = read-host

        if ($Confirm -eq "y" -or $Confirm -eq "Y") {

            new-item -ItemType Directory -Path "$DevCompExportPath" | Out-Null -Verbose
            Write-Host

        }

        else {

            Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
            Write-Host
            break

        }

    }

    else {
        $DevCompExportPath = "C:\Temp\Intune\Devcomp"
        $CDate = (Get-Date -Format dd-MM-yy)
        $Backuplocation = "$DevCompExportPath\$CDate"

        IF (!(Test-Path -Path $Backuplocation)) {

            New-Item -Path "$Backuplocation" -ItemType Directory
            Get-ChildItem -Path "$DevCompExportPath" -Recurse | Move-Item -Destination "$Backuplocation" -ErrorAction SilentlyContinue
        }
        Else {
            Get-ChildItem -Path "$DevCompExportPath" -Recurse | Move-Item -Destination "$Backuplocation" -ErrorAction SilentlyContinue
        }

        Write-Host "Setting $DevCompExportPath as export directory..." -f Yellow
    }
}

function Save-DeviceCompPolices {

    New-DeviceCompExportPath

    Write-Host "Saving the exported files to: $DevCompExportPath"

    New-GraphAuthToken

    $CPs = Get-DeviceCompliancePolicy

    foreach($CP in $CPs){

    write-host "Device Compliance Policy:"$CP.displayName -f Yellow
    Export-JSONData -JSON $CP -ExportPath "$DevCompExportPath"
    Write-Host

    }

}