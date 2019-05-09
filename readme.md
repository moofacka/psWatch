This powershell cmdlet continuously monitors a directory tree and write to the output the path of the file that has changed.

Can run to copy changes to a new location. All events will also be logged.

Installation
============

Clone repository to module folder. 


Usage
=====

Import module

    Import-Module psWatch

	
Monitors C:\Watch and all it's subfolders for events to

    Watch-FSFolder -Folder C:\Watch -Filter "*.txt" -includeSubdirectories


Monitors all events in the current directory and logs to the same directory.
	
    Watch-FSFolder -includeDeleted


Monitors C:\Watch for events to *.txt files and copies changed files to C:\Destination and logs all to psWatch.log in C:\Destination.
    Watch-FSFolder -Folder C:\Watch -Filter "*.txt" -Destination C:\Destination -LogFile psWatch.log


Options
=======

The wacth cmdlet has the following parameters:

  * Folder: The Folder that you want to monitor. Default is the current working directory.
  * Filter: What filter to be used for the monitoring. Default is wildcard for everything. Could be specified in string like "important.txt".
  * Destination: Destination folder for the captured changes. Default is not configured.
  * LogFile: Log file name for all the output.
  * includeSubdirectories: Recursively searches subfolders as well. Turned off by default.
  * includeChanged: Includes change events. Default setting.
  * includeRenamed: Includes rename events. Default setting.
  * includeCreated: Includes create events. Default setting.
  * includeDeleted: Includes delete events. Turned off by default.