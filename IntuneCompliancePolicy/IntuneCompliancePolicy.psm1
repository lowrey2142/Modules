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

Function Export-JSONData() {

    <#
    .SYNOPSIS
    This function is used to export JSON data returned from Graph
    .DESCRIPTION
    This function is used to export JSON data returned from Graph
    .EXAMPLE
    Export-JSONData -JSON $JSON
    Export the JSON inputted on the function
    .NOTES
    NAME: Export-JSONData
    #>

    param (

        $JSON,
        $ExportPath

    )

    try {

        if (!$JSON -or $JSON -eq "") {

            write-host "No JSON specified, please specify valid JSON..." -f Red

        }

        elseif (!$DevConfExportPath) {

            write-host "No export path parameter set, please provide a path to export the file" -f Red

        }

        elseif (!(Test-Path $ExportPath)) {

            write-host "$ExportPath doesn't exist, can't export JSON Data" -f Red

        }

        else {

            $JSON1 = ConvertTo-Json $JSON -Depth 5

            $JSON_Convert = $JSON1 | ConvertFrom-Json

            $displayName = $JSON_Convert.displayName

            # Updating display name to follow file naming conventions - https://msdn.microsoft.com/en-us/library/windows/desktop/aa365247%28v=vs.85%29.aspx
            $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"

            $Properties = ($JSON_Convert | Get-Member | Where-Object { $_.MemberType -eq "NoteProperty" }).Name

            $FileName_CSV = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".csv"
            $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"

            $Object = New-Object System.Object

            foreach ($Property in $Properties) {

                $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property

            }

            write-host "Export Path:" "$ExportPath"

            $Object | Export-Csv -LiteralPath "$ExportPath\$FileName_CSV" -Delimiter "," -NoTypeInformation -Append
            $JSON1 | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
            write-host "CSV created in $ExportPath\$FileName_CSV..." -f cyan
            write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan

        }

    }

    catch {

        $_.Exception

    }

}

Function Test-JSON() {

    <#
        .SYNOPSIS
        This function is used to test if the JSON passed to a REST Post request is valid
        .DESCRIPTION
        The function tests if the JSON passed to the REST Post is valid
        .EXAMPLE
        Test-JSON -JSON $JSON
        Test if the JSON is valid before calling the Graph REST interface
        .NOTES
        NAME: Test-AuthHeader
        #>
        
    param (
        
        $JSON
        
    )
        
    try {
        
        $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
        $validJson = $true
        
    }
        
    catch {
        
        $validJson = $false
        $_.Exception
        
    }
        
    if (!$validJson) {
            
        Write-Host "Provided JSON isn't in valid JSON format" -f Red
        break
        
    }
        
}

function Save-DeviceCompPolices {

    New-DeviceCompExportPath

    Write-Host "Saving the exported files to: $DevCompExportPath"

    New-GraphAuthToken

    $CPs = Get-DeviceCompliancePolicy

    foreach ($CP in $CPs) {

        write-host "Device Compliance Policy:"$CP.displayName -f Yellow
        Export-JSONData -JSON $CP -ExportPath "$DevCompExportPath"
        Write-Host

    }

}