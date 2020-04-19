# $PROFILE = "C:\Users\Daniel\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

Import-Module PSReadLine
Import-Module posh-git
Import-Module oh-my-posh
Set-Theme Robbyrussell

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Shows navigable menu of all options when hitting Tab
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

# Autocompletion for arrow keys
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

$DEV = "C:\dev"