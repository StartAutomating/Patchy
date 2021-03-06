function Test-UpdateRebootRequired
{
    <#
    .Synopsis
        Determines a reboot is required
    .Description
        Determines if a reboot is required after applying an update.
    .Link
        Install-WindowsUpdate
    #>
    param()
        
    end {
        (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired
    }
} 
