<#
.Synopsis
    Continuously monitors a directory tree and write to the output the path of the file that has changed.
.Description 
    This powershell cmdlet continuously monitors a directory tree and write to the output the path of the file that has changed.
	This allows you to create an script that for instance, run a suite of unit tests when an specific file has changed using powershell pipelining.
	
.Parameter $location
    The directory to watch. Optional, default to current directory.
.Parameter $includeSubdirectories
.Parameter $includeChanged
.Parameter $includeRenamed
.Parameter $includeCreated
.Parameter $includeDeleted

.Link
    https://github.com/jfromaniello/pswatch/
.Example
    Import-Module pswatch

	watch "Myfolder\Other" | %{
		Write-Host "$_.Path has changed!"
		RunUnitTests.exe $_.Path
	}

    Description
    -----------
    A simple example.
	
.Example
	watch | Get-Item | Where-Object { $_.Extension -eq ".js" } | %{
		do the magic...
	}

	Description
	-----------
	You can filter by using powershell pipelining.
	
#>
function Watch-fsFolder
{
    [CmdletBinding()]
    [Alias("Monitor-fsFolder")]
    Param
    (
        [Parameter(Mandatory=$false,
                   Position=0)]
        [ValidateScript({  Test-Path -Path $_ -PathType Container  })]
        [string]$Folder = (Get-Location),

        [Parameter(Mandatory=$false,
                   Position=1)]
        [string]$Filter = '*.*',

        [Parameter(Mandatory=$false,
                   Position=2)]
        [ValidateScript({  Test-Path -Path $_ -PathType Container  })]
        [string]$Destination,

        [Parameter(Mandatory=$false,
                   Position=3)]
        [switch]$IncludeSubdirectories = $false,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [string]$LogFile = "Watch-Folder.csv",

        [Parameter(HelpMessage = 'Watch for changes')]
        [switch]$includeChanged = $true,

        [Parameter(HelpMessage = 'Watch for renames')]
        [switch]$includeRenamed = $true,

        [Parameter(HelpMessage = 'Watch for new files')]
        [switch]$includeCreated = $true,

        [Parameter(HelpMessage = 'Watch for delete events')]
        [switch]$includeDeleted = $false

    )
		   
    Begin
    {
        if(!$Destination)
        {
            $LogFile = Join-Path -Path (Get-Location) -ChildPath $LogFile
            Start-Log -Log $LogFile
        }
        else
        {
            Start-Log -Log (Join-Path -Path $Destination -ChildPath $LogFile)
        }
        #Write-Host "The log file was created at: [$ScriptLogFilePath]"
        #Write-Log -Message "The log file was created at: [$ScriptLogFilePath]" -LogLevel 1

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
            $SourceFullPath = [System.IO.Path]::Combine($Folder, $SourceName)

            switch ($Event.ChangeType)
            {
                'Changed'
                {

                    Try
                    {
                        if(!$Destination)
                        {
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
                            Throw "Source is a perfect match with the last written file. No actions will be taken."
                        }

                        Copy-Item -Path $SourceFullPath -Destination $DestinationFullPath
                        #Write-Log -Message "Successfully copied the file." -Severity Information

                    }
                    catch
                    {
                        #Write-Host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
                    }

                }
                'Created' { }
                'Deleted' { }
                'Renamed' { }
            }
            #Write-Log -Message Hej -Severity Information
		    New-Object Object |
                Add-Member -MemberType NoteProperty -Name Time (Get-Date -Format s) -passThru | 
                Add-Member -MemberType NoteProperty -Name Operation $Event.ChangeType.ToString() -passThru | 
                Add-Member -MemberType NoteProperty -Name Source $SourceFullPath -passThru |
              Write-Output
            
            #Write-Log -Message "The log file was created at: [$ScriptLogFilePath]" -LogLevel 1
	    }
    }
    End
    {
    }
}

Watch-fsFolder -Folder C:\watch -Destination "C:\dest"