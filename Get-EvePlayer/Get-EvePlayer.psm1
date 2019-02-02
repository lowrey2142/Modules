
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

            #Get players alliacne
            Get-AlliancePublicData -Org 'alliances' -corpID "$AID"
			$AName = $PlayerAlliance.name
            $PlayerPublicData | Add-Member -NotePropertyName 'alliance_name' -NotePropertyValue "$AName"
            
            #Creat Alliance image url
            $AImageUrl = "https://imageserver.eveonline.com/Alliance/$AID"+"_128.png"
            $PlayerPublicData | Add-Member -NotePropertyName 'alliance_image_url' -NotePropertyValue "$AImageUrl"

            #Get players corporation
			Get-AlliancePublicData -Org 'corporations' -corpID "$CID"
			$CName = $PlayerAlliance.name
            $PlayerPublicData | Add-Member -NotePropertyName 'corporation_name' -NotePropertyValue "$CName"
            
            #Creat corporation image url
            $CImageUrl = "https://imageserver.eveonline.com/Corporation/$CID"+"_256.png"
            $PlayerPublicData | Add-Member -NotePropertyName 'corporation_image_url' -NotePropertyValue "$CImageUrl"

		}
		Else{
			
			Get-AlliancePublicData -Org 'corporations' -corpID "$CID"
			$CName = $PlayerAlliance.name
            $PlayerPublicData | Add-Member -NotePropertyName 'corporation_name' -NotePropertyValue "$CName"
            
            #Creat corporation image url
            $CImageUrl = "https://imageserver.eveonline.com/Corporation/$CID"+"_256.png"
            $PlayerPublicData | Add-Member -NotePropertyName 'corporation_image_url' -NotePropertyValue "$CImageUrl"
	
    }
    
    #Creat Player image url
    $PlayerImageUrl = "https://image.eveonline.com/Character/$player"+"_256.jpg"
    $PlayerPublicData | Add-Member -NotePropertyName 'player_image_url' -NotePropertyValue "$PlayerImageUrl"
			  
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