[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\DvrArchive\logs\dvr-archive.log",

    [Parameter(Mandatory = $false)]
    [string]$StatePath = "C:\DvrArchive\state\archive-state.json",

    [Parameter(Mandatory = $false)]
    [int]$MinFileAgeMinutes = 120,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"
    Write-Output $line
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function Ensure-Path {
    param([string]$Path)

    $directory = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

function Get-State {
    if (-not (Test-Path -LiteralPath $StatePath)) {
        return [PSCustomObject]@{
            LastRunDate = $null
        }
    }

    try {
        $raw = Get-Content -Path $StatePath -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return [PSCustomObject]@{ LastRunDate = $null }
        }

        return ($raw | ConvertFrom-Json)
    }
    catch {
        Write-Log -Level 'WARN' -Message "No se pudo leer el estado. Se reinicia el estado. Error: $($_.Exception.Message)"
        return [PSCustomObject]@{ LastRunDate = $null }
    }
}

function Save-State {
    param([string]$DateString)

    Ensure-Path -Path $StatePath
    [PSCustomObject]@{
        LastRunDate = $DateString
    } | ConvertTo-Json | Set-Content -Path $StatePath -Encoding UTF8
}

Ensure-Path -Path $LogPath

try {
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $state = Get-State

    if ($state.LastRunDate -eq $today) {
        Write-Log -Message "Ejecución omitida: ya se ejecutó el archivado hoy ($today)."
        exit 0
    }

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-Log -Level 'ERROR' -Message "No existe la ruta de origen: $SourcePath"
        exit 2
    }

    if (-not (Test-Path -LiteralPath $DestinationPath)) {
        Write-Log -Message "La ruta destino no existe. Se crea: $DestinationPath"
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }

    $cutoff = (Get-Date).AddMinutes(-1 * [Math]::Abs($MinFileAgeMinutes))

    $files = Get-ChildItem -LiteralPath $SourcePath -Recurse -File |
        Where-Object { $_.LastWriteTime -lt $cutoff }

    if (-not $files -or $files.Count -eq 0) {
        Write-Log -Message "No hay archivos elegibles para mover (edad mínima: $MinFileAgeMinutes minutos)."
        Save-State -DateString $today
        exit 0
    }

    $success = 0
    $failed = 0

    foreach ($file in $files) {
        try {
            $relativePath = $file.FullName.Substring($SourcePath.TrimEnd('\\').Length).TrimStart('\\')
            $targetFile = Join-Path $DestinationPath $relativePath
            $targetDir = Split-Path -Path $targetFile -Parent

            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            if ($WhatIf.IsPresent) {
                Write-Log -Message "[SIMULACIÓN] Movería: '$($file.FullName)' -> '$targetFile'"
                $success++
                continue
            }

            Move-Item -LiteralPath $file.FullName -Destination $targetFile -Force
            Write-Log -Message "Movido: '$($file.FullName)' -> '$targetFile'"
            $success++
        }
        catch {
            $failed++
            Write-Log -Level 'ERROR' -Message "Falló copia/movimiento para '$($file.FullName)': $($_.Exception.Message)"
        }
    }

    Write-Log -Message "Resultado del archivado: OK=$success, FALLIDOS=$failed"

    Save-State -DateString $today

    if ($failed -gt 0) {
        exit 3
    }

    exit 0
}
catch {
    Write-Log -Level 'ERROR' -Message "Error general: $($_.Exception.Message)"
    exit 1
}
