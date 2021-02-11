If($PSVersionTable.PSVersion -lt [Version]"3.0")
{
    'TSE-Error: Sensor requires PSv3 or greater.'
}
Else
{
	# Function to collect Chrome extensions
	Function Get-ChromeExtension 
    {
        # Set up empty arrays for output
        $Extension_Names = @()
        $Extension_Versions = @()
        $Chrome_Extensions = @()
        
        # Loop through each user folder
        $User_Folders = Get-ChildItem -Path "C:\Users"
        ForEach ($User_Folder in $User_Folders) {
            # Check for existence of Chrome Extensions folder in user folder
            if(Test-Path -Path "$($User_Folder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Extensions")
            {
                # Loop through each extension folder
                $Ext_Folders = Get-ChildItem -Path "$($User_Folder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Extensions"
                ForEach ($Ext_Folder in $Ext_Folders) {
                    #Loop through each version folder
                    $Ver_Folders = Get-ChildItem -Path "$($Ext_Folder.FullName)"
                    ForEach ($Ver_Folder in $Ver_Folders) {
                        $AppID = $Ext_Folder.BaseName
                        $Ext_Name = ""
                        # Check extension manifest for name
                        if( (Test-Path -Path "$($Ver_Folder.FullName)\manifest.json") ) 
                        {
                            
                            try 
                            {
                                $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\manifest.json" | ConvertFrom-Json
                                $Ext_Name = $Json.name
                                
                            } 
                            catch 
                            {
                                #$_
                                $Ext_Name = ""
                            }
                        }

                        if( $Ext_Name -like "*MSG*" ) 
                        {
                            # Check the en locale folder
                            if( Test-Path -Path "$($Ver_Folder.FullName)\_locales\en\messages.json" ) 
                            {
                                try 
                                { 
                                    $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\_locales\en\messages.json" | ConvertFrom-Json
                                    $Ext_Name = $Json.appName.message
                                    # Check various locations to get extension name
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.extName.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.extensionName.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.app_name.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.application_title.message
                                    }
                                } 
                                catch 
                                { 
                                    #$_
                                    $name = ""
                                }
                            }
                            # check en_US local folder
                            if( Test-Path -Path "$($Ver_Folder.FullName)\_locales\en_US\messages.json" ) 
                            {
                                try 
                                {
                                    $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\_locales\en_US\messages.json" | ConvertFrom-Json
                                    $Ext_Name = $Json.appName.message
                                    # Check various locations to get extension name
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.extName.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.extensionName.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.app_name.message
                                    }
                                    if(!$Ext_Name) 
                                    {
                                        $Ext_Name = $Json.application_title.message
                                    }
                                } 
                                catch 
                                {
                                    #$_
                                    $Ext_Name = ""
                                }
                            }

                        }

                        # If extension name still not found, use App ID
                        if( !$Ext_Name ) {
                            $Ext_Name = "[$($AppID)]"
                        }
                        $obj = New-Object psobject -Property @{
                            Name = $Ext_Name
                            Version = [String]$Ver_Folder
                        }

                        $Chrome_Extensions = $Chrome_Extensions + $obj
                        <#
                        $Extension_Names = $Extension_Names + "$Ext_Name"
                        $Extension_Versions = $Extension_Versions + "($($Ver_Folder))"

                        Write-Host $Ext_Name, $Ver_Folder
                        #>
                    }
                }
            }
            else { continue }
        }

        # Format data in table and return to script
        $Chrome_Extensions | Sort-Object Name | Select-Object Name, Version -Unique
	}

	# Check to ensure that chrome is installed
	$ChromeInstall64 = "C:\Program Files\Google\Chrome"
	$ChromeInstall86 = "C:\Program Files (x86)\Google\Chrome"

	If(-not ((Test-Path -Path $ChromeInstall64) -or (Test-Path -Path $ChromeInstall86)))
    {
		Write-Host "TSE-Error: Chrome is not installed."
	}
	Else
	{
		# Call function to get Chrome extensions
        #Get-ChromeExtension
	    $Extensions = Get-ChromeExtension

        If ($Extensions.Count -gt 0)
        {
            ForEach ($Extension in $Extensions) {
                Write-Host "$($Extension.Name.Trim())|$($Extension.Version.Trim())"
            }
        }
        Else 
        {
		    Write-Host "TSE-Error: No chrome extensions present."
	    }
        
	}
}