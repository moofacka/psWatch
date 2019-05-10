<#
.SYNOPSIS
    Continuously monitors a directory tree and write to the output the path of the file that has changed.
.DESCRIPTION
    This powershell cmdlet continuously monitors a directory tree and write to the output the path of the file that has changed.
	Can run to copy changes to a new location. All events will also be logged.

.Parameter $Folder
    The Folder that you want to monitor. Default is the current working directory.
.Parameter $Filter
    What filter to be used for the monitoring. Default is wildcard for everything. Could be specified in string like "important.txt".
.Parameter $Destination
    Destination folder for the captured changes. Default is not configured.
.Parameter $LogFile
    Log file name for all the output.
.Parameter $includeSubdirectories
    Recursively searches subfolders as well. Turned off by default.
.Parameter $includeChanged
    Includes change events. Default setting.
.Parameter $includeRenamed
    Includes rename events. Default setting.
.Parameter $includeCreated
    Includes create events. Default setting.
.Parameter $includeDeleted
    Includes delete events. Turned off by default.

.Link
    Original Project
    https://github.com/jfromaniello/pswatch/
    This fork
    https://github.com/moofacka/psWatch

.EXAMPLE
    Import-Module psWatch

.EXAMPLE
    Watch-FSFolder -Folder C:\Watch -Filter "*.txt" -includeSubdirectories
    Monitors C:\Watch and all it's subfolders for events to

.EXAMPLE
    Watch-FSFolder -includeDeleted
    Monitors all events in the current directory and logs to the same directory.

.EXAMPLE
    Watch-FSFolder -Folder C:\Watch -Filter "*.txt" -Destination C:\Destination -LogFile psWatch.log
    Monitors C:\Watch for events to *.txt files and copies changed files to C:\Destination and logs all to psWatch.log in C:\Destination.
.NOTES
    Version:        2.0
    Author:         Mats Tegbjer
    Creation Date:  2019-05-08
        
#>
function Watch-FSFolder
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
    [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateScript({
            if(!($_ | Test-Path) ){
                throw "Path does not exist"
            }
            if(!(Test-Path -Path $_ -PathType Container))
            {
                throw "Argument is a file. Only folders are allowed."
            }
            return $true
              })]
        [string]$Folder = (Get-Location),

        [Parameter(Mandatory=$false,
                   Position=1)]
        [string]$Filter = '*.*',

        [Parameter(Mandatory=$false,
                   Position=2)]
        [ValidateScript({ 
            if(!($_ | Test-Path) ){
                throw "Path does not exist"
            }
            if(!(Test-Path -Path $_ -PathType Container))
            {
                throw "Argument is a file. Only folders are allowed."
            }
            return $true
              })]
        [string]$Destination,

        [Parameter(Mandatory=$false,
                   Position=3)]
        [string]$LogFile = "Watch-Folder.csv",

        [switch]$IncludeSubdirectories = $false,
        [switch]$includeChanged = $true,
        [switch]$includeRenamed = $true,
        [switch]$includeCreated = $true,
        [switch]$includeDeleted = $false

    )
		   
    Begin
    {
        if(!$Destination)
        {
            $LogFile = Join-Path -Path $Folder -ChildPath $LogFile
            Start-FSLog -Log $LogFile
        }
        else
        {
            Start-FSLog -Log (Join-Path -Path $Destination -ChildPath $LogFile)
        }
        Write-FSLog -Message "The log file was created at '$ScriptLogFilePath'" -Severity Information 
        Write-FSLog -Message "Started monitoring of folder '$Folder'" -Severity Information
        $fsw = New-Object System.IO.FileSystemWatcher
	    $fsw.Path = $Folder
        $fsw.Filter = $Filter
	    $fsw.IncludeSubdirectories = $includeSubdirectories
	    $fsw.EnableRaisingEvents = $false
	    $fsw.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName
	
	    $conditions = 0
	    if($includeChanged)
        {
		    $conditions = [System.IO.WatcherChangeTypes]::Changed 
	    }

	    if($includeRenamed)
        {
		    $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Renamed
	    }

	    if($includeCreated)
        {
		    $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Created 
	    }

	    if($includeDeleted)
        {
		    $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Deleted
	    }
    }
    Process
    {
	    while($true){
		    $Event = $fsw.WaitForChanged($conditions, 1000);
		    if($Event.TimedOut){
                continue;
		    }
		    $Timestamp = Get-Date -UFormat '+%Y-%m-%dT%H%M%SZ'
            $SourceName = $Event.Name
            $SourceOldName = $Event.OldName
            $SourceFullPath = [System.IO.Path]::Combine($Folder, $SourceName)
            [string]$ChangeType = $Event.ChangeType
            $ChangeType = $ChangeType.ToLower()
            
            try
            {
                switch ($Event.ChangeType)
                {
                    'Changed'
                    {
                        if(!$Destination)
                        {
                            Write-FSLog -Message "'$SourceName' was $ChangeType."  -Severity Information 
                            break;
                        }
                        $DestinationName = $Timestamp + "-" + $SourceName
                        $DestinationFullPath = [System.IO.Path]::Combine($Destination, $DestinationName)
                        $LastWrite = Get-ChildItem $Destination -Recurse -Filter "*$SourceName" -Exclude $LogFile | sort LastWriteTime | select -last 1
                        if (!$LastWrite)
                        {
                        }
                        elseif(!(Compare-Object -ReferenceObject @($(Get-Content $LastWrite)) -DifferenceObject @($(Get-Content $SourceFullPath)) ) )
                        {
                            Throw "E001"
                        }
                        Copy-Item -Path $SourceFullPath -Destination $DestinationFullPath
                        Write-FSLog -Message "'$SourceName' was $ChangeType. File was captured to $DestinationFullPath"  -Severity Information 

                    }
                    'Created' 
                    {
                        Write-FSLog -Message "'$SourceName' was $ChangeType in $Folder." -Severity Information 
                    }
                    'Deleted'
                    {
                        Write-FSLog -Message "'$SourceName' was $ChangeType from $Folder." -Severity Information 
                    }
                    'Renamed'
                    {
                        Write-FSLog -Message "'$SourceOldName' was $ChangeType to $SourceName." -Severity Information 
                    }
                }
            }
            catch
            {
                if($($_.Exception.Message) -match "E001")
                {
                    Write-FSLog -Message "Source is a perfect match with the last written file. No actions will be taken." -Severity Warning
                }
                else
                {
                    Write-FSLog -Message "$($_.Exception.Message)" -Severity Error
                }
            }
	    }
        Write-FSLog -Message "Terminated monitoring of folder '$Folder'" -Severity Information
    }
    End
    {
    $fsw.Dispose()
    }
}