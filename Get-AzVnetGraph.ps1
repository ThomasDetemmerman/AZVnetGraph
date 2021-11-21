    
    
    
    function addQuotes($array){
        for($i=0; $i -lt $array.Length; $i++){
            $j = $array[$i]
            $array[$i] = "`"$j`""
        }
    }

    function convertToDotLanguage ($nodes)
    {
        $sb = [System.Text.StringBuilder]::new()
        [void]$sb.Append( 'digraph G {' )
        foreach ($node in $nodes)
        {
            $source = $node.Name
            $dest = $node.Remotes
            addQuotes($dest)
            $dest = [String]::Join(' ',$dest)
            [void]$sb.AppendLine( "`"$source`" -> { $dest }"  )
        }
        [void]$sb.Append( '}' )
        
        $sb.ToString()
    }

    function Invoke-URLInDefaultBrowser
    {
        <#
            .SYNOPSIS
                Cmdlet to open a URL in the User's default browser.
            .DESCRIPTION
                Cmdlet to open a URL in the User's default browser.
            .PARAMETER URL
                Specify the URL to be Opened.
            .EXAMPLE
                PS> Invoke-URLInDefaultBrowser -URL 'http://jkdba.com'
                
                This will open the website "jkdba.com" in the user's default browser.
            .NOTES
                This cmdlet has only been test on Windows 10, using edge, chrome, and firefox as default browsers.
        #>
        [CmdletBinding()]
        param
        (
            [Parameter(
                Position = 0,
                Mandatory = $true
            )]
            [ValidateNotNullOrEmpty()]
            [String] $URL
        )
        #Verify Format. Do not want to assume http or https so throw warning.
        if( $URL -notmatch "http://*" -and $URL -notmatch "https://*")
        {
            Write-Warning -Message "The URL Specified is formatted incorrectly: ($URL)"
            Write-Warning -Message "Please make sure to include the URL Protocol (http:// or https://)"
            break;
        }
        #Replace spaces with encoded space
        $URL = $URL -replace ' ','%20'
        
        #Get Default browser
        $DefaultSettingPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
        $DefaultBrowserName = (Get-Item $DefaultSettingPath | Get-ItemProperty).ProgId
        
        #Handle for Edge
        ##edge will no open with the specified shell open command in the HKCR.
        if($DefaultBrowserName -eq 'AppXq0fevzme2pys62n3e0fbqa7peapykr8v')
        {
            #Open url in edge
            start Microsoft-edge:$URL
        }
        else
        {
            try
            {
                #Create PSDrive to HKEY_CLASSES_ROOT
                $null = New-PSDrive -PSProvider registry -Root 'HKEY_CLASSES_ROOT' -Name 'HKCR'
                #Get the default browser executable command/path
                $DefaultBrowserOpenCommand = (Get-Item "HKCR:\$DefaultBrowserName\shell\open\command" | Get-ItemProperty).'(default)'
                $DefaultBrowserPath = [regex]::Match($DefaultBrowserOpenCommand,'\".+?\"')
                #Open URL in browser
                Start-Process -FilePath $DefaultBrowserPath -ArgumentList $URL  
            }
            catch
            {
                Throw $_.Exception
            }
            finally
            {
                #Clean up PSDrive for 'HKEY_CLASSES_ROOT
                Remove-PSDrive -Name 'HKCR'
            }
        }
    }

    function get-AzVnetGraph 
    {
       
        [CmdletBinding()]
        param
        (
            [Parameter(
                Mandatory = $true
            )]
            [ValidateNotNullOrEmpty()]
            [String] $TenantId
        )
    
    $baseURL = "https://dreampuf.github.io/GraphvizOnline/#"
    $nodes = @()
    
    $subarr = Get-AzSubscription -TenantId $TenantId
    foreach ($sub in $subarr)
    {
        Set-AzContext -Subscription $sub | out-null
        $vnets = Get-AzVirtualNetwork
        foreach($vnet in $vnets){
        $name = $vnet.name
        $remotevnets = $vnet.virtualNetworkPeerings.RemoteVirtualnetwork.id
        $remotevnetnames = @()
        foreach($remotevnet in $remotevnets){
            $remotevnetname =  $($remotevnet -split "/")[-1]
            $remotevnetnames += $remotevnetname
        }
        
        
        $node = [PSCustomObject]@{
                Name     = $name
                Remotes = $remotevnetnames
        }
        $nodes += $node
        }

    }


    $dotcode = convertToDotLanguage($nodes)
    $URI = "$baseURL$dotcode"
    $URI = [uri]::EscapeUriString($URI)

    Invoke-URLInDefaultBrowser -URL $URI
}