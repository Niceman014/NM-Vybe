param(
    [string]$BackendUrl = ''
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$tempDirectory = Join-Path $workspaceRoot '.tmp'
$dataDirectory = Join-Path $workspaceRoot '.nm_vybe_data'
$debugExecutable = Join-Path $workspaceRoot 'build\windows\x64\runner\Debug\nm_vybe.exe'

$runningInstances = @(
    Get-Process -Name 'nm_vybe' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path -ieq $debugExecutable }
)
if ($runningInstances.Count -gt 0) {
    $processDetails = $runningInstances | ForEach-Object {
        "PID $($_.Id) (window: $($_.MainWindowTitle))"
    }
    throw "NM VYBE Debug is already running: $($processDetails -join ', '). `
Close that app window or press q in its flutter run terminal before rebuilding."
}

New-Item -ItemType Directory -Force -Path $tempDirectory, $dataDirectory | Out-Null
$env:TEMP = $tempDirectory
$env:TMP = $tempDirectory
$env:NM_VYBE_DATA_DIR = $dataDirectory

Push-Location $workspaceRoot
try {
    $flutterArguments = @('run', '-d', 'windows')
    if ($BackendUrl -and -not [string]::IsNullOrWhiteSpace($BackendUrl)) {
        $flutterArguments += "--dart-define=BACKEND_URL=$BackendUrl"
    }
    flutter @flutterArguments
    # flutter run stays attached while the app is open. Press q in this
    # terminal to stop it before running flutter clean or rebuilding.
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
