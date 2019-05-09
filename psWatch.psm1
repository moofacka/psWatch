#Dot source all functions in all ps1 files located in the module folder
Get-ChildItem -Path $PSScriptRoot\functions\*.ps1 |
ForEach-Object {
    . $_.FullName
}