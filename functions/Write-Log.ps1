<#
.Synopsis
   Used to format log message.
.DESCRIPTION
   Will format into log text, component, date and time. This works great with trace32.
.EXAMPLE
   Write-FolderLog -Message 'simple activity'
   Write-FolderLog -Message 'warning' -LogLevel 2
   Write-FolderLog -Message 'Error' -LogLevel 3
.NOTES
   Written by Adam Bertram
   https://www.adamtheautomator.com/building-logs-for-cmtrace-powershell/
#>
function Write-Log
{
    [CmdletBinding()]
    param (
    [Parameter(Mandatory = $true)]
    [string]$Message,
		
    [Parameter()]
    [ValidateSet(1, 2, 3)]
    [int]$LogLevel = 1
    )
    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
    $Line = $Line -f $LineFormat
    Add-Content -Value $Line -Path $ScriptLogFilePath
}

