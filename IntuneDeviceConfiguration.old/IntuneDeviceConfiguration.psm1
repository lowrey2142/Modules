<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

Function Get-DeviceConfigurationPolicy(){

    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-DeviceConfigurationPolicy
    #>

    [cmdletbinding()]

    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"

        try {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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

Function Export-JSONData(){

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

            if(!$JSON -or $JSON -eq ""){

            write-host "No JSON specified, please specify valid JSON..." -f Red

            }

            elseif(!$ExportPath){

            write-host "No export path parameter set, please provide a path to export the file" -f Red

            }

            elseif(!(Test-Path $ExportPath)){

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

                    foreach($Property in $Properties){

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

function New-DeviceConfigExportPath {
    param (

    )

    if(!$DevConfExportPath -or $DevConfExportPath -eq ""){

        Write-Host "Confirm export directory" -ForegroundColor Yellow

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $DevConfigtitle = 'Export Directory'
        $DevConfigmsg   = 'Please confrim the export directory:'

        $Global:DevConfExportPath = [Microsoft.VisualBasic.Interaction]::InputBox($DevConfigmsg, $DevConfigtitle)
    }
        # If the directory path doesn't exist prompt user to create the directory
        $DevConfExportPath = $DevConfExportPath.replace('"','')

        if(!(Test-Path "$DevConfExportPath")){

        Write-Host
        Write-Host "Path '$DevConfExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow

        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            new-item -ItemType Directory -Path "$DevConfExportPath" | Out-Null -Verbose
            Write-Host

            }

            else {

            Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
            Write-Host
            break

            }

        }

        else {
            $DevConfExportPath = "C:\Temp\Intune\Devconf"
            $CDate = (Get-Date -Format dd-MM-yy)
            $Backuplocation = "$DevConfExportPath\$CDate"

            IF(!(Test-Path -Path $Backuplocation)){

                New-Item -Path "$Backuplocation" -ItemType Directory

            }
            Else{
            Get-ChildItem -Path "$DevConfExportPath" -Recurse | Move-Item -Destination "$Backuplocation" -ErrorAction SilentlyContinue
            }

            Write-Host "Setting $DevConfExportPath as export directory..." -f Yellow
        }
}

function Save-DeviceConfigPolices {
    param (

    )

    New-DeviceConfigExportPath

    Write-Host "Saving the exported files to: $DevConfExportPath"

    New-GraphAuthToken

    $DCPs = Get-DeviceConfigurationPolicy

    foreach($DCP in $DCPs){

    write-host "Device Configuration Policy:"$DCP.displayName -f Yellow
    Export-JSONData -JSON $DCP -ExportPath "$DevConfExportPath"
    Write-Host
    }
}