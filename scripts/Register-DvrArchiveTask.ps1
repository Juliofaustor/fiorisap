[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [Parameter(Mandatory = $false)]
    [string]$TaskName = 'DVR-Video-Archive',

    [Parameter(Mandatory = $false)]
    [string]$LogPath = 'C:\DvrArchive\logs\dvr-archive.log',

    [Parameter(Mandatory = $false)]
    [string]$StatePath = 'C:\DvrArchive\state\archive-state.json',

    [Parameter(Mandatory = $false)]
    [int]$MinFileAgeMinutes = 120
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "No existe el script principal: $ScriptPath"
}

$escapedScript = '"' + $ScriptPath + '"'
$escapedSource = '"' + $SourcePath + '"'
$escapedDestination = '"' + $DestinationPath + '"'
$escapedLog = '"' + $LogPath + '"'
$escapedState = '"' + $StatePath + '"'

$arguments = @(
    '-NoProfile'
    '-ExecutionPolicy', 'Bypass'
    '-File', $escapedScript
    '-SourcePath', $escapedSource
    '-DestinationPath', $escapedDestination
    '-LogPath', $escapedLog
    '-StatePath', $escapedState
    '-MinFileAgeMinutes', $MinFileAgeMinutes
) -join ' '

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Daily -At 12:00AM
$settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest -LogonType ServiceAccount

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Write-Output "Tarea programada '$TaskName' creada/actualizada para ejecutarse todos los días a las 00:00."
