
#EVE ESI REST URi.
$Global:Url = "https://esi.evetech.net/latest"
#$Player= '1778645394'

Function Get-PlayerPublicData{

	[cmdletbinding()]
	Param (

		[parameter(Mandatory=$true)]
		[string]
		$Player
	) 
	# End of Parameters

Process {
			   
$RESTParams = @{

			datasource = 'tranquility';
			
		}

		#Gets basic public data from ESI
		
		$Global:PlayerPublicData = Invoke-WebRequest -Uri "$Url/characters/$Player" -Method Get -Body $RESTParams | ConvertFrom-Json
		$AID = $PlayerPublicData.alliance_id
		$CID = $PlayerPublicData.corporation_id

		If ($AID){

			Get-AlliancePublicData -Org 'alliances' -corpID "$AID"
			$AName = $PlayerAlliance.name
			$PlayerPublicData | Add-Member -NotePropertyName 'alliance_name' -NotePropertyValue "$AName"

			Get-AlliancePublicData -Org 'corporations' -corpID "$CID"
			$CName = $PlayerAlliance.name
			$PlayerPublicData | Add-Member -NotePropertyName 'corporation_name' -NotePropertyValue "$CName"

			#$PlayerPublicData
		}
		Else{
			
			Get-AlliancePublicData -Org 'corporations' -corpID "$CID"
			$CName = $PlayerAlliance.name
			$PlayerPublicData | Add-Member -NotePropertyName 'corporation_name' -NotePropertyValue "$CName"

			#$PlayerPublicData
		
	}
			  
  } # End of Process
}

Function Get-AlliancePublicData{

	[cmdletbinding()]
	Param (
		
		[parameter(Mandatory=$true)]
		[string]
		$Org,

		[parameter(Mandatory=$true)]
		[string]
		$corpID
	) 
	# End of Parameters

Process {
			   
$RESTParams = @{

			datasource = 'tranquility';
			
		}

		#Gets basic public data from ESI
		
		$Global:PlayerAlliance = Invoke-WebRequest -Uri "$Url/$Org/$corpID" -Method Get -Body $RESTParams | ConvertFrom-Json
			  
  } # End of Process
}