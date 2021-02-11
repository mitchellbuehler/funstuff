If($PSVersionTable.PSVersion -lt [Version]"3.0")
{
    "TSE-Error: Sensor requires PSv3 or greater."
}
Else
{


    # Function to collect Chrome extensions
    Function Get-ChromeExtension 
    {
        # Set up array for output
        $Chrome_Extensions = @()
        
        # Loop through each user folder
        $User_Folders = Get-ChildItem -Path "C:\Users"
        ForEach ($User_Folder in $User_Folders) {

            # Check for existence of Chrome Extensions folder in user folder
            If(Test-Path -Path "$($User_Folder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Extensions")
            {

                # Loop through each extension folder
                $Ext_Folders = Get-ChildItem -Path "$($User_Folder.FullName)\AppData\Local\Google\Chrome\User Data\Default\Extensions"
                ForEach ($Ext_Folder in $Ext_Folders) {

                    #Loop through each version folder
                    $Ver_Folders = Get-ChildItem -Path "$($Ext_Folder.FullName)"
                    ForEach ($Ver_Folder in $Ver_Folders) {

                        # Check extension manifest for name
                        $AppID = $Ext_Folder.BaseName
                        $Ext_Name = ""

                        If( (Test-Path -Path "$($Ver_Folder.FullName)\manifest.json") ) 
                        {
                            Try 
                            {
                                $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\manifest.json" | ConvertFrom-Json
                                $Ext_Name = $Json.name
                                
                            } 
                            Catch 
                            {
                                $Ext_Name = ""
                            }
                        }

                        If( $Ext_Name -like "*MSG*" ) 
                        {
                            # Check the en locale folder
                            If( Test-Path -Path "$($Ver_Folder.FullName)\_locales\en\messages.json" ) 
                            {
                                Try 
                                { 
                                    $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\_locales\en\messages.json" | ConvertFrom-Json
                                    $Ext_Name = $Json.appName.message

                                    # Check various locations to get extension name
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.extName.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.extensionName.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.app_name.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.application_title.message
                                    }
                                } 
                                Catch 
                                { 
                                    # Reset extension name if not found
                                    $Ext_Name = ""
                                }
                            }

                            # Check the en_US locale folder
                            If( Test-Path -Path "$($Ver_Folder.FullName)\_locales\en_US\messages.json" ) 
                            {
                                Try 
                                {
                                    $Json = Get-Content -Raw -Path "$($Ver_Folder.FullName)\_locales\en_US\messages.json" | ConvertFrom-Json
                                    $Ext_Name = $Json.appName.message

                                    # Check various locations to get extension name
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.extName.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.extensionName.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.app_name.message
                                    }
                                    If( -not $Ext_Name ) 
                                    {
                                        $Ext_Name = $Json.application_title.message
                                    }
                                } 
                                Catch 
                                {
                                    # Reset extension name if not found
                                    $Ext_Name = ""
                                }
                            }

                        }

                        # If extension name still not found, use App ID
                        If( !$Ext_Name ) {
                            $Ext_Name = "$($AppID)"
                        }

                        # Add extension entry to object array
                        $Obj = New-Object psobject -Property @{
                            Name = $Ext_Name
                            Version = [String]$Ver_Folder
                        }
                        $Chrome_Extensions = $Chrome_Extensions + $Obj
                    }
                }
            }

            # Continue to new user if Chrome not found
            Else 
            { 
                Continue 
            }
        }

        # Format data in table, remove duplicates, and print output
        $Extensions = $Chrome_Extensions | Sort-Object Name | Select-Object Name, Version -Unique

        If ( $Extensions.Count -gt 0 )
        {
            ForEach ( $Extension in $Extensions ) {
                Write-Host "$($Extension.Name.Trim())|$($Extension.Version.Trim())"
            }
        }
        Else 
        {
            Write-Host "TSE-Error: No chrome extensions present."
        }
    }


    # Check to ensure that chrome is installed, call function if it is
    $ChromeInstall64 = "C:\Program Files\Google\Chrome"
    $ChromeInstall86 = "C:\Program Files (x86)\Google\Chrome"
    If( ( Test-Path -Path $ChromeInstall64 ) -or ( Test-Path -Path $ChromeInstall86 ) )
    {
        Get-ChromeExtension
    }
    Else
    {
        Write-Host "TSE-Error: Chrome is not installed."
    }
}
