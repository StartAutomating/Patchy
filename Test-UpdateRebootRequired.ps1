function Test-UpdateRebootRequired
{
    param()
        
    end {
        (New-Object -ComObject "Microsoft.Update.SystemInfo").RebootRequired
    }
} 
