<#
.Synopsis
   This function will create a logfile.
.DESCRIPTION
   It will check the directory and then create a logfile.
.EXAMPLE
   Start-Log -Log "c:\dest"
.NOTES
   Written by Adam Bertram
   https://www.adamtheautomator.com/building-logs-for-cmtrace-powershell/
#>
function Start-Log
{
    [CmdletBinding()]
    [Alias()]
    param (
        [ValidateScript({ Split-Path $_ -Parent | Test-Path })]
        [string]$Log
    )

    try
    {
        if (!(Test-Path $Log))
	{
	    ## Create the log file
	    New-Item $Log -Type File | Out-Null
	}
		
	## Set the global variable to be used as the FilePath for all subsequent Write-Log
	## calls in this session
	$global:ScriptLogFilePath = $Log
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

}