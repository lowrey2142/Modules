<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>
#Import Graph authentication module
Import-Module GraphAuth

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

Function Add-DeviceConfigurationPolicy(){

        <#
        .SYNOPSIS
        This function is used to add an device configuration policy using the Graph API REST interface
        .DESCRIPTION
        The function connects to the Graph API Interface and adds a device configuration policy
        .EXAMPLE
        Add-DeviceConfigurationPolicy -JSON $JSON
        Adds a device configuration policy in Intune
        .NOTES
        NAME: Add-DeviceConfigurationPolicy
        #>
        
        [cmdletbinding()]
        
        param
        (
            $JSON
        )
        
        $graphApiVersion = "Beta"
        $DCP_resource = "deviceManagement/deviceConfigurations"
        Write-Verbose "Resource: $DCP_resource"
        
            try {
        
                if(!$JSON -or $JSON -eq ""){
        
                write-host "No JSON specified, please specify valid JSON for the Device Configuration Policy..." -f Red
        
                }
        
                else {
        
                Test-JSON -JSON $JSON
        
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        
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

Function Test-JSON(){

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
        
            if (!$validJson){
            
            Write-Host "Provided JSON isn't in valid JSON format" -f Red
            break
        
            }
        
        }

function New-DeviceConfigExportPath {
    param (

    )

    if(!$DevConfExportPath -or $DevConfExportPath -eq ""){

        Write-Host "Confirm export directory" -ForegroundColor Yellow

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $DevConfigtitle = 'Export Directory'
        $DevConfigmsg   = 'Please confirm the export directory:'

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
            
            $CDate = (Get-Date -Format dd-MM-yy)
            $Backuplocation = "$DevConfExportPath\$CDate"

            IF(!(Test-Path -Path $Backuplocation)){

                New-Item -Path "$Backuplocation" -ItemType Directory
                Get-ChildItem -Path "$DevConfExportPath" -Recurse | Move-Item -Destination "$Backuplocation" -ErrorAction SilentlyContinue
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

function Import-DeviceConfigPolices{
    
    #Select a Json file list
    if(!$JSONDirectory -or $JSONDirectory -eq ""){
        Write-Host "Confirm import directory..." -ForegroundColor Yellow

        [void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

        $DevConfigtitle = 'Device Config JSON Directory'
        $DevConfigmsg   = 'Please confirm the import directory:'

        $Global:JSONDirectory = [Microsoft.VisualBasic.Interaction]::InputBox($DevConfigmsg, $DevConfigtitle)
    }
    
    $JASONFiles = (Get-ChildItem -Path $JSONDirectory -Filter "*.json").FullName

    Write-Host "Number of polices found: " $JASONFiles.count
    $JASONFiles
    if(!$JASONFiles){
    
        Write-Host "No JSON files found..." -ForegroundColor Red
        Write-Host "Script can't continue..." -ForegroundColor Red
        Write-Host
        break
        
        }
    else {
        Remove-GraphAppLogin
        Write-Host "Please confirm the import tenant details" -f Yellow
        New-GraphAuthToken
        foreach($ImportPath in $JASONFiles){
        
            $ImportPath = $ImportPath.replace('"','')
                    
            $JSON_Data = Get-Content "$ImportPath"
            
            # Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
            $JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version
            
            $DisplayName = $JSON_Convert.displayName
            
            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
                        
            write-host
            write-host "Device Configuration Policy '$DisplayName' Found..." -ForegroundColor Yellow
            write-host
            $JSON_Output
            write-host
            Write-Host "Adding Device Configuration Policy '$DisplayName'" -ForegroundColor Yellow
            #Add-DeviceConfigurationPolicy -JSON $JSON_Output
        }
    }
}