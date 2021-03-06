function Install-WindowsUpdate
{
    <#
    .Synopsis
        Installs windows updates
    .Description
        Installs windows updates discovered with Find-WindowsUpdate 
    .Example
        Find-WindowsUpdate -Recommended |
            Install-WindowsUpdate
    .Link
        Find-WindowsUpdate
    #>
    [CmdletBinding(DefaultParameterSetName='UpdateName')]
    param(
    # The update object
    [Parameter(ValueFromPipeline=$true,
        Mandatory=$true,
        ParameterSetName='UpdateObject')]
    [ValidateScript({
        if ($_.pstypenames -notcontains 'System.__ComObject#{c1c2f21a-d2f4-4902-b5c6-8a081c19a890}') {
            throw "Not a windows update"
        }
        return $true
    })]
    $UpdateObject,
    
    # If set, will automatically reboot if an update requires it.
    [Switch]
    $Force
    )
 
    begin {
        $objCollection = New-Object -ComObject "Microsoft.Update.UpdateColl"
        $objServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
        $objSession = New-Object -ComObject "Microsoft.Update.Session"

    }   
    
    process {
        if ($psCmdlet.ParameterSetName -eq 'UpdateObject') {
            $UpdateObject.AcceptEula()
            $null = $objCollection.Add($UpdateObject)            
        }         
    }
    
    end {
        $objCollection2 = New-Object -ComObject "Microsoft.Update.UpdateColl"
	    foreach($Update in $objCollection)
	    {   
	        $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
	        $null = $objCollectionTmp.Add($Update) 
	            
	        $Downloader = $objSession.CreateUpdateDownloader() 
	        $Downloader.Updates = $objCollectionTmp
	        try {
	            $DownloadResult = $Downloader.Download()
	        } Catch {
                if($_ -match "HRESULT: 0x80240044") {
	                Write-Error "Must be an administrator"
	            }
	            return
	        } 
	        
	        switch -exact ($DownloadResult.ResultCode)
	        {
	            0   { $Status = "NotStarted"}
	            1   { $Status = "InProgress"}
	            2   { $Status = "Downloaded"}
	            3   { $Status = "DownloadedWithErrors"}
	            4   { $Status = "Failed"}
	            5   { $Status = "Aborted"}
	        }
	                
	        $log = New-Object psobject
	                        
	        if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
	        $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,2)
	                        
			$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
			$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
			$log | Add-Member -MemberType NoteProperty -Name Size -Value $size
			$log | Add-Member -MemberType NoteProperty -Name Status -Value $Status
	        
	        $log | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
	                
	        if($DownloadResult.ResultCode -eq 2)
	        {
	            $objCollection2.Add($Update) | out-null
	        }
            
            $objCollectionTmp = New-Object -ComObject "Microsoft.Update.UpdateColl"
	        $null = $objCollectionTmp.Add($Update) 
	                                
            $objInstaller = $objSession.CreateUpdateInstaller()
            $objInstaller.Updates = $objCollectionTmp
	                
	        try {                
                $InstallResult = $objInstaller.Install()
            } Catch {
                if($_ -match "HRESULT: 0x80240044") {
                    Write-Error "Must be an administrator"	                
	                return
	            }
	             
            }       
	        
            if(!$needsReboot)  { 
                $needsReboot = $installResult.RebootRequired 
            }  
            
            if ($needsReboot) { break } 
	                     
            switch -exact ($InstallResult.ResultCode) {
	           0   { $Status = "NotStarted"}
	           1   { $Status = "InProgress"}
	           2   { $Status = "Installed"}
	           3   { $Status = "InstalledWithErrors"}
	           4   { $Status = "Failed"}
	           5   { $Status = "Aborted"}
	        }
	           
	        $log = New-Object psobject 
	                        
	        if($Update.KBArticleIDs -ne "")    {$KB = "KB"+$Update.KBArticleIDs} else {$KB = ""}
	        $size = [System.Math]::Round($Update.MaxDownloadSize/1MB,2)
	                        
			$log | Add-Member -MemberType NoteProperty -Name Title -Value $Update.Title
			$log | Add-Member -MemberType NoteProperty -Name KB -Value $KB
			$log | Add-Member -MemberType NoteProperty -Name Size -Value $size
            $log | Add-Member -MemberType NoteProperty -Name Status -Value $Status
				
            $log | Select-Object  Title, KB, @{e={$_.Size};n='Size [MB]'}, Status 
	    }
                
        if($needsReboot) {
            if($Force) {
                Restart-Computer -Force
            } else {
                Write-Error "Reboot required"
                return                
			}	
        }
    }
}
 
